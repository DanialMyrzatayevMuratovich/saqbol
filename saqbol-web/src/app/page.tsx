"use client";

import { useRouter } from "next/navigation";
import { useCallback, useEffect, useState } from "react";

import { CategoryChart } from "@/components/CategoryChart";
import { NavBar } from "@/components/NavBar";
import { StatCard } from "@/components/StatCard";
import { VerdictSplit } from "@/components/VerdictSplit";
import { UnauthorizedError, fetchMetrics } from "@/lib/api";
import { getAccessToken } from "@/lib/auth";
import type { Overview } from "@/lib/types";

export default function DashboardPage() {
  const router = useRouter();
  const [overview, setOverview] = useState<Overview | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const load = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      setOverview(await fetchMetrics());
    } catch (err) {
      if (err instanceof UnauthorizedError) {
        router.replace("/login");
        return;
      }
      setError(err instanceof Error ? err.message : "Ошибка загрузки");
    } finally {
      setLoading(false);
    }
  }, [router]);

  useEffect(() => {
    if (!getAccessToken()) {
      router.replace("/login");
      return;
    }
    queueMicrotask(() => {
      void load();
    });
  }, [load, router]);

  const safe = overview
    ? Math.max(overview.total_messages - overview.scam_messages - overview.suspicious_messages, 0)
    : 0;

  return (
    <main className="min-h-screen bg-background">
      <NavBar active="/" />

      <div className="mx-auto max-w-6xl px-6 py-8">
        <div className="mb-4 flex items-center justify-between">
          <h1 className="text-xl font-bold text-foreground">Метрики</h1>
          <button
            onClick={load}
            className="rounded-lg border border-border px-4 py-2 text-sm font-medium text-muted hover:bg-surface-raised"
          >
            Обновить
          </button>
        </div>
        {loading && <p className="text-muted">Загрузка…</p>}
        {error && <p className="text-scam">{error}</p>}

        {overview && (
          <>
            <div className="grid grid-cols-2 gap-4 lg:grid-cols-5">
              <StatCard label="Пользователи" value={overview.total_users} />
              <StatCard label="Всего проверок" value={overview.total_messages} />
              <StatCard label="Мошенничество" value={overview.scam_messages} accent="text-scam" />
              <StatCard label="Подозрительно" value={overview.suspicious_messages} accent="text-suspicious" />
              <StatCard label="Алерты по звонкам" value={overview.alerted_call_sessions} accent="text-scam" />
            </div>

            <div className="mt-6 grid grid-cols-1 gap-6 lg:grid-cols-2">
              <CategoryChart data={overview.category_distribution} />
              <VerdictSplit
                scam={overview.scam_messages}
                suspicious={overview.suspicious_messages}
                safe={safe}
              />
            </div>
          </>
        )}
      </div>
    </main>
  );
}
