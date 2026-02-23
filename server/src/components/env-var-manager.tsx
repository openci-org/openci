"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { Key, Lock, RefreshCw, Plus, Pencil, Trash2 } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { EnvVarDialog } from "@/components/env-var-dialog";
import type { EnvironmentVariable } from "@/lib/supabase/types";

interface EnvVarManagerProps {
  orgSlug: string;
  projectId: string;
  envVars: EnvironmentVariable[];
}

export function EnvVarManager({ orgSlug, projectId, envVars }: EnvVarManagerProps) {
  const router = useRouter();
  const [addOpen, setAddOpen] = useState(false);
  const [editTarget, setEditTarget] = useState<EnvironmentVariable | null>(null);
  const [deletingId, setDeletingId] = useState<string | null>(null);
  const [deleteError, setDeleteError] = useState<string | null>(null);

  function handleSaved() {
    router.refresh();
  }

  async function handleDelete(ev: EnvironmentVariable) {
    if (!confirm(`Delete "${ev.key}"? This cannot be undone.`)) return;
    setDeletingId(ev.id);
    setDeleteError(null);
    try {
      const res = await fetch(
        `/api/orgs/${orgSlug}/projects/${projectId}/env/${ev.id}`,
        { method: "DELETE" }
      );
      if (!res.ok) {
        const body = (await res.json()) as { error?: string };
        setDeleteError(body.error ?? "Failed to delete variable.");
        return;
      }
      router.refresh();
    } catch {
      setDeleteError("Network error. Please try again.");
    } finally {
      setDeletingId(null);
    }
  }

  return (
    <>
      <div className="flex items-center justify-between">
        <Button size="sm" onClick={() => setAddOpen(true)}>
          <Plus className="size-4" />
          Add Variable
        </Button>
      </div>

      <Card>
        <CardHeader>
          <CardTitle className="text-base">Variables</CardTitle>
          <CardDescription>
            Environment variables are injected into each build. Secrets are encrypted in Supabase Vault.
          </CardDescription>
        </CardHeader>
        <CardContent>
          {deleteError && (
            <p className="text-sm text-destructive mb-3">{deleteError}</p>
          )}
          {envVars.length === 0 ? (
            <p className="text-sm text-muted-foreground py-6 text-center">
              No environment variables defined yet.
            </p>
          ) : (
            <div className="divide-y">
              {envVars.map((ev) => (
                <div key={ev.id} className="flex items-center gap-3 py-3">
                  <div className="flex size-7 items-center justify-center rounded bg-muted shrink-0">
                    {ev.is_secret ? (
                      <Lock className="size-3.5 text-muted-foreground" />
                    ) : (
                      <Key className="size-3.5 text-muted-foreground" />
                    )}
                  </div>
                  <div className="flex-1 min-w-0">
                    <div className="text-sm font-mono font-medium">{ev.key}</div>
                    <div className="text-xs text-muted-foreground flex items-center gap-2 mt-0.5">
                      {ev.is_secret && <span>Secret</span>}
                      {ev.auto_increment && (
                        <span className="flex items-center gap-1">
                          <RefreshCw className="size-3" />
                          Auto-increment
                        </span>
                      )}
                      <span>Updated {new Date(ev.updated_at).toLocaleDateString()}</span>
                    </div>
                  </div>
                  <div className="flex items-center gap-1 shrink-0">
                    <Button
                      variant="ghost"
                      size="sm"
                      onClick={() => setEditTarget(ev)}
                    >
                      <Pencil className="size-3.5" />
                    </Button>
                    <Button
                      variant="ghost"
                      size="sm"
                      onClick={() => handleDelete(ev)}
                      disabled={deletingId === ev.id}
                    >
                      <Trash2 className="size-3.5" />
                    </Button>
                  </div>
                </div>
              ))}
            </div>
          )}
        </CardContent>
      </Card>

      <EnvVarDialog
        orgSlug={orgSlug}
        projectId={projectId}
        open={addOpen}
        onOpenChange={setAddOpen}
        onSaved={handleSaved}
      />

      {editTarget && (
        <EnvVarDialog
          orgSlug={orgSlug}
          projectId={projectId}
          envVar={editTarget}
          open={editTarget !== null}
          onOpenChange={(v) => { if (!v) setEditTarget(null); }}
          onSaved={handleSaved}
        />
      )}
    </>
  );
}
