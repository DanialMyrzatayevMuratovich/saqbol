"use client";

import {
  Bar,
  BarChart,
  CartesianGrid,
  ResponsiveContainer,
  Tooltip,
  XAxis,
  YAxis,
} from "recharts";

import { categoryLabel } from "@/lib/labels";
import type { CategoryCount } from "@/lib/types";

interface CategoryChartProps {
  data: CategoryCount[];
}

export function CategoryChart({ data }: CategoryChartProps) {
  const chartData = data.map((item) => ({
    name: categoryLabel(item.name),
    count: item.count,
  }));

  return (
    <div className="rounded-2xl border border-border bg-surface p-5">
      <h2 className="mb-4 text-lg font-semibold">Категории мошенничества</h2>

      {chartData.length === 0 ? (
        <p className="py-20 text-center text-muted">Пока нет данных</p>
      ) : (
        <ResponsiveContainer width="100%" height={260}>
          <BarChart data={chartData} margin={{ top: 8, right: 8, bottom: 8, left: 8 }}>
            <CartesianGrid strokeDasharray="3 3" stroke="var(--border)" vertical={false} />
            <XAxis
              dataKey="name"
              tick={{ fontSize: 12, fill: "var(--muted)" }}
              interval={0}
              angle={-15}
              height={50}
              textAnchor="end"
              axisLine={{ stroke: "var(--border)" }}
              tickLine={false}
            />
            <YAxis
              allowDecimals={false}
              tick={{ fontSize: 12, fill: "var(--muted)" }}
              axisLine={false}
              tickLine={false}
            />
            <Tooltip
              cursor={{ fill: "var(--surface-raised)" }}
              contentStyle={{
                background: "var(--surface-raised)",
                border: "1px solid var(--border)",
                borderRadius: "0.75rem",
                color: "var(--foreground)",
              }}
              formatter={(value: number) => value.toLocaleString("ru-RU")}
            />
            {/* One measure, one series: a single accent hue, never a rainbow. */}
            <Bar dataKey="count" name="Проверок" fill="var(--accent-strong)" radius={[4, 4, 0, 0]} />
          </BarChart>
        </ResponsiveContainer>
      )}
    </div>
  );
}
