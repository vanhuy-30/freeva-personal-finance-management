import { AdminHeader } from "../admin_header";
import { AppConfigPanel } from "./app_config_panel";

export const dynamic = "force-dynamic";

export const metadata = { title: "Cờ và cấu hình · Freeva Admin" };

export default function AppConfigPage() {
  return (
    <div className="flex min-h-full flex-1 flex-col">
      <AdminHeader current="/config" />
      <main className="mx-auto w-full max-w-5xl flex-1 px-8 py-12">
        <h2 className="text-2xl font-semibold">Cờ và cấu hình</h2>
        <p className="mt-1 text-sm" style={{ color: "var(--color-neutral-text-muted)" }}>
          Bật/tắt tính năng và các số app dùng (ngưỡng, giới hạn, lựa chọn). Mỗi môi trường có cấu hình riêng.
        </p>
        <div className="mt-8">
          <AppConfigPanel />
        </div>
      </main>
    </div>
  );
}
