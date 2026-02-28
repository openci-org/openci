"use client";

import { useState } from "react";
import { useRouter, usePathname } from "next/navigation";
import { Check, ChevronsUpDown, FolderOpen } from "lucide-react";
import { cn } from "@/lib/utils";
import { Button } from "@/components/ui/button";
import {
  Command,
  CommandEmpty,
  CommandGroup,
  CommandInput,
  CommandItem,
  CommandList,
} from "@/components/ui/command";
import {
  Popover,
  PopoverContent,
  PopoverTrigger,
} from "@/components/ui/popover";
import { MOCK_PROJECTS, CURRENT_PROJECT } from "@/lib/mock-data";
import { useTranslations } from "next-intl";

type Project = (typeof MOCK_PROJECTS)[number];

export function ProjectSwitcher() {
  const [open, setOpen] = useState(false);
  const [selected, setSelected] = useState<Project>(CURRENT_PROJECT);
  const router = useRouter();
  const pathname = usePathname();
  const t = useTranslations("nav");

  const handleSelect = (project: Project) => {
    setSelected(project);
    setOpen(false);

    // If currently inside a project sub-page, navigate to the same sub-page of the new project
    const projectBase = `/protected/projects/${selected.id}`;
    if (pathname.startsWith(projectBase)) {
      const subPath = pathname.slice(projectBase.length);
      router.push(`/protected/projects/${project.id}${subPath}`);
    } else {
      router.push(`/protected/projects/${project.id}`);
    }
  };

  return (
    <Popover open={open} onOpenChange={setOpen}>
      <PopoverTrigger asChild>
        <Button
          variant="ghost"
          role="combobox"
          aria-expanded={open}
          aria-controls="project-switcher-listbox"
          className="w-full justify-between px-2 h-9 text-sm font-medium"
        >
          <div className="flex items-center gap-2 min-w-0">
            <FolderOpen className="size-4 shrink-0 text-muted-foreground" />
            <span className="truncate">{selected.name}</span>
          </div>
          <ChevronsUpDown className="ml-1 size-4 shrink-0 text-muted-foreground" />
        </Button>
      </PopoverTrigger>
      <PopoverContent className="w-56 p-0" align="start" side="bottom" sideOffset={4}>
        <Command id="project-switcher-listbox">
          <CommandInput placeholder={`${t("projects")}...`} />
          <CommandList>
            <CommandEmpty>No projects found.</CommandEmpty>
            <CommandGroup>
              {MOCK_PROJECTS.map((project) => (
                <CommandItem
                  key={project.id}
                  value={project.name}
                  onSelect={() => handleSelect(project)}
                  className="gap-2"
                >
                  <FolderOpen className="size-4 text-muted-foreground" />
                  <span className="flex-1 truncate">{project.name}</span>
                  <Check
                    className={cn(
                      "size-4 shrink-0",
                      selected.id === project.id ? "opacity-100" : "opacity-0"
                    )}
                  />
                </CommandItem>
              ))}
            </CommandGroup>
          </CommandList>
        </Command>
      </PopoverContent>
    </Popover>
  );
}
