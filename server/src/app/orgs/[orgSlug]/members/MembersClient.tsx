"use client";

import { useState, useTransition } from "react";
import { useRouter } from "next/navigation";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { CircleUserRound, Mail, UserPlus, Trash2, Loader2, Copy, Check } from "lucide-react";
import type { OrgRole } from "@/lib/supabase/types";

interface Member {
  id: string;
  user_id: string;
  role: OrgRole;
  created_at: string;
  profile: { full_name: string | null; avatar_url: string | null } | null;
}

interface Invitation {
  id: string;
  email: string;
  role: OrgRole;
  expires_at: string;
}

interface Props {
  orgSlug: string;
  currentUserId: string;
  orgRole: OrgRole;
  members: Member[];
  invitations: Invitation[];
}

function RoleBadge({ role }: { role: OrgRole }) {
  const variants: Record<OrgRole, string> = {
    owner: "bg-purple-100 text-purple-800 dark:bg-purple-900 dark:text-purple-200",
    admin: "bg-blue-100 text-blue-800 dark:bg-blue-900 dark:text-blue-200",
    member: "bg-gray-100 text-gray-800 dark:bg-gray-800 dark:text-gray-200",
  };
  return (
    <span
      className={`inline-flex items-center rounded-full px-2 py-0.5 text-xs font-medium ${variants[role]}`}
    >
      {role}
    </span>
  );
}

export function MembersClient({
  orgSlug,
  currentUserId,
  orgRole,
  members,
  invitations,
}: Props) {
  const router = useRouter();
  const [isPending, startTransition] = useTransition();

  // Invite form state
  const [inviteEmail, setInviteEmail] = useState("");
  const [inviteRole, setInviteRole] = useState<OrgRole>("member");
  const [inviteError, setInviteError] = useState<string | null>(null);
  const [inviteLink, setInviteLink] = useState<string | null>(null);
  const [inviting, setInviting] = useState(false);
  const [copied, setCopied] = useState(false);

  const canManage = orgRole === "owner" || orgRole === "admin";
  const isOwner = orgRole === "owner";

  const handleInvite = async (e: React.FormEvent) => {
    e.preventDefault();
    setInviteError(null);
    setInviteLink(null);
    setInviting(true);

    const res = await fetch(`/api/orgs/${orgSlug}/invitations`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ email: inviteEmail, role: inviteRole }),
    });

    if (!res.ok) {
      const data = (await res.json()) as { error?: string };
      setInviteError(
        data.error === "already_invited"
          ? "This email has already been invited."
          : (data.error ?? "An error occurred")
      );
      setInviting(false);
      return;
    }

    const data = (await res.json()) as { inviteLink: string };
    setInviteLink(data.inviteLink);
    setInviteEmail("");
    setInviting(false);
    startTransition(() => router.refresh());
  };

  const handleCopyLink = async () => {
    if (!inviteLink) return;
    await navigator.clipboard.writeText(inviteLink);
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  };

  const handleRoleChange = async (memberId: string, role: OrgRole) => {
    const res = await fetch(`/api/orgs/${orgSlug}/members/${memberId}`, {
      method: "PATCH",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ role }),
    });

    if (!res.ok) {
      const data = (await res.json()) as { error?: string };
      alert(data.error ?? "Failed to update role");
      return;
    }

    startTransition(() => router.refresh());
  };

  const handleRemoveMember = async (memberId: string, displayName: string) => {
    if (!confirm(`Remove ${displayName} from the organization?`)) return;

    const res = await fetch(`/api/orgs/${orgSlug}/members/${memberId}`, {
      method: "DELETE",
    });

    if (!res.ok) {
      const data = (await res.json()) as { error?: string };
      alert(data.error ?? "Failed to remove member");
      return;
    }

    startTransition(() => router.refresh());
  };

  const handleCancelInvitation = async (invitationId: string, email: string) => {
    if (!confirm(`Cancel invitation for ${email}?`)) return;

    const res = await fetch(`/api/orgs/${orgSlug}/invitations/${invitationId}`, {
      method: "DELETE",
    });

    if (!res.ok) {
      const data = (await res.json()) as { error?: string };
      alert(data.error ?? "Failed to cancel invitation");
      return;
    }

    startTransition(() => router.refresh());
  };

  return (
    <div className="flex flex-col gap-6">
      {/* Invite form (admins/owners only) */}
      {canManage && (
        <Card>
          <CardHeader>
            <CardTitle className="text-base flex items-center gap-2">
              <UserPlus className="size-4" />
              Invite Member
            </CardTitle>
            <CardDescription>Send an invitation to add a new member.</CardDescription>
          </CardHeader>
          <CardContent>
            <form onSubmit={handleInvite} className="flex flex-col gap-4">
              <div className="flex gap-3">
                <div className="flex-1 grid gap-1.5">
                  <Label htmlFor="invite-email">Email address</Label>
                  <Input
                    id="invite-email"
                    type="email"
                    placeholder="colleague@example.com"
                    value={inviteEmail}
                    onChange={(e) => setInviteEmail(e.target.value)}
                    required
                  />
                </div>
                <div className="grid gap-1.5">
                  <Label htmlFor="invite-role">Role</Label>
                  <select
                    id="invite-role"
                    value={inviteRole}
                    onChange={(e) => setInviteRole(e.target.value as OrgRole)}
                    className="h-9 w-28 rounded-md border border-input bg-background px-3 py-1 text-sm shadow-sm focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring"
                  >
                    <option value="member">member</option>
                    <option value="admin">admin</option>
                    {isOwner && <option value="owner">owner</option>}
                  </select>
                </div>
              </div>
              {inviteError && <p className="text-sm text-destructive">{inviteError}</p>}
              {inviteLink && (
                <div className="flex flex-col gap-1.5">
                  <p className="text-sm text-muted-foreground">
                    Share this link with the invitee:
                  </p>
                  <div className="flex items-center gap-2 rounded-md border bg-muted/50 px-3 py-2">
                    <code className="flex-1 truncate text-xs">{inviteLink}</code>
                    <Button
                      type="button"
                      variant="ghost"
                      size="icon"
                      className="size-6 shrink-0"
                      onClick={handleCopyLink}
                      title="Copy link"
                    >
                      {copied ? (
                        <Check className="size-3.5 text-green-600" />
                      ) : (
                        <Copy className="size-3.5" />
                      )}
                    </Button>
                  </div>
                </div>
              )}
              <div>
                <Button type="submit" size="sm" disabled={inviting}>
                  {inviting ? (
                    <>
                      <Loader2 className="size-4 animate-spin" />
                      Sending...
                    </>
                  ) : (
                    "Send Invitation"
                  )}
                </Button>
              </div>
            </form>
          </CardContent>
        </Card>
      )}

      {/* Members list */}
      <Card>
        <CardHeader>
          <CardTitle className="text-base">Organization Members</CardTitle>
          <CardDescription>
            {members.length} member{members.length !== 1 ? "s" : ""}
          </CardDescription>
        </CardHeader>
        <CardContent>
          <div className="divide-y">
            {members.map((member) => {
              const displayName =
                member.profile?.full_name ?? member.user_id.slice(0, 8);
              const isSelf = member.user_id === currentUserId;
              const isTargetOwner = member.role === "owner";

              return (
                <div key={member.id} className="flex items-center gap-3 py-3">
                  <div className="flex size-8 items-center justify-center rounded-full bg-muted shrink-0">
                    <CircleUserRound className="size-4 text-muted-foreground" />
                  </div>
                  <div className="flex-1 min-w-0">
                    <div className="text-sm font-medium truncate">
                      {displayName}
                      {isSelf && (
                        <span className="ml-1.5 text-xs text-muted-foreground">
                          (you)
                        </span>
                      )}
                    </div>
                    <div className="text-xs text-muted-foreground">
                      Joined {new Date(member.created_at).toLocaleDateString()}
                    </div>
                  </div>

                  {/* Role selector (only owner can change roles, not for self) */}
                  {isOwner && !isSelf ? (
                    <select
                      value={member.role}
                      onChange={(e) =>
                        handleRoleChange(member.id, e.target.value as OrgRole)
                      }
                      disabled={isPending}
                      className="h-7 w-24 rounded-md border border-input bg-background px-2 text-xs shadow-sm focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring disabled:opacity-50"
                    >
                      <option value="member">member</option>
                      <option value="admin">admin</option>
                      <option value="owner">owner</option>
                    </select>
                  ) : (
                    <RoleBadge role={member.role} />
                  )}

                  {/* Remove / Leave button */}
                  {((canManage && !isTargetOwner && !isSelf) || isSelf) ? (
                    <Button
                      variant="ghost"
                      size="icon"
                      className="size-7 text-muted-foreground hover:text-destructive"
                      onClick={() => handleRemoveMember(member.id, displayName)}
                      disabled={isPending}
                      title={isSelf ? "Leave organization" : "Remove member"}
                    >
                      <Trash2 className="size-3.5" />
                    </Button>
                  ) : (
                    <div className="size-7" />
                  )}
                </div>
              );
            })}
          </div>
        </CardContent>
      </Card>

      {/* Pending invitations */}
      {invitations.length > 0 && (
        <Card>
          <CardHeader>
            <CardTitle className="text-base">Pending Invitations</CardTitle>
            <CardDescription>{invitations.length} pending</CardDescription>
          </CardHeader>
          <CardContent>
            <div className="divide-y">
              {invitations.map((inv) => (
                <div key={inv.id} className="flex items-center gap-3 py-3">
                  <div className="flex size-8 items-center justify-center rounded-full bg-muted shrink-0">
                    <Mail className="size-4 text-muted-foreground" />
                  </div>
                  <div className="flex-1 min-w-0">
                    <div className="text-sm font-medium truncate">{inv.email}</div>
                    <div className="text-xs text-muted-foreground">
                      Expires {new Date(inv.expires_at).toLocaleDateString()}
                    </div>
                  </div>
                  <Badge variant="outline" className="text-xs">
                    {inv.role}
                  </Badge>
                  {canManage && (
                    <Button
                      variant="ghost"
                      size="icon"
                      className="size-7 text-muted-foreground hover:text-destructive"
                      onClick={() => handleCancelInvitation(inv.id, inv.email)}
                      disabled={isPending}
                      title="Cancel invitation"
                    >
                      <Trash2 className="size-3.5" />
                    </Button>
                  )}
                </div>
              ))}
            </div>
          </CardContent>
        </Card>
      )}
    </div>
  );
}
