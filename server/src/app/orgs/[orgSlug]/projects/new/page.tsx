"use client";

import { useState, use } from "react";
import { useRouter } from "next/navigation";
import { Button } from "@/components/ui/button";
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Badge } from "@/components/ui/badge";
import { ArrowLeft, X } from "lucide-react";
import Link from "next/link";

const FRAMEWORKS = ["Swift", "Kotlin", "Flutter", "React Native", "Unity"];
const PLATFORMS = ["iOS", "Android", "macOS", "tvOS", "watchOS", "Web"];

function slugify(value: string): string {
  return value
    .toLowerCase()
    .trim()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-+|-+$/g, "");
}

export default function NewProjectPage({
  params,
}: {
  params: Promise<{ orgSlug: string }>;
}) {
  const { orgSlug } = use(params);
  const router = useRouter();

  const [name, setName] = useState("");
  const [slug, setSlug] = useState("");
  const [slugManuallyEdited, setSlugManuallyEdited] = useState(false);
  const [description, setDescription] = useState("");
  const [framework, setFramework] = useState("");
  const [platforms, setPlatforms] = useState<string[]>([]);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const handleNameChange = (value: string) => {
    setName(value);
    if (!slugManuallyEdited) {
      setSlug(slugify(value));
    }
  };

  const handleSlugChange = (value: string) => {
    setSlug(value.toLowerCase().replace(/[^a-z0-9-]/g, ""));
    setSlugManuallyEdited(true);
  };

  const togglePlatform = (p: string) => {
    setPlatforms((prev) =>
      prev.includes(p) ? prev.filter((x) => x !== p) : [...prev, p]
    );
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsSubmitting(true);
    setError(null);

    const res = await fetch(`/api/orgs/${orgSlug}/projects`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ name, slug, description, framework: framework || undefined, platforms }),
    });

    if (!res.ok) {
      const data = (await res.json()) as { error?: string };
      setError(data.error === "slug_taken" ? "This slug is already taken" : (data.error ?? "An error occurred"));
      setIsSubmitting(false);
      return;
    }

    const { project } = (await res.json()) as { project: { id: string; slug: string } };
    router.push(`/orgs/${orgSlug}/projects/${project.id}`);
  };

  return (
    <div className="flex flex-col gap-6 max-w-2xl">
      <div className="flex items-center gap-3">
        <Button variant="ghost" size="sm" asChild>
          <Link href={`/orgs/${orgSlug}/projects`}>
            <ArrowLeft className="size-4" />
            Back
          </Link>
        </Button>
        <div>
          <h1 className="text-2xl font-bold">New Project</h1>
        </div>
      </div>

      <Card>
        <CardHeader>
          <CardTitle className="text-base">Project Details</CardTitle>
          <CardDescription>Configure your new CI/CD project.</CardDescription>
        </CardHeader>
        <CardContent>
          <form onSubmit={handleSubmit} className="flex flex-col gap-5">
            {/* Name */}
            <div className="grid gap-2">
              <Label htmlFor="name">Project Name <span className="text-destructive">*</span></Label>
              <Input
                id="name"
                placeholder="My iOS App"
                value={name}
                onChange={(e) => handleNameChange(e.target.value)}
                required
              />
            </div>

            {/* Slug */}
            <div className="grid gap-2">
              <Label htmlFor="slug">URL Slug <span className="text-destructive">*</span></Label>
              <Input
                id="slug"
                placeholder="my-ios-app"
                value={slug}
                onChange={(e) => handleSlugChange(e.target.value)}
                pattern="[a-z0-9-]{2,60}"
                required
              />
              <p className="text-xs text-muted-foreground">
                Used in URLs. Lowercase letters, numbers, and hyphens only.
              </p>
            </div>

            {/* Description */}
            <div className="grid gap-2">
              <Label htmlFor="description">Description</Label>
              <Input
                id="description"
                placeholder="A short description of your project"
                value={description}
                onChange={(e) => setDescription(e.target.value)}
              />
            </div>

            {/* Framework */}
            <div className="grid gap-2">
              <Label>Framework</Label>
              <div className="flex flex-wrap gap-2">
                {FRAMEWORKS.map((f) => (
                  <button
                    key={f}
                    type="button"
                    onClick={() => setFramework(framework === f ? "" : f)}
                    className={`rounded-full px-3 py-1 text-sm border transition-colors ${
                      framework === f
                        ? "bg-primary text-primary-foreground border-primary"
                        : "border-border hover:bg-muted"
                    }`}
                  >
                    {f}
                  </button>
                ))}
              </div>
            </div>

            {/* Platforms */}
            <div className="grid gap-2">
              <Label>Platforms</Label>
              <div className="flex flex-wrap gap-2">
                {PLATFORMS.map((p) => (
                  <button
                    key={p}
                    type="button"
                    onClick={() => togglePlatform(p)}
                    className={`inline-flex items-center gap-1 rounded-full px-3 py-1 text-sm border transition-colors ${
                      platforms.includes(p)
                        ? "bg-primary text-primary-foreground border-primary"
                        : "border-border hover:bg-muted"
                    }`}
                  >
                    {p}
                    {platforms.includes(p) && <X className="size-3" />}
                  </button>
                ))}
              </div>
              {platforms.length > 0 && (
                <div className="flex flex-wrap gap-1 mt-1">
                  {platforms.map((p) => (
                    <Badge key={p} variant="secondary" className="text-xs">{p}</Badge>
                  ))}
                </div>
              )}
            </div>

            {error && <p className="text-sm text-destructive">{error}</p>}

            <div className="flex gap-3 pt-2">
              <Button type="submit" disabled={isSubmitting || !name || !slug}>
                {isSubmitting ? "Creating..." : "Create Project"}
              </Button>
              <Button type="button" variant="outline" asChild>
                <Link href={`/orgs/${orgSlug}/projects`}>Cancel</Link>
              </Button>
            </div>
          </form>
        </CardContent>
      </Card>
    </div>
  );
}
