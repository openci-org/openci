"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { Plus, Trash2 } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Checkbox } from "@/components/ui/checkbox";
import type { TriggerType, WorkflowWithTriggers } from "@/lib/supabase/types";

const TRIGGER_TYPES: TriggerType[] = ["push", "pull_request", "tag", "release"];

interface TriggerDraft {
  key: string;
  trigger_type: TriggerType;
  github_repo: string;
  branch_pattern: string;
}

let triggerKeyCounter = 0;
function nextKey() {
  triggerKeyCounter += 1;
  return String(triggerKeyCounter);
}

interface WorkflowEditorProps {
  orgSlug: string;
  projectId: string;
  workflow: WorkflowWithTriggers;
}

export function WorkflowEditor({ orgSlug, projectId, workflow }: WorkflowEditorProps) {
  const router = useRouter();
  const [tab, setTab] = useState<"gui" | "yaml">("gui");

  // GUI state
  const [name, setName] = useState(workflow.name);
  const [isActive, setIsActive] = useState(workflow.is_active);
  const [triggers, setTriggers] = useState<TriggerDraft[]>(
    workflow.workflow_triggers.map((t) => ({
      key: t.id,
      trigger_type: t.trigger_type,
      github_repo: t.github_repo,
      branch_pattern: t.branch_pattern ?? "",
    }))
  );

  // YAML state
  const [yaml, setYaml] = useState(workflow.yaml_definition);

  const [saving, setSaving] = useState(false);
  const [deleting, setDeleting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  function addTrigger() {
    setTriggers((prev) => [
      ...prev,
      { key: nextKey(), trigger_type: "push", github_repo: "", branch_pattern: "" },
    ]);
  }

  function removeTrigger(key: string) {
    setTriggers((prev) => prev.filter((t) => t.key !== key));
  }

  function updateTrigger(key: string, patch: Partial<Omit<TriggerDraft, "key">>) {
    setTriggers((prev) => prev.map((t) => (t.key === key ? { ...t, ...patch } : t)));
  }

  async function handleSave() {
    const trimmedName = name.trim();
    if (!trimmedName) {
      setError("Workflow name is required.");
      return;
    }
    setError(null);
    setSaving(true);
    try {
      const body: Record<string, unknown> = { name: trimmedName, is_active: isActive };
      if (tab === "gui") {
        body.triggers = triggers.map((t) => ({
          trigger_type: t.trigger_type,
          github_repo: t.github_repo,
          branch_pattern: t.branch_pattern || null,
        }));
      } else {
        body.yaml_definition = yaml;
      }

      const res = await fetch(
        `/api/orgs/${orgSlug}/projects/${projectId}/workflows/${workflow.id}`,
        {
          method: "PATCH",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify(body),
        }
      );
      if (!res.ok) {
        const data = (await res.json()) as { error?: string };
        setError(data.error ?? "Failed to save workflow.");
        return;
      }
      router.refresh();
    } catch {
      setError("Network error. Please try again.");
    } finally {
      setSaving(false);
    }
  }

  async function handleDelete() {
    if (!confirm(`Delete workflow "${workflow.name}"? This cannot be undone.`)) return;
    setDeleting(true);
    try {
      const res = await fetch(
        `/api/orgs/${orgSlug}/projects/${projectId}/workflows/${workflow.id}`,
        { method: "DELETE" }
      );
      if (!res.ok) {
        const data = (await res.json()) as { error?: string };
        setError(data.error ?? "Failed to delete workflow.");
        return;
      }
      router.push(`/orgs/${orgSlug}/projects/${projectId}/workflow`);
    } catch {
      setError("Network error. Please try again.");
    } finally {
      setDeleting(false);
    }
  }

  return (
    <div className="flex flex-col gap-6">
      {/* Tab switcher */}
      <div className="flex gap-1 border-b">
        <button
          type="button"
          onClick={() => setTab("gui")}
          className={`px-4 py-2 text-sm font-medium border-b-2 -mb-px transition-colors ${
            tab === "gui"
              ? "border-primary text-primary"
              : "border-transparent text-muted-foreground hover:text-foreground"
          }`}
        >
          GUI
        </button>
        <button
          type="button"
          onClick={() => setTab("yaml")}
          className={`px-4 py-2 text-sm font-medium border-b-2 -mb-px transition-colors ${
            tab === "yaml"
              ? "border-primary text-primary"
              : "border-transparent text-muted-foreground hover:text-foreground"
          }`}
        >
          YAML
        </button>
      </div>

      {tab === "gui" ? (
        <div className="flex flex-col gap-6">
          {/* Name */}
          <div className="flex flex-col gap-1.5">
            <Label htmlFor="wf-name">Workflow name</Label>
            <Input
              id="wf-name"
              value={name}
              onChange={(e) => setName(e.target.value)}
            />
          </div>

          {/* Active toggle */}
          <div className="flex items-center gap-2">
            <Checkbox
              id="wf-active"
              checked={isActive}
              onCheckedChange={(v) => setIsActive(v === true)}
            />
            <Label htmlFor="wf-active">Active</Label>
          </div>

          {/* Triggers */}
          <div className="flex flex-col gap-3">
            <div className="flex items-center justify-between">
              <Label>Triggers</Label>
              <Button type="button" variant="outline" size="sm" onClick={addTrigger}>
                <Plus className="size-3.5" />
                Add Trigger
              </Button>
            </div>
            {triggers.length === 0 && (
              <p className="text-sm text-muted-foreground">No triggers configured.</p>
            )}
            {triggers.map((trigger) => (
              <div key={trigger.key} className="flex flex-col gap-2 rounded-md border p-3">
                <div className="flex items-center gap-2">
                  <div className="flex flex-col gap-1 flex-1">
                    <Label htmlFor={`trigger-type-${trigger.key}`}>Type</Label>
                    <select
                      id={`trigger-type-${trigger.key}`}
                      value={trigger.trigger_type}
                      onChange={(e) =>
                        updateTrigger(trigger.key, { trigger_type: e.target.value as TriggerType })
                      }
                      className="flex h-9 w-full rounded-md border border-input bg-transparent px-3 py-1 text-sm shadow-xs transition-colors focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring"
                    >
                      {TRIGGER_TYPES.map((t) => (
                        <option key={t} value={t}>
                          {t}
                        </option>
                      ))}
                    </select>
                  </div>
                  <Button
                    type="button"
                    variant="ghost"
                    size="sm"
                    className="mt-5 shrink-0"
                    onClick={() => removeTrigger(trigger.key)}
                  >
                    <Trash2 className="size-4" />
                  </Button>
                </div>
                <div className="flex flex-col gap-1">
                  <Label htmlFor={`trigger-repo-${trigger.key}`}>GitHub repo (owner/repo)</Label>
                  <Input
                    id={`trigger-repo-${trigger.key}`}
                    placeholder="e.g. acme/my-app"
                    value={trigger.github_repo}
                    onChange={(e) => updateTrigger(trigger.key, { github_repo: e.target.value })}
                  />
                </div>
                <div className="flex flex-col gap-1">
                  <Label htmlFor={`trigger-branch-${trigger.key}`}>Branch pattern (optional)</Label>
                  <Input
                    id={`trigger-branch-${trigger.key}`}
                    placeholder="e.g. main or release/*"
                    value={trigger.branch_pattern}
                    onChange={(e) => updateTrigger(trigger.key, { branch_pattern: e.target.value })}
                  />
                </div>
              </div>
            ))}
          </div>
        </div>
      ) : (
        <div className="flex flex-col gap-1.5">
          <Label htmlFor="wf-yaml">YAML definition</Label>
          <textarea
            id="wf-yaml"
            value={yaml}
            onChange={(e) => setYaml(e.target.value)}
            rows={20}
            spellCheck={false}
            className="font-mono text-xs w-full rounded-md border border-input bg-transparent px-3 py-2 shadow-xs resize-y focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring"
          />
        </div>
      )}

      {error && <p className="text-sm text-destructive">{error}</p>}

      {/* Actions */}
      <div className="flex justify-between">
        <Button
          type="button"
          variant="destructive"
          size="sm"
          onClick={handleDelete}
          disabled={deleting || saving}
        >
          {deleting ? "Deleting…" : "Delete Workflow"}
        </Button>
        <Button type="button" size="sm" onClick={handleSave} disabled={saving || deleting}>
          {saving ? "Saving…" : "Save"}
        </Button>
      </div>
    </div>
  );
}
