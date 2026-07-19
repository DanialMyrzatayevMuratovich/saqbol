"use client";

import { useRouter } from "next/navigation";
import { useCallback, useEffect, useState } from "react";

import { NavBar } from "@/components/NavBar";
import { UnauthorizedError, fetchFlaggedMessages } from "@/lib/api";
import { getAccessToken } from "@/lib/auth";
import { categoryLabel } from "@/lib/labels";
import type { AdminMessage } from "@/lib/types";

const filters = [
  { value: "", label: "Все" },
  { value: "scam", label: "Мошенничество" },
  { value: "suspicious", label: "Подозрительно" },
  { value: "safe", label: "Безопасно" },
];

const verdictColor: Record<string, string> = {
  scam: "text-scam",
  suspicious: "text-suspicious",
  safe: "text-safe",
};

export default function MessagesPage() {
  const router = useRouter();
  const [items, setItems] = useState<AdminMessage[]>([]);
  const [verdict, setVerdict] = useState("");
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const load = useCallback(
    async (selected: string) => {
      setLoading(true);
      setError(null);
      try {
        setItems(await fetchFlaggedMessages(selected));
      } catch (err) {
        if (err instanceof UnauthorizedError) {
          router.replace("/login");
          return;
        }
        setError(err instanceof Error ? err.message : "Ошибка загрузки");
      } finally {
        setLoading(false);
      }
    },
    [router],
  );

  useEffect(() => {
    if (!getAccessToken()) {
      router.replace("/login");
      return;
    }
    queueMicrotask(() => {
      void load(verdict);
    });
  }, [load, verdict, router]);

  return (
    <main className="min-h-screen bg-background">
      <NavBar active="/messages" />

      <div className="mx-auto max-w-6xl px-6 py-8">
        <div className="mb-4 flex items-center justify-between">
          <h1 className="text-xl font-bold text-foreground">Помеченные сообщения</h1>
          <div className="flex gap-2">
            {filters.map((filter) => (
              <button
                key={filter.value}
                onClick={() => setVerdict(filter.value)}
                className={
                  verdict === filter.value
                    ? "rounded-lg bg-accent px-3 py-1.5 text-sm font-semibold text-background"
                    : "rounded-lg border border-border px-3 py-1.5 text-sm text-muted hover:bg-surface-raised"
                }
              >
                {filter.label}
              </button>
            ))}
          </div>
        </div>

        {loading && <p className="text-muted">Загрузка…</p>}
        {error && <p className="text-scam">{error}</p>}

        {!loading && !error && (
          <div className="overflow-x-auto rounded-2xl border border-border bg-surface">
            <table className="w-full text-left text-sm">
              <thead className="border-b border-border text-muted">
                <tr>
                  <th className="px-4 py-3">Вердикт</th>
                  <th className="px-4 py-3">Категория</th>
                  <th className="px-4 py-3">Текст</th>
                  <th className="px-4 py-3">Отправитель</th>
                  <th className="px-4 py-3">Пользователь</th>
                  <th className="px-4 py-3 text-right">Вероятность</th>
                </tr>
              </thead>
              <tbody>
                {items.length === 0 ? (
                  <tr>
                    <td colSpan={6} className="px-4 py-8 text-center text-muted">
                      Нет сообщений
                    </td>
                  </tr>
                ) : (
                  items.map((item) => (
                    <tr key={item.id} className="border-b border-border">
                      <td className={`px-4 py-3 font-medium ${verdictColor[item.verdict] ?? ""}`}>
                        {item.verdict}
                      </td>
                      <td className="px-4 py-3">{item.category ? categoryLabel(item.category) : "—"}</td>
                      <td className="max-w-sm truncate px-4 py-3" title={item.text}>
                        {item.text}
                      </td>
                      <td className="px-4 py-3">{item.source_number || "—"}</td>
                      <td className="px-4 py-3">{item.phone}</td>
                      <td className="px-4 py-3 text-right">{Math.round(item.probability * 100)}%</td>
                    </tr>
                  ))
                )}
              </tbody>
            </table>
          </div>
        )}
      </div>
    </main>
  );
}
