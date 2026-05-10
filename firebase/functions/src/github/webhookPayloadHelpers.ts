export function branchFromRef(ref: string): string {
  return ref.replace(/^refs\/heads\//u, "");
}

export function ownerFromFullName(fullName: string): string {
  return fullName.split("/")[0] ?? "";
}
