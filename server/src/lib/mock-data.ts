// Mock data — will be replaced with Supabase data

export const MOCK_ORGS = [
  { id: "org-1", name: "Acme Corp" },
  { id: "org-2", name: "My Team" },
] as const;

export const MOCK_PROJECTS = [
  { id: "project-a", name: "Project A", teamId: "org-1" },
  { id: "project-b", name: "Project B", teamId: "org-1" },
] as const;

// Currently "selected" context (mock — will come from URL/session later)
export const CURRENT_ORG = MOCK_ORGS[0];
export const CURRENT_PROJECT = MOCK_PROJECTS[0];
