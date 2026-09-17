"use client";

import { useActionState } from "react";
import {
  lookupUserAccount,
  type UserLookupState,
} from "./user_lookup_actions";

const initialState: UserLookupState = { status: "idle" };

export function UserLookupForm() {
  const [state, formAction, pending] = useActionState(
    lookupUserAccount,
    initialState,
  );

  return (
    <section
      className="rounded-2xl border p-6 shadow-sm"
      style={{
        background: "var(--color-neutral-surface)",
        borderColor: "var(--color-brand-muted)",
      }}
    >
      <h2 className="text-lg font-semibold">Tra cứu tài khoản</h2>
      <p
        className="mt-1 text-sm"
        style={{ color: "var(--color-neutral-text-muted)" }}
      >
        Chỉ tra cứu chính xác theo email hoặc UUID. Mỗi lần tra cứu đều được
        ghi audit; không hiển thị dữ liệu tài chính.
      </p>

      <form action={formAction} className="mt-6 space-y-4">
        <label className="block text-sm font-medium" htmlFor="staffToken">
          Credential staff
        </label>
        <input
          className="w-full rounded-lg border px-3 py-2 text-sm"
          style={{ borderColor: "var(--color-brand-muted)" }}
          id="staffToken"
          name="staffToken"
          type="password"
          autoComplete="current-password"
          required
        />

        <label className="block text-sm font-medium" htmlFor="lookupType">
          Tiêu chí
        </label>
        <select
          className="w-full rounded-lg border px-3 py-2 text-sm"
          style={{ borderColor: "var(--color-brand-muted)" }}
          id="lookupType"
          name="lookupType"
          defaultValue="email"
        >
          <option value="email">Email chính xác</option>
          <option value="userId">User UUID</option>
        </select>

        <label className="block text-sm font-medium" htmlFor="lookupValue">
          Giá trị tra cứu
        </label>
        <input
          className="w-full rounded-lg border px-3 py-2 text-sm"
          style={{ borderColor: "var(--color-brand-muted)" }}
          id="lookupValue"
          name="lookupValue"
          type="text"
          autoComplete="off"
          required
        />

        <button
          className="rounded-lg px-4 py-2 text-sm font-semibold text-white disabled:cursor-not-allowed disabled:opacity-60"
          style={{ background: "var(--color-brand-primary)" }}
          type="submit"
          disabled={pending}
        >
          {pending ? "Đang tra cứu…" : "Tra cứu"}
        </button>
      </form>

      {state.status === "error" ? (
        <p
          className="mt-5 text-sm"
          style={{ color: "var(--color-semantic-danger)" }}
          role="alert"
        >
          {state.message}
        </p>
      ) : null}

      {state.status === "success" ? (
        <dl className="mt-6 grid gap-3 text-sm sm:grid-cols-[12rem_1fr]">
          <dt className="font-medium">User ID</dt>
          <dd className="break-all">{state.user.id}</dd>
          <dt className="font-medium">Email</dt>
          <dd className="break-all">{state.user.email}</dd>
          <dt className="font-medium">Locale</dt>
          <dd>{state.user.locale}</dd>
          <dt className="font-medium">Múi giờ</dt>
          <dd>{state.user.timezone}</dd>
          <dt className="font-medium">Tiền tệ mặc định</dt>
          <dd>{state.user.defaultCurrencyCode}</dd>
          <dt className="font-medium">Ngày bắt đầu kỳ</dt>
          <dd>{state.user.fiscalMonthStartDay}</dd>
          <dt className="font-medium">Ngày tạo</dt>
          <dd>{new Date(state.user.createdAt).toLocaleString("vi-VN")}</dd>
        </dl>
      ) : null}
    </section>
  );
}
