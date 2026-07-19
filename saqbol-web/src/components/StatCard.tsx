interface StatCardProps {
  label: string;
  value: number;
  accent?: string;
}

export function StatCard({ label, value, accent = "text-slate-900" }: StatCardProps) {
  return (
    <div className="rounded-xl border border-slate-200 bg-white p-5 shadow-sm">
      <p className="text-sm text-slate-500">{label}</p>
      <p className={`mt-2 text-3xl font-bold ${accent}`}>{value.toLocaleString("ru-RU")}</p>
    </div>
  );
}
