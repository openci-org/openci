import { createClient, type SupabaseClient } from "@supabase/supabase-js";
import type { Build } from "./types.js";

export class SupabaseWorkerClient {
  private client: SupabaseClient;

  constructor(supabaseUrl: string, serviceRoleKey: string) {
    this.client = createClient(supabaseUrl, serviceRoleKey);
  }

  async claimNextBuild(workerId: string): Promise<Build | null> {
    const { data, error } = await this.client.rpc("claim_next_build", {
      p_worker_id: workerId,
      p_runner_os: "macos",
    });

    if (error || !data) return null;
    return data as Build;
  }

  async fetchQueuedBuilds(): Promise<Build[]> {
    const { data, error } = await this.client
      .from("builds")
      .select("*")
      .eq("status", "queued")
      .eq("runner_os", "macos")
      .order("created_at", { ascending: true })
      .limit(10);

    if (error || !data) return [];
    return data as Build[];
  }

  async updateBuildStatus(buildId: string, status: string): Promise<void> {
    await this.client.from("builds").update({ status }).eq("id", buildId);
  }

  async insertLog(
    buildId: string,
    message: string,
    level: "info" | "warn" | "error" = "info",
    stepIndex?: number,
    stepName?: string,
  ): Promise<void> {
    await this.client.from("build_logs").insert({
      build_id: buildId,
      message,
      level,
      step_index: stepIndex,
      step_name: stepName,
    });
  }
}
