"use client";

import { useState, useTransition, type CSSProperties, type ReactNode } from "react";
import {
  loadAppConfig,
  resetConfigValue,
  saveConfigValue,
  saveFlag,
  type AdminAppConfig,
  type AdminConfigEntry,
  type AdminFlag,
  type AdminResult,
  type LastChange,
} from "./app_config_actions";
import {
  configGroup,
  describeLimits,
  describeValue,
  parseConfigInput,
  parseFlagInput,
  sameValue,
  toInputText,
} from "./app_config_format";

const GROUP_LABELS: Record<string, string> = {
  budget: "Ngân sách",
  forecast: "Dự báo số dư",
  installment: "Trả góp thẻ",
  recurring: "Định kỳ",
  creditCard: "Thẻ tín dụng",
  debt: "Cho mượn / đi mượn",
  onboarding: "Onboarding",
  notification: "Thông báo",
  netWorth: "Tài sản ròng",
  investment: "Đầu tư",
  report: "Báo cáo",
  home: "Tổng quan",
  goal: "Mục tiêu",
  security: "Bảo mật",
  password: "Mật khẩu",
  profile: "Hồ sơ",
  import: "Nhập CSV",
  export: "Xuất CSV",
  transaction: "Giao dịch",
};

const card: CSSProperties = { background: "var(--color-neutral-surface)", borderColor: "var(--color-brand-muted)" };
const muted: CSSProperties = { color: "var(--color-neutral-text-muted)" };
const danger: CSSProperties = { color: "var(--color-semantic-danger)" };
const inputStyle: CSSProperties = { borderColor: "var(--color-brand-muted)", background: "var(--color-neutral-surface)" };
const primaryButton: CSSProperties = { background: "var(--color-brand-primary)", color: "var(--color-neutral-on-primary)" };
const ghostButton: CSSProperties = { borderColor: "var(--color-brand-muted)" };

type Apply = (run: () => Promise<AdminResult>) => Promise<AdminResult>;

export function AppConfigPanel() {
  const [token, setToken] = useState("");
  const [data, setData] = useState<AdminAppConfig | null>(null);
  const [loadError, setLoadError] = useState<string | null>(null);
  const [pending, startTransition] = useTransition();

  const load = () =>
    startTransition(async () => {
      const result = await loadAppConfig(token);
      if (result.status === "ok") {
        setData(result.data);
        setLoadError(null);
      } else {
        setLoadError(result.message);
      }
    });

  // Every save answers with the full list, so a success replaces the page data.
  const apply: Apply = async (run) => {
    const result = await run();
    if (result.status === "ok") setData(result.data);
    return result;
  };

  const groups = new Map<string, AdminConfigEntry[]>();
  for (const entry of data?.config ?? []) {
    const group = configGroup(entry.key);
    groups.set(group, [...(groups.get(group) ?? []), entry]);
  }

  return (
    <div className="space-y-8">
      <section className="rounded-2xl border p-6 shadow-sm" style={card}>
        <form
          className="flex flex-wrap items-end gap-3"
          onSubmit={(event) => {
            event.preventDefault();
            load();
          }}
        >
          <label className="flex min-w-64 flex-1 flex-col gap-1 text-sm font-medium" htmlFor="staffToken">
            Credential staff
            <input
              className="rounded-lg border px-3 py-2 text-sm font-normal"
              style={inputStyle}
              id="staffToken"
              type="password"
              autoComplete="current-password"
              value={token}
              onChange={(event) => setToken(event.target.value)}
              required
            />
          </label>
          <button className="rounded-lg px-4 py-2 text-sm font-semibold disabled:opacity-60" style={primaryButton} type="submit" disabled={pending}>
            {pending ? "Đang tải…" : data ? "Tải lại" : "Tải cấu hình"}
          </button>
        </form>
        <p className="mt-3 text-sm" style={muted}>
          Credential chỉ giữ trong trang này, tải lại trang phải nhập lại. Mọi thay đổi được ghi audit kèm giá trị trước và sau. App nhận giá trị mới ở lần tải cấu hình kế tiếp.
        </p>
        {loadError ? (
          <p className="mt-3 text-sm" style={danger} role="alert">
            {loadError}
          </p>
        ) : null}
        {data ? (
          <p className="mt-3 text-sm" style={muted}>
            Phiên bản cấu hình: <span className="font-medium">{data.version}</span>
          </p>
        ) : null}
      </section>

      {data ? (
        <>
          <section className="space-y-3">
            <h2 className="text-lg font-semibold">Cờ tính năng</h2>
            {data.flags.map((flag) => (
              <FlagRow key={`${flag.key}:${flag.version}`} flag={flag} token={token} apply={apply} />
            ))}
          </section>
          {[...groups.entries()].map(([group, entries]) => (
            <section key={group} className="space-y-3">
              <h2 className="text-lg font-semibold">{GROUP_LABELS[group] ?? group}</h2>
              {entries.map((entry) => (
                <ConfigRow key={`${entry.key}:${entry.version}`} entry={entry} token={token} apply={apply} />
              ))}
            </section>
          ))}
        </>
      ) : null}
    </div>
  );
}

function FlagRow({ flag, token, apply }: { flag: AdminFlag; token: string; apply: Apply }) {
  const [enabled, setEnabled] = useState(flag.enabled);
  const [percentage, setPercentage] = useState(String(flag.percentage));
  const [userIds, setUserIds] = useState(flag.userIds.join("\n"));
  const [error, setError] = useState<{ field?: string; message: string } | null>(null);
  const [confirming, setConfirming] = useState<{ enabled: boolean; percentage: number; userIds: string[] } | null>(null);
  const [pending, startTransition] = useTransition();

  const current = { enabled: flag.enabled, percentage: flag.percentage, userIds: flag.userIds };
  const review = () => {
    const parsed = parseFlagInput(enabled, percentage, userIds);
    if (!parsed.ok) return setError({ field: parsed.field, message: parsed.message });
    setError(null);
    if (sameValue({ ...parsed.value, userIds: [...parsed.value.userIds].sort() }, { ...current, userIds: [...current.userIds].sort() })) {
      return setError({ message: "Chưa có gì thay đổi." });
    }
    setConfirming(parsed.value);
  };
  const save = () =>
    startTransition(async () => {
      if (!confirming) return;
      const result = await apply(() => saveFlag(token, flag.key, confirming, flag.version));
      if (result.status === "error") {
        setConfirming(null);
        setError({ message: result.reason ? `${result.message} (${result.reason})` : result.message });
      }
    });
  const describe = (state: typeof current) =>
    `${state.enabled ? "Bật" : "Tắt"} · ${state.percentage}% user · ${state.userIds.length} user trong danh sách`;

  return (
    <article className="rounded-2xl border p-5 shadow-sm" style={card}>
      <RowHeader title={flag.key} description={flag.description} lastChange={flag.lastChange} badge={flag.enabled ? "Đang bật" : "Đang tắt"} />
      <div className="mt-4 grid gap-4 md:grid-cols-[auto_10rem_1fr]">
        <label className="flex items-center gap-2 text-sm font-medium">
          <input type="checkbox" checked={enabled} onChange={(event) => setEnabled(event.target.checked)} />
          Bật
        </label>
        <Field label="Phần trăm user" error={error?.field === "percentage" ? error.message : undefined}>
          <input
            className="w-full rounded-lg border px-3 py-2 text-sm"
            style={inputStyle}
            inputMode="numeric"
            value={percentage}
            onChange={(event) => setPercentage(event.target.value)}
            aria-invalid={error?.field === "percentage"}
          />
        </Field>
        <Field label="User luôn bật (UUID, mỗi dòng một)" error={error?.field === "userIds" ? error.message : undefined}>
          <textarea
            className="w-full rounded-lg border px-3 py-2 font-mono text-xs"
            style={inputStyle}
            rows={2}
            value={userIds}
            onChange={(event) => setUserIds(event.target.value)}
            aria-invalid={error?.field === "userIds"}
          />
        </Field>
      </div>
      <p className="mt-2 text-xs" style={muted}>
        Tắt thì tắt với mọi user. Bật thì user trong danh sách luôn có, những user khác theo phần trăm (cố định theo từng user).
      </p>
      {error && !error.field ? <ErrorLine message={error.message} /> : null}
      {confirming ? (
        <Confirm
          before={describe(current)}
          after={describe(confirming)}
          pending={pending}
          onConfirm={save}
          onCancel={() => setConfirming(null)}
        />
      ) : (
        <div className="mt-4">
          <button className="rounded-lg px-4 py-2 text-sm font-semibold" style={primaryButton} type="button" onClick={review}>
            Lưu
          </button>
        </div>
      )}
    </article>
  );
}

function ConfigRow({ entry, token, apply }: { entry: AdminConfigEntry; token: string; apply: Apply }) {
  const { definition } = entry;
  const [text, setText] = useState(toInputText(definition, entry.value));
  const [error, setError] = useState<string | null>(null);
  const [confirming, setConfirming] = useState<{ kind: "save"; value: AdminConfigEntry["value"] } | { kind: "reset" } | null>(null);
  const [pending, startTransition] = useTransition();
  const inputId = `config-${entry.key}`;

  const review = () => {
    const parsed = parseConfigInput(definition, text);
    if (!parsed.ok) return setError(parsed.message);
    if (sameValue(parsed.value, entry.value)) return setError("Chưa có gì thay đổi.");
    setError(null);
    setConfirming({ kind: "save", value: parsed.value });
  };
  const run = () =>
    startTransition(async () => {
      if (!confirming) return;
      const result = await apply(() =>
        confirming.kind === "save"
          ? saveConfigValue(token, entry.key, confirming.value, entry.version)
          : resetConfigValue(token, entry.key, entry.version),
      );
      if (result.status === "error") {
        setConfirming(null);
        setError(result.reason ? `${result.message} (${result.reason})` : result.message);
      }
    });

  return (
    <article className="rounded-2xl border p-5 shadow-sm" style={card}>
      <RowHeader
        title={entry.key}
        description={definition.description}
        lastChange={entry.lastChange}
        badge={entry.isDefault ? "Mặc định" : "Đã sửa"}
      />
      <div className="mt-4">
        <Field label="Giá trị" htmlFor={inputId} error={error ?? undefined} hint={describeLimits(definition)}>
          {definition.type === "enum" ? (
            <select
              className="w-full rounded-lg border px-3 py-2 text-sm"
              style={inputStyle}
              id={inputId}
              value={text}
              onChange={(event) => setText(event.target.value)}
            >
              {definition.values?.map((value) => (
                <option key={value} value={value}>
                  {value}
                </option>
              ))}
            </select>
          ) : (
            <input
              className="w-full rounded-lg border px-3 py-2 text-sm"
              style={inputStyle}
              id={inputId}
              type={definition.type === "time" ? "time" : "text"}
              inputMode={definition.type === "integer" ? "numeric" : undefined}
              value={text}
              onChange={(event) => setText(event.target.value)}
              aria-invalid={error !== null}
            />
          )}
        </Field>
        <p className="mt-2 text-xs" style={muted}>
          Mặc định: {describeValue(definition, definition.default)}
        </p>
      </div>
      {confirming ? (
        <Confirm
          before={describeValue(definition, entry.value)}
          after={describeValue(definition, confirming.kind === "save" ? confirming.value : definition.default)}
          pending={pending}
          onConfirm={run}
          onCancel={() => setConfirming(null)}
        />
      ) : (
        <div className="mt-4 flex flex-wrap gap-2">
          <button className="rounded-lg px-4 py-2 text-sm font-semibold" style={primaryButton} type="button" onClick={review}>
            Lưu
          </button>
          {!entry.isDefault ? (
            <button
              className="rounded-lg border px-4 py-2 text-sm font-semibold"
              style={ghostButton}
              type="button"
              onClick={() => {
                setError(null);
                setConfirming({ kind: "reset" });
              }}
            >
              Về mặc định
            </button>
          ) : null}
        </div>
      )}
    </article>
  );
}

function RowHeader({ title, description, lastChange, badge }: { title: string; description: string; lastChange: LastChange; badge: string }) {
  return (
    <header>
      <div className="flex flex-wrap items-center gap-2">
        <h3 className="font-mono text-sm font-semibold">{title}</h3>
        <span className="rounded-full border px-2 py-0.5 text-xs" style={ghostButton}>
          {badge}
        </span>
      </div>
      <p className="mt-1 text-sm">{description}</p>
      <p className="mt-1 text-xs" style={muted}>
        {lastChange
          ? `Sửa lần cuối ${new Date(lastChange.updatedAt).toLocaleString("vi-VN")} · staff ${lastChange.updatedBy}`
          : "Chưa sửa lần nào"}
      </p>
    </header>
  );
}

function Field({ label, htmlFor, error, hint, children }: { label: string; htmlFor?: string; error?: string; hint?: string; children: ReactNode }) {
  return (
    <div className="flex flex-col gap-1">
      <label className="text-sm font-medium" htmlFor={htmlFor}>
        {label}
      </label>
      {children}
      {hint ? (
        <span className="text-xs" style={muted}>
          {hint}
        </span>
      ) : null}
      {error ? <ErrorLine message={error} /> : null}
    </div>
  );
}

function ErrorLine({ message }: { message: string }) {
  return (
    <p className="mt-1 text-sm" style={danger} role="alert">
      {message}
    </p>
  );
}

function Confirm({ before, after, pending, onConfirm, onCancel }: { before: string; after: string; pending: boolean; onConfirm: () => void; onCancel: () => void }) {
  return (
    <div className="mt-4 rounded-xl border p-4" style={ghostButton} role="group" aria-label="Xác nhận thay đổi">
      <dl className="grid gap-2 text-sm sm:grid-cols-[6rem_1fr]">
        <dt style={muted}>Hiện tại</dt>
        <dd className="break-all">{before}</dd>
        <dt style={muted}>Sau khi lưu</dt>
        <dd className="break-all font-semibold">{after}</dd>
      </dl>
      <div className="mt-3 flex flex-wrap gap-2">
        <button className="rounded-lg px-4 py-2 text-sm font-semibold disabled:opacity-60" style={primaryButton} type="button" onClick={onConfirm} disabled={pending}>
          {pending ? "Đang lưu…" : "Xác nhận lưu"}
        </button>
        <button className="rounded-lg border px-4 py-2 text-sm font-semibold" style={ghostButton} type="button" onClick={onCancel} disabled={pending}>
          Hủy
        </button>
      </div>
    </div>
  );
}
