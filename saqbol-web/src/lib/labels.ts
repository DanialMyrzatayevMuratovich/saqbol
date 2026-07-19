export const categoryLabels: Record<string, string> = {
  fake_bank: "Фейк-банк",
  phishing: "Фишинг",
  fake_prize: "Фейк-приз",
  fake_police: "Фейк-полиция",
  kaspi_scam: "Kaspi-скам",
  other: "Другое",
};

export function categoryLabel(name: string): string {
  return categoryLabels[name] ?? name;
}
