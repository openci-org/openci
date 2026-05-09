import { request } from "@octokit/request";

import { filterYamlFiles } from "./filterYamlFiles.js";

export interface WorkflowFile {
  name: string;
  content: string;
}

export async function fetchOpenCIWorkflowYamlFiles(
  owner: string,
  repo: string,
  commitSha: string,
  token: string,
  apiBaseUrl: string,
): Promise<WorkflowFile[]> {
  const res = await request("GET /repos/{owner}/{repo}/contents/{path}", {
    baseUrl: apiBaseUrl,
    owner,
    repo,
    path: ".openci",
    ref: commitSha,
    headers: { authorization: `bearer ${token}` },
  });

  if (!Array.isArray(res.data)) {
    throw new Error(`.openci is not a directory in ${owner}/${repo} at ${commitSha}`);
  }

  const yamlFiles = filterYamlFiles(res.data);

  if (yamlFiles.length === 0) return [];

  return Promise.all(
    yamlFiles.map(async (item) => {
      const file = await request("GET /repos/{owner}/{repo}/contents/{path}", {
        baseUrl: apiBaseUrl,
        owner,
        repo,
        path: item.path,
        ref: commitSha,
        headers: {
          authorization: `bearer ${token}`,
          accept: "application/vnd.github.raw+json",
        },
      });
      return { name: item.name, content: file.data as unknown as string };
    }),
  );
}
