import { describe, expect, it } from "vitest";

import { categoryLabel } from "./labels";

describe("categoryLabel", () => {
  it("maps known categories to Russian labels", () => {
    expect(categoryLabel("fake_bank")).toBe("Фейк-банк");
    expect(categoryLabel("phishing")).toBe("Фишинг");
  });

  it("falls back to the raw name for unknown categories", () => {
    expect(categoryLabel("unknown_scheme")).toBe("unknown_scheme");
  });
});
