"use client";

import * as Sentry from "@sentry/nextjs";
import { useEffect } from "react";
import "./globals.css";

export default function GlobalError({
  error,
  reset,
}: {
  error: Error & { digest?: string };
  reset: () => void;
}) {
  useEffect(() => {
    Sentry.captureException(error);
  }, [error]);

  return (
    <html lang="vi">
      <body>
        <main className="mx-auto flex min-h-full max-w-lg flex-col justify-center gap-4 p-6">
          <h1 className="text-xl font-semibold">Đã xảy ra lỗi</h1>
          <p>Không thể hiển thị trang này. Thử lại sau.</p>
          <button
            className="w-fit rounded-lg px-4 py-2 text-sm font-semibold text-white"
            style={{ background: "var(--color-brand-primary)" }}
            type="button"
            onClick={() => reset()}
          >
            Thử lại
          </button>
        </main>
      </body>
    </html>
  );
}
