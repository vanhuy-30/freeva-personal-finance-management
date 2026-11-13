/**
 * Base URL of the Freeva API for server-side calls (SEC-P6-002).
 *
 * Staff calls carry the staff bearer token, so production never falls back to
 * a default and never sends it over plain HTTP to a non-local host. Outside
 * production an unset value keeps the local default.
 */
export function apiBase(
  env: Record<string, string | undefined> = process.env,
): string {
  const raw = env.NEXT_PUBLIC_API_BASE_URL?.trim();
  if (!raw) {
    if (env.NODE_ENV === "production") {
      throw new Error("NEXT_PUBLIC_API_BASE_URL is not set");
    }
    return "http://localhost:4000";
  }
  const url = new URL(raw);
  const local = url.hostname === "localhost" || url.hostname === "127.0.0.1";
  if (env.NODE_ENV === "production" && url.protocol !== "https:" && !local) {
    throw new Error("NEXT_PUBLIC_API_BASE_URL must use https");
  }
  return raw.replace(/\/+$/, "");
}
