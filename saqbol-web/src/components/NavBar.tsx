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
    <header className="border-b border-slate-200 bg-white">
      <div className="mx-auto flex max-w-6xl items-center justify-between px-6 py-4">
        <div className="flex items-center gap-6">
          <span className="text-lg font-bold text-slate-900">SaqBol</span>
          <nav className="flex gap-4">
            {links.map((link) => (
              <Link
                key={link.href}
                href={link.href}
                className={
                  active === link.href
                    ? "text-sm font-semibold text-blue-700"
                    : "text-sm text-slate-500 hover:text-slate-800"
                }
              >
                {link.label}
              </Link>
            ))}
          </nav>
        </div>
        <button
          onClick={logout}
          className="rounded-lg border border-slate-300 px-4 py-2 text-sm font-medium text-slate-700 hover:bg-slate-50"
        >
          Выйти
        </button>
      </div>
    </header>
  );
}
