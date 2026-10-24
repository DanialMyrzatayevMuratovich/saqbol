import { describe, expect, it } from "vitest";

import { maskUserPhone } from "./phone";

describe("maskUserPhone", () => {
  it.each([
    "+77001234501",
    "77001234501",
    "+7 (700) 123-45-01",
    "  +7 700 123 45 01  ",
    "8 (700) 123-45-01",
  ])("masks a complete number in format %s", (phone) => {
    expect(maskUserPhone(phone)).toBe("+7 700 *** ** 01");
  });

  it("preserves only the prefix and final two digits", () => {
    expect(maskUserPhone("+77715555599")).toBe("+7 771 *** ** 99");
  });

  it.each(["", "   ", "+7700", "+770012345012", "+12025550123", "user+77001234501"])(
    "hides unsupported or incomplete input %s",
    (phone) => {
      expect(maskUserPhone(phone)).toBe("—");
    },
  );
});
