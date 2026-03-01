"use client";

import { useState } from "react";
import { Button } from "@/components/ui/button";
import {
  Dialog,
  DialogContent,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Checkbox } from "@/components/ui/checkbox";
import type { EnvironmentVariable } from "@/lib/supabase/types";

interface EnvVarDialogProps {
  orgSlug: string;
  projectId: string;
  /** When editing, pass the existing variable. When adding, leave undefined. */
  envVar?: EnvironmentVariable;
  open: boolean;
  onOpenChange: (open: boolean) => void;
  onSaved: () => void;
}

export function EnvVarDialog({
  orgSlug,
  projectId,
  envVar,
  open,
  onOpenChange,
  onSaved,
}: EnvVarDialogProps) {
  const isEditing = envVar !== undefined;
  const submitLabel = isEditing ? "Update" : "Add";
  const [key, setKey] = useState(envVar?.key ?? "");
  const [value, setValue] = useState("");
  const [isSecret, setIsSecret] = useState(envVar?.is_secret ?? false);
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);

  function resetAndClose() {
    setKey(envVar?.key ?? "");
    setValue("");
    setIsSecret(envVar?.is_secret ?? false);
    setError(null);
    onOpenChange(false);
  }

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    const trimmedKey = key.trim();
    if (!isEditing && !trimmedKey) {
      setError("Key is required.");
      return;
    }
    if (!value) {
      setError("Value is required.");
      return;
    }
    setError(null);
    setLoading(true);
    try {
      let res: Response;
      if (isEditing) {
        res = await fetch(
          `/api/orgs/${orgSlug}/projects/${projectId}/env/${envVar.id}`,
          {
            method: "PATCH",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({ value, is_secret: isSecret }),
          }
        );
      } else {
        res = await fetch(
          `/api/orgs/${orgSlug}/projects/${projectId}/env`,
          {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({ key: trimmedKey, value, is_secret: isSecret }),
          }
        );
      }

      if (!res.ok) {
        const body = (await res.json()) as { error?: string };
        if (body.error === "key_taken") {
          setError(`Key "${trimmedKey}" already exists in this project.`);
        } else {
          setError(body.error ?? "Failed to save variable.");
        }
        return;
      }

      onSaved();
      resetAndClose();
    } catch {
      setError("Network error. Please try again.");
    } finally {
      setLoading(false);
    }
  }

  return (
    <Dialog open={open} onOpenChange={(v) => { if (!v) resetAndClose(); else onOpenChange(true); }}>
      <DialogContent>
        <DialogHeader>
          <DialogTitle>{isEditing ? `Edit "${envVar.key}"` : "Add Environment Variable"}</DialogTitle>
        </DialogHeader>
        <form onSubmit={handleSubmit} className="flex flex-col gap-4">
          {!isEditing && (
            <div className="flex flex-col gap-1.5">
              <Label htmlFor="ev-key">Key</Label>
              <Input
                id="ev-key"
                placeholder="e.g. API_KEY"
                value={key}
                onChange={(e) => setKey(e.target.value)}
                disabled={loading}
                className="font-mono"
              />
            </div>
          )}
          <div className="flex flex-col gap-1.5">
            <Label htmlFor="ev-value">
              {isEditing ? "New value" : "Value"}
            </Label>
            <Input
              id="ev-value"
              type={isSecret ? "password" : "text"}
              placeholder={isSecret ? "••••••••" : "value"}
              value={value}
              onChange={(e) => setValue(e.target.value)}
              disabled={loading}
              className="font-mono"
            />
          </div>
          <div className="flex items-center gap-2">
            <Checkbox
              id="ev-secret"
              checked={isSecret}
              onCheckedChange={(v) => setIsSecret(v === true)}
              disabled={loading}
            />
            <Label htmlFor="ev-secret">Store as secret (encrypted in Vault)</Label>
          </div>
          {error && <p className="text-xs text-destructive">{error}</p>}
          <DialogFooter showCloseButton>
            <Button type="submit" size="sm" disabled={loading}>
              {loading ? "Saving…" : submitLabel}
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  );
}
