export function matchesTrigger(
  parsed: Record<string, unknown>,
  triggerType: string,
  triggerBranch?: string,
): boolean {
  const on = parsed.on;
  if (on === undefined || on === null) return false;

  // on: push
  if (typeof on === "string") {
    return on === triggerType;
  }

  // on: [push, pull_request]
  if (Array.isArray(on)) {
    return on.includes(triggerType);
  }

  // on:
  //   push:
  //     branches: [main]
  if (typeof on === "object") {
    return matchesTriggerObject(on as Record<string, unknown>, triggerType, triggerBranch);
  }

  return false;
}

function matchesTriggerObject(
  triggers: Record<string, unknown>,
  triggerType: string,
  triggerBranch?: string,
): boolean {
  if (!(triggerType in triggers)) return false;

  const config = triggers[triggerType];
  if (config === null || config === undefined) return true;
  if (typeof config !== "object") return true;

  return matchesBranchFilter(config as Record<string, unknown>, triggerBranch);
}

function matchesBranchFilter(config: Record<string, unknown>, triggerBranch?: string): boolean {
  const branches = config.branches;
  if (branches === undefined || triggerBranch === undefined) return true;

  const branchList = Array.isArray(branches) ? branches.map(String) : [String(branches)];
  return branchList.includes(triggerBranch);
}
