interface StatCardProps {
  label: string;
  value: number;
  /** Theme token for the number, e.g. "text-scam". Defaults to primary ink. */
  accent?: string;
  /** Share of the total (0..1), drawn as a thin meter under the value. */
  share?: number;
}

export function StatCard({ label, value, accent = "text-foreground", share }: StatCardProps) {
  return (
    <div className="relative overflow-hidden rounded-2xl border border-border bg-surface p-5 transition-colors hover:border-accent/40">
      {/* Hairline highlight on the top edge — reads as depth on a dark page. */}
      <div className="absolute inset-x-0 top-0 h-px bg-gradient-to-r from-transparent via-accent/50 to-transparent" />

      <p className="text-sm font-medium text-muted">{label}</p>
      <p className={`mt-2 text-3xl font-bold tabular-nums tracking-tight ${accent}`}>
        {value.toLocaleString("ru-RU")}
      </p>

      {share !== undefined && (
        <div className="mt-3 h-1 overflow-hidden rounded-full bg-surface-raised">
          <div
            className={`h-full rounded-full ${accent.replace("text-", "bg-")}`}
            style={{ width: `${Math.min(Math.max(share, 0), 1) * 100}%` }}
          />
        </div>
      )}
    </div>
  );
}
