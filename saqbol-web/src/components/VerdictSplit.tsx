"use client";

import { Cell, Legend, Pie, PieChart, ResponsiveContainer, Tooltip } from "recharts";

interface VerdictSplitProps {
  scam: number;
  suspicious: number;
  safe: number;
}

const colors = ["#d32f2f", "#f57c00", "#2e7d32"];

export function VerdictSplit({ scam, suspicious, safe }: VerdictSplitProps) {
  const data = [
    { name: "Мошенничество", value: scam },
    { name: "Подозрительно", value: suspicious },
    { name: "Безопасно", value: safe },
  ];

  const total = scam + suspicious + safe;

  return (
    <div className="rounded-xl border border-slate-200 bg-white p-5 shadow-sm">
      <h2 className="mb-4 text-lg font-semibold text-slate-900">Распределение вердиктов</h2>
      {total === 0 ? (
        <p className="py-20 text-center text-slate-400">Пока нет проверок</p>
      ) : (
        <ResponsiveContainer width="100%" height={300}>
          <PieChart>
            <Pie data={data} dataKey="value" nameKey="name" innerRadius={70} outerRadius={110} paddingAngle={2}>
              {data.map((entry, index) => (
                <Cell key={entry.name} fill={colors[index]} />
              ))}
            </Pie>
            <Tooltip />
            <Legend />
          </PieChart>
        </ResponsiveContainer>
      )}
    </div>
  );
}
