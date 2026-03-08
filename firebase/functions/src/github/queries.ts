export const OPENCI_DIR_QUERY = `
  query($owner: String!, $repo: String!, $expression: String!) {
    repository(owner: $owner, name: $repo) {
      object(expression: $expression) {
        ... on Tree {
          entries {
            name
            type
            object {
              ... on Blob { text }
            }
          }
        }
      }
    }
  }
`;

export interface OpenciDirEntry {
  name: string;
  type: string;
  object: { text: string } | null;
}

export const BRANCHES_QUERY = `
  query($owner: String!, $repo: String!, $cursor: String) {
    repository(owner: $owner, name: $repo) {
      defaultBranchRef { name }
      refs(refPrefix: "refs/heads/", first: 100, after: $cursor, orderBy: {field: TAG_COMMIT_DATE, direction: DESC}) {
        nodes {
          name
          target {
            ... on Commit { committedDate }
          }
        }
        pageInfo { hasNextPage endCursor }
      }
    }
  }
`;

export interface BranchNode {
  name: string;
  target: { committedDate: string };
}

export interface BranchesQueryResult {
  repository: {
    defaultBranchRef: { name: string } | null;
    refs: {
      nodes: BranchNode[];
      pageInfo: { hasNextPage: boolean; endCursor: string | null };
    };
  };
}

function buildTreeFragment(depth: number): string {
  if (depth === 0) return "name type";
  return `name type object { ... on Tree { entries { ${buildTreeFragment(depth - 1)} } } }`;
}

export const DIRECTORY_TREE_QUERY = `
  query($owner: String!, $repo: String!, $expression: String!) {
    repository(owner: $owner, name: $repo) {
      object(expression: $expression) {
        ... on Tree {
          entries {
            ${buildTreeFragment(7)}
          }
        }
      }
    }
  }
`;

export interface TreeEntry {
  name: string;
  type: string;
  object?: { entries?: TreeEntry[] } | null;
}

export function flattenTreeEntries(entries: TreeEntry[], prefix = ""): string[] {
  const dirs: string[] = [];
  for (const entry of entries) {
    if (entry.type !== "tree") continue;
    const path = prefix ? `${prefix}/${entry.name}` : entry.name;
    dirs.push(path);
    if (entry.object?.entries) {
      dirs.push(...flattenTreeEntries(entry.object.entries, path));
    }
  }
  return dirs;
}
