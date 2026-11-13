import { apiBase } from "../lib/api_base";
import { AdminHeader } from "./admin_header";
import { UserLookupForm } from "./user_lookup_form";

export const dynamic = "force-dynamic";

type HealthResponse = {
  status: string;
  service: string;
  timestamp: string;
  database: string;
};

async function fetchHealth(): Promise<HealthResponse | null> {
  try {
    const response = await fetch(`${apiBase()}/api/health`, { cache: "no-store" });
    if (!response.ok) {
      return null;
    }
    return (await response.json()) as HealthResponse;
  } catch {
    return null;
  }
}

export default async function Home() {
  const health = await fetchHealth();

  return (
    <div className="flex min-h-full flex-1 flex-col">
      <AdminHeader current="/" />
      <main className="mx-auto grid w-full max-w-5xl flex-1 gap-6 px-8 py-12 lg:grid-cols-2">
        <section
          className="rounded-2xl border p-6 shadow-sm"
          style={{
            background: "var(--color-neutral-surface)",
            borderColor: "var(--color-brand-muted)",
          }}
        >
          <h2 className="text-lg font-semibold">API health</h2>
          <p className="mt-1 text-sm" style={{ color: "var(--color-neutral-text-muted)" }}>
            Trạng thái dịch vụ nội bộ. Chạy <code>make up</code> và{" "}
            <code>make api</code>.
          </p>
          {health ? (
            <dl className="mt-6 grid grid-cols-2 gap-3 text-sm">
              <dt>status</dt>
              <dd className="font-medium">{health.status}</dd>
              <dt>service</dt>
              <dd>{health.service}</dd>
              <dt>database</dt>
              <dd>{health.database}</dd>
              <dt>timestamp</dt>
              <dd className="break-all">{health.timestamp}</dd>
            </dl>
          ) : (
            <p className="mt-6 text-sm" style={{ color: "var(--color-semantic-danger)" }}>
              Không kết nối được API. Endpoint: /api/health
            </p>
          )}
          <div
            className="mt-8 h-1.5 w-16 rounded-full"
            style={{ background: "var(--color-brand-accent)" }}
            aria-hidden
          />
        </section>
        <UserLookupForm />
      </main>
    </div>
  );
}
