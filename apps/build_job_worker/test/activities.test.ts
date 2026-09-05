import { describe, expect, it } from "vitest";
import { EchoActivity } from "../src/activities";

describe("EchoActivity", () => {
  it.each(["Hello OpenCI", "", "こんにちは、OpenCI"])(
    "returns the input unchanged: %j",
    async (message) => {
      await expect(EchoActivity(message)).resolves.toBe(message);
    },
  );
});
