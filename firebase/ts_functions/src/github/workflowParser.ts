export interface JobStep {
  name: string;
  run?: string;
  uses?: string;
  withParams?: Record<string, string>;
}

export interface JobInfo {
  jobKey: string;
  needs: string[];
  runsOn?: string;
  steps: JobStep[];
}

type JsonMap = Record<string, unknown>;

export function matchesTrigger(
  parsed: JsonMap,
  triggerType: string,
  triggerBranch?: string,
): boolean {
  const on = parsed.on;
  if (on === undefined || on === null) return false;
  const yamlTriggerKey = triggerType === "pullRequest" ? "pull_request" : triggerType;

  if (typeof on === "string") return on === yamlTriggerKey;
  if (Array.isArray(on)) return on.includes(yamlTriggerKey);
  if (typeof on === "object") {
    const triggers = on as JsonMap;
    if (!(yamlTriggerKey in triggers)) return false;
    const triggerConfig = triggers[yamlTriggerKey];
    if (triggerConfig === null || triggerConfig === undefined) return true;
    if (typeof triggerConfig === "object") {
      const branches = (triggerConfig as JsonMap).branches;
      if (branches !== undefined && triggerBranch !== undefined) {
        const branchList = Array.isArray(branches) ? branches.map(String) : [String(branches)];
        if (!branchList.includes(triggerBranch)) return false;
      }
    }
    return true;
  }
  return false;
}

export function extractJobs(parsed: JsonMap): JobInfo[] {
  const jobs = parsed.jobs;
  if (typeof jobs !== "object" || jobs === null || Array.isArray(jobs)) return [];
  const jobInfos: JobInfo[] = [];

  for (const [jobKey, job] of Object.entries(jobs as JsonMap)) {
    if (typeof job !== "object" || job === null || Array.isArray(job)) continue;
    const jobMap = job as JsonMap;
    if (!Array.isArray(jobMap.steps)) continue;
    const steps: JobStep[] = [];
    for (const step of jobMap.steps) {
      if (typeof step !== "object" || step === null || Array.isArray(step)) continue;
      const stepMap = step as JsonMap;
      const name = typeof stepMap.name === "string" ? stepMap.name : "";
      if (typeof stepMap.uses === "string") {
        let withParams: Record<string, string> | undefined;
        if (
          typeof stepMap.with === "object" &&
          stepMap.with !== null &&
          !Array.isArray(stepMap.with)
        ) {
          withParams = Object.fromEntries(
            Object.entries(stepMap.with as JsonMap).map(([key, value]) => [key, String(value)]),
          );
        }
        steps.push({ name, uses: stepMap.uses, ...(withParams ? { withParams } : {}) });
      } else if (typeof stepMap.run === "string") {
        steps.push({ name, run: stepMap.run });
      }
    }
    if (steps.length === 0) continue;
    const needs = Array.isArray(jobMap.needs)
      ? jobMap.needs.map(String)
      : typeof jobMap.needs === "string"
        ? [jobMap.needs]
        : [];
    jobInfos.push({
      jobKey,
      needs,
      runsOn: typeof jobMap["runs-on"] === "string" ? jobMap["runs-on"] : undefined,
      steps,
    });
  }

  return jobInfos;
}

export function workflowFileDocId(
  teamId: string,
  repository: string,
  branch: string,
  fileName: string,
): string {
  return `${teamId}_${repository.replaceAll("/", "_")}_${branch}_${fileName}`;
}
