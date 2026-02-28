import type { SupabaseClient } from "@supabase/supabase-js";
import { describe, expect, it, vi } from "vitest";
import { getEnvVarById } from "../queries";

function makeSupabase(result: { data: unknown; error: unknown }) {
  const single = vi.fn().mockResolvedValue(result);
  const eq = vi.fn().mockReturnValue({ single });
  const select = vi.fn().mockReturnValue({ eq });
  const from = vi.fn().mockReturnValue({ select });
  return { from } as unknown as SupabaseClient;
}

describe("getEnvVarById", () => {
  const baseEnvVar = {
    id: "ev-1",
    team_id: "org-1",
    key: "API_KEY",
    is_secret: false,
    vault_secret_id: null,
    auto_increment: false,
    created_at: "2024-01-01T00:00:00Z",
    updated_at: "2024-01-01T00:00:00Z",
  };

  it("returns null when supabase returns an error", async () => {
    const supabase = makeSupabase({ data: null, error: new Error("not found") });
    const result = await getEnvVarById(supabase, "ev-1");
    expect(result).toBeNull();
  });

  it("returns null when data is null", async () => {
    const supabase = makeSupabase({ data: null, error: null });
    const result = await getEnvVarById(supabase, "ev-1");
    expect(result).toBeNull();
  });

  it("returns env var for plain-text variable", async () => {
    const supabase = makeSupabase({ data: baseEnvVar, error: null });
    const result = await getEnvVarById(supabase, "ev-1");
    expect(result).not.toBeNull();
    if (!result) throw new Error("Expected result to be non-null");
    expect(result.id).toBe("ev-1");
    expect(result.is_secret).toBe(false);
    expect(result.vault_secret_id).toBeNull();
  });

  it("returns env var with vault_secret_id for secret variable", async () => {
    const secretVar = {
      ...baseEnvVar,
      is_secret: true,
      vault_secret_id: "vault-uuid-1",
      value: null,
    };
    const supabase = makeSupabase({ data: secretVar, error: null });
    const result = await getEnvVarById(supabase, "ev-1");
    if (!result) throw new Error("Expected result to be non-null");
    expect(result.is_secret).toBe(true);
    expect(result.vault_secret_id).toBe("vault-uuid-1");
  });
});
