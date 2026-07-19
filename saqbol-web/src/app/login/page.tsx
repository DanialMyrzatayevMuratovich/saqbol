"use client";

import { useRouter } from "next/navigation";
import { useState } from "react";

import { login } from "@/lib/api";

export default function LoginPage() {
  const router = useRouter();
  const [phone, setPhone] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [submitting, setSubmitting] = useState(false);

  async function onSubmit(event: React.FormEvent) {
    event.preventDefault();
    setError(null);
    setSubmitting(true);
    try {
      await login(phone.trim(), password);
      router.push("/");
    } catch (err) {
      setError(err instanceof Error ? err.message : "Ошибка входа");
    } finally {
      setSubmitting(false);
    }
  }

  return (
    <main className="flex min-h-screen items-center justify-center bg-background p-4">
      <form
        onSubmit={onSubmit}
        className="w-full max-w-sm rounded-2xl border border-border bg-surface p-8 "
      >
        <h1 className="text-center text-2xl font-bold text-foreground">SaqBol</h1>
        <p className="mt-1 text-center text-sm text-muted">Панель аналитики</p>

        <label className="mt-6 block text-sm font-medium text-muted">Телефон</label>
        <input
          value={phone}
          onChange={(event) => setPhone(event.target.value)}
          placeholder="+7..."
          className="mt-1 w-full rounded-lg border border-border px-3 py-2 outline-none focus:border-accent"
        />

        <label className="mt-4 block text-sm font-medium text-muted">Пароль</label>
        <input
          type="password"
          value={password}
          onChange={(event) => setPassword(event.target.value)}
          className="mt-1 w-full rounded-lg border border-border px-3 py-2 outline-none focus:border-accent"
        />

        {error && <p className="mt-3 text-sm text-scam">{error}</p>}

        <button
          type="submit"
          disabled={submitting}
          className="mt-6 w-full rounded-lg bg-accent py-2.5 font-semibold text-background transition hover:bg-accent-strong disabled:opacity-60"
        >
          {submitting ? "Вход..." : "Войти"}
        </button>
      </form>
    </main>
  );
}
