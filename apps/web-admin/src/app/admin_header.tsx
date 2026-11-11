import Image from "next/image";
import Link from "next/link";

const links = [
  { href: "/", label: "Tổng quan" },
  { href: "/config", label: "Cờ và cấu hình" },
] as const;

export function AdminHeader({ current }: { current: (typeof links)[number]["href"] }) {
  return (
    <header
      className="border-b px-8 py-4"
      style={{
        background: "var(--color-neutral-surface)",
        borderColor: "var(--color-brand-muted)",
      }}
    >
      <div className="mx-auto flex w-full max-w-5xl flex-wrap items-center gap-x-6 gap-y-2">
        <Image
          src="/brand/freeva-logo-lockup.png"
          alt="Freeva"
          width={2172}
          height={724}
          className="h-12 w-auto"
          priority
        />
        <h1
          className="text-xl font-semibold sm:border-l sm:pl-6"
          style={{ borderColor: "var(--color-brand-muted)" }}
        >
          Web Admin
        </h1>
        <nav className="flex gap-4 text-sm sm:ml-auto" aria-label="Điều hướng">
          {links.map((link) => (
            <Link
              key={link.href}
              href={link.href}
              aria-current={link.href === current ? "page" : undefined}
              className={link.href === current ? "font-semibold underline underline-offset-4" : ""}
            >
              {link.label}
            </Link>
          ))}
        </nav>
      </div>
    </header>
  );
}
