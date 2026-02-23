"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { Plus } from "lucide-react";
import { Button } from "@/components/ui/button";
import {
  Dialog,
  DialogContent,
  DialogFooter,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from "@/components/ui/dialog";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";

interface CreateWorkflowDialogProps {
  orgSlug: string;
  projectId: string;
  /** Optional label override for the trigger button */
  label?: string;
}

export function CreateWorkflowDialog({
  orgSlug,
  projectId,
  label = "New Workflow",
}: CreateWorkflowDialogProps) {
  const router = useRouter();
  const [open, setOpen] = useState(false);
  const [name, setName] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    const trimmed = name.trim();
    if (!trimmed) {
      setError("Workflow name is required.");
      return;
    }
    setError(null);
    setLoading(true);
    try {
      const res = await fetch(
        `/api/orgs/${orgSlug}/projects/${projectId}/workflows`,
        {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ name: trimmed }),
        }
      );
      if (!res.ok) {
        const body = (await res.json()) as { error?: string };
        setError(body.error ?? "Failed to create workflow.");
        return;
      }
      const { workflow } = (await res.json()) as { workflow: { id: string } };
      setOpen(false);
      setName("");
      router.push(`/orgs/${orgSlug}/projects/${projectId}/workflow/${workflow.id}`);
    } catch {
      setError("Network error. Please try again.");
    } finally {
      setLoading(false);
    }
  }

  return (
    <Dialog open={open} onOpenChange={setOpen}>
      <DialogTrigger asChild>
        <Button size="sm">
          <Plus className="size-4" />
          {label}
        </Button>
      </DialogTrigger>
      <DialogContent>
        <DialogHeader>
          <DialogTitle>Create Workflow</DialogTitle>
        </DialogHeader>
        <form onSubmit={handleSubmit} className="flex flex-col gap-4">
          <div className="flex flex-col gap-1.5">
            <Label htmlFor="workflow-name">Workflow name</Label>
            <Input
              id="workflow-name"
              placeholder="e.g. Build & Test"
              value={name}
              onChange={(e) => setName(e.target.value)}
              disabled={loading}
            />
            {error && <p className="text-xs text-destructive">{error}</p>}
          </div>
          <DialogFooter showCloseButton>
            <Button type="submit" size="sm" disabled={loading}>
              {loading ? "Creating…" : "Create"}
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  );
}
