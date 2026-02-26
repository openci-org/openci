import type { SupabaseClient } from "@supabase/supabase-js";
import { describe, expect, it, vi } from "vitest";
import { getWorkflowById } from "../queries";

function makeSupabase(result: { data: unknown; error: unknown }) {
  const single = vi.fn().mockResolvedValue(result);
  const eq = vi.fn().mockReturnValue({ single });
  const select = vi.fn().mockReturnValue({ eq });
  const from = vi.fn().mockReturnValue({ select });
  return { from } as unknown as SupabaseClient;
}

describe("getWorkflowById", () => {
  const baseWorkflow = {
    id: "wf-1",
    org_id: "org-1",
    name: "My Workflow",
    yaml_definition: "steps: []",
    is_active: true,
    created_at: "2024-01-01T00:00:00Z",
    updated_at: "2024-01-01T00:00:00Z",
    workflow_triggers: [],
    builds: [],
  };

  it("returns null when supabase returns an error", async () => {
    const supabase = makeSupabase({ data: null, error: new Error("not found") });
    const result = await getWorkflowById(supabase, "wf-1");
    expect(result).toBeNull();
  });

  it("returns null when data is null", async () => {
    const supabase = makeSupabase({ data: null, error: null });
    const result = await getWorkflowById(supabase, "wf-1");
    expect(result).toBeNull();
  });

  it("returns workflow with empty last_build when there are no builds", async () => {
    const supabase = makeSupabase({ data: baseWorkflow, error: null });
    const result = await getWorkflowById(supabase, "wf-1");
    expect(result).not.toBeNull();
    if (!result) throw new Error("Expected result to be non-null");
    expect(result.id).toBe("wf-1");
    expect(result.last_build).toBeNull();
    expect(result.workflow_triggers).toEqual([]);
  });

  it("returns the most recent build as last_build", async () => {
    const wfWithBuilds = {
      ...baseWorkflow,
      builds: [
        { id: "b1", status: "success", created_at: "2024-01-01T00:00:00Z" },
        { id: "b2", status: "failure", created_at: "2024-01-02T00:00:00Z" },
        { id: "b3", status: "in_progress", created_at: "2024-01-01T12:00:00Z" },
      ],
    };
    const supabase = makeSupabase({ data: wfWithBuilds, error: null });
    const result = await getWorkflowById(supabase, "wf-1");
    if (!result) throw new Error("Expected result to be non-null");
    expect(result.last_build).toEqual({
      id: "b2",
      status: "failure",
      created_at: "2024-01-02T00:00:00Z",
    });
  });

  it("returns workflow triggers", async () => {
    const trigger = {
      id: "t1",
      workflow_id: "wf-1",
      trigger_type: "push",
      github_repo: "owner/repo",
      branch_pattern: "main",
      created_at: "2024-01-01T00:00:00Z",
      updated_at: "2024-01-01T00:00:00Z",
    };
    const wfWithTrigger = { ...baseWorkflow, workflow_triggers: [trigger] };
    const supabase = makeSupabase({ data: wfWithTrigger, error: null });
    const result = await getWorkflowById(supabase, "wf-1");
    if (!result) throw new Error("Expected result to be non-null");
    expect(result.workflow_triggers).toHaveLength(1);
    expect(result.workflow_triggers[0].trigger_type).toBe("push");
  });
});
