export function maskUserPhone(phone: string): string {
  const normalized = phone.trim().replace(/[\s()-]/g, "");
  const match = /^(?:\+?7|8)(\d{3})\d{5}(\d{2})$/.exec(normalized);

  // Unsupported or incomplete values must not fall back to the raw number.
  if (!match) return "—";

  return `+7 ${match[1]} *** ** ${match[2]}`;
}
