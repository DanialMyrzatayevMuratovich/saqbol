"use client";

import Link from "next/link";
import { useRouter } from "next/navigation";

import { clearTokens } from "@/lib/auth";

const links = [
  { href: "/", label: "Метрики" },
  { href: "/messages", label: "Сообщения" },
  { href: "/models", label: "Модель" },
];

export function NavBar({ active }: { active: string }) {
  const router = useRouter();

  function logout() {
    clearTokens();
    router.replace("/login");
  }

  return (
    <header className="sticky top-0 z-10 border-b border-border bg-background/80 backdrop-blur">
      <div className="mx-auto flex max-w-6xl items-center justify-between px-6 py-4">
        <div className="flex items-center gap-8">
          <span className="flex items-center gap-2 text-lg font-bold tracking-tight">
            <span
              aria-hidden
              className="inline-block h-2 w-2 rounded-full bg-accent shadow-[0_0_12px_var(--accent)]"
            />
            SaqBol
          </span>
          <nav className="flex gap-1">
            {links.map((link) => (
              <Link
                key={link.href}
                href={link.href}
                aria-current={active === link.href ? "page" : undefined}
                className={
                  active === link.href
                    ? "rounded-lg bg-surface px-3 py-1.5 text-sm font-semibold text-accent"
                    : "rounded-lg px-3 py-1.5 text-sm text-muted transition-colors hover:bg-surface hover:text-foreground"
                }
              >
                {link.label}
              </Link>
            ))}
          </nav>
        </div>
        <button
          onClick={logout}
          className="rounded-lg border border-border px-4 py-2 text-sm font-medium text-muted transition-colors hover:border-scam/50 hover:text-foreground"
        >
          Выйти
        </button>
      </div>
    </header>
  );
}
