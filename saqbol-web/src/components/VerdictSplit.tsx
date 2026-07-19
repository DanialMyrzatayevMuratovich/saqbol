"use client";

import { Cell, Pie, PieChart, ResponsiveContainer, Tooltip } from "recharts";

interface VerdictSplitProps {
  scam: number;
  suspicious: number;
  safe: number;
}

/*
 * Verdict colours sit at dE 6.1 under deuteranopia, so colour alone is not a
 * sufficient encoding: slices are separated by a gap and every value is
 * repeated in the labelled list beside the chart.
 */
const slices = [
  { key: "scam", name: "Мошенничество", color: "var(--verdict-scam)" },
  { key: "suspicious", name: "Подозрительно", color: "var(--verdict-suspicious)" },
  { key: "safe", name: "Безопасно", color: "var(--verdict-safe)" },
] as const;

export function VerdictSplit({ scam, suspicious, safe }: VerdictSplitProps) {
  const values = { scam, suspicious, safe };
  const data = slices.map((slice) => ({ name: slice.name, value: values[slice.key] }));
  const total = scam + suspicious + safe;

  return (
    <div className="rounded-2xl border border-border bg-surface p-5">
      <h2 className="mb-4 text-lg font-semibold">Распределение вердиктов</h2>

      {total === 0 ? (
        <p className="py-20 text-center text-muted">Пока нет проверок</p>
      ) : (
        <div className="flex flex-col gap-4 sm:flex-row sm:items-center">
          <div className="relative h-[220px] w-full sm:w-1/2">
            <ResponsiveContainer width="100%" height="100%">
              <PieChart>
                <Pie
                  data={data}
                  dataKey="value"
                  nameKey="name"
                  innerRadius={62}
                  outerRadius={92}
                  paddingAngle={2}
                  stroke="var(--surface)"
                  strokeWidth={2}
                >
                  {slices.map((slice) => (
                    <Cell key={slice.key} fill={slice.color} />
                  ))}
                </Pie>
                <Tooltip
                  contentStyle={{
                    background: "var(--surface-raised)",
                    border: "1px solid var(--border)",
                    borderRadius: "0.75rem",
                    color: "var(--foreground)",
                  }}
                  formatter={(value: number) => value.toLocaleString("ru-RU")}
                />
              </PieChart>
            </ResponsiveContainer>

            {/* Hero number in the donut hole: the headline is the total. */}
            <div className="pointer-events-none absolute inset-0 flex flex-col items-center justify-center">
              <span className="text-2xl font-bold tabular-nums">
                {total.toLocaleString("ru-RU")}
              </span>
              <span className="text-xs text-muted">всего</span>
            </div>
          </div>

          <ul className="flex-1 space-y-2">
            {slices.map((slice) => {
              const value = values[slice.key];
              const percent = total === 0 ? 0 : Math.round((value / total) * 100);
              return (
                <li key={slice.key} className="flex items-center gap-3 text-sm">
                  <span
                    aria-hidden
                    className="h-2.5 w-2.5 shrink-0 rounded-full"
                    style={{ background: slice.color }}
                  />
                  <span className="flex-1 text-muted">{slice.name}</span>
                  <span className="font-semibold tabular-nums">
                    {value.toLocaleString("ru-RU")}
                  </span>
                  <span className="w-10 text-right text-xs tabular-nums text-muted">
                    {percent}%
                  </span>
                </li>
              );
            })}
          </ul>
        </div>
      )}
    </div>
  );
}
