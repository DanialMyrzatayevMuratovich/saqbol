"use client";

import { useRouter } from "next/navigation";
import { useCallback, useEffect, useState } from "react";

import { NavBar } from "@/components/NavBar";
import { UnauthorizedError, createModelVersion, fetchModelVersions } from "@/lib/api";
import { getAccessToken } from "@/lib/auth";
import type { ModelVersion } from "@/lib/types";

export default function ModelsPage() {
  const router = useRouter();
  const [items, setItems] = useState<ModelVersion[]>([]);
  const [name, setName] = useState("");
  const [metrics, setMetrics] = useState("");
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [saving, setSaving] = useState(false);

  const load = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      setItems(await fetchModelVersions());
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

  async function onSubmit(event: React.FormEvent) {
    event.preventDefault();
    if (!name.trim()) return;
    setSaving(true);
    setError(null);
    try {
      await createModelVersion(name.trim(), metrics.trim());
      setName("");
      setMetrics("");
      await load();
    } catch (err) {
      setError(err instanceof Error ? err.message : "Не удалось сохранить");
    } finally {
      setSaving(false);
    }
  }

  return (
    <main className="min-h-screen bg-slate-100">
      <NavBar active="/models" />

      <div className="mx-auto max-w-6xl px-6 py-8">
        <h1 className="mb-4 text-xl font-bold text-slate-900">Версии модели</h1>

        <form
          onSubmit={onSubmit}
          className="mb-6 rounded-xl border border-slate-200 bg-white p-5 shadow-sm"
        >
          <div className="grid grid-cols-1 gap-3 md:grid-cols-2">
            <input
              value={name}
              onChange={(event) => setName(event.target.value)}
              placeholder="Название (например xlm-roberta-v1)"
              className="rounded-lg border border-slate-300 px-3 py-2 outline-none focus:border-blue-500"
            />
            <input
              value={metrics}
              onChange={(event) => setMetrics(event.target.value)}
              placeholder='Метрики JSON (например {"f1":0.92})'
              className="rounded-lg border border-slate-300 px-3 py-2 outline-none focus:border-blue-500"
            />
          </div>
          {error && <p className="mt-3 text-sm text-red-600">{error}</p>}
          <button
            type="submit"
            disabled={saving}
            className="mt-4 rounded-lg bg-blue-700 px-4 py-2 text-sm font-medium text-white hover:bg-blue-800 disabled:opacity-60"
          >
            {saving ? "Сохранение…" : "Добавить версию"}
          </button>
        </form>

        {loading ? (
          <p className="text-slate-500">Загрузка…</p>
        ) : (
          <div className="overflow-x-auto rounded-xl border border-slate-200 bg-white">
            <table className="w-full text-left text-sm">
              <thead className="border-b border-slate-200 text-slate-500">
                <tr>
                  <th className="px-4 py-3">Название</th>
                  <th className="px-4 py-3">Метрики</th>
                  <th className="px-4 py-3">Обучена</th>
                </tr>
              </thead>
              <tbody>
                {items.length === 0 ? (
                  <tr>
                    <td colSpan={3} className="px-4 py-8 text-center text-slate-400">
                      Пока нет версий
                    </td>
                  </tr>
                ) : (
                  items.map((item) => (
                    <tr key={item.id} className="border-b border-slate-100">
                      <td className="px-4 py-3 font-medium text-slate-900">{item.name}</td>
                      <td className="px-4 py-3 font-mono text-xs text-slate-600">{item.metrics}</td>
                      <td className="px-4 py-3 text-slate-600">
                        {new Date(item.trained_at).toLocaleString("ru-RU")}
                      </td>
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
