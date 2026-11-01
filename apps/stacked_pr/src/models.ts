export type Json = Record<string, unknown>;

export function jsonObject(value: unknown): Json {
  if (value === null || typeof value !== "object" || Array.isArray(value)) {
    throw new TypeError("Expected a JSON object");
  }
  return value as Json;
}
export function object(value: unknown): Json {
  return value !== null && typeof value === "object" && !Array.isArray(value)
    ? (value as Json)
    : {};
}
export function jsonObjects(value: unknown): Json[] {
  if (!Array.isArray(value)) throw new TypeError("Expected a JSON array");
  return value.map(jsonObject);
}

export class Repository {
  constructor(
    readonly id: number,
    readonly fullName: string,
    readonly defaultBranch?: string,
  ) {}
  static fromJson(value: Json): Repository {
    return new Repository(
      value.id as number,
      value.full_name as string,
      value.default_branch as string | undefined,
    );
  }
  get apiPath(): string {
    return `/repos/${this.fullName.split("/").map(encodeURIComponent).join("/")}`;
  }
  toJson(): Json {
    return { id: this.id, full_name: this.fullName, default_branch: this.defaultBranch };
  }
}

export interface PullRequestFields {
  number: number;
  title: string;
  head: string;
  headRef: string;
  base: string;
  baseRef: string;
  url?: string;
  state?: string;
  merged?: boolean;
  draft?: boolean;
  sameRepo?: boolean;
  mergeCommit?: string;
  parent?: number;
  boundary?: string;
  createdAt?: Date;
  mergedAt?: Date;
}

export class PullRequest implements PullRequestFields {
  number: number;
  title: string;
  head: string;
  headRef: string;
  base: string;
  baseRef: string;
  url: string;
  state: string;
  merged: boolean;
  draft: boolean;
  sameRepo: boolean;
  mergeCommit?: string;
  parent?: number;
  boundary?: string;
  createdAt?: Date;
  mergedAt?: Date;

  constructor(fields: PullRequestFields) {
    this.number = fields.number;
    this.title = fields.title;
    this.head = fields.head;
    this.headRef = fields.headRef;
    this.base = fields.base;
    this.baseRef = fields.baseRef;
    this.url = fields.url ?? "";
    this.state = fields.state ?? "open";
    this.merged = fields.merged ?? false;
    this.draft = fields.draft ?? false;
    this.sameRepo = fields.sameRepo ?? true;
    this.mergeCommit = fields.mergeCommit;
    this.parent = fields.parent;
    this.boundary = fields.boundary;
    this.createdAt = fields.createdAt;
    this.mergedAt = fields.mergedAt;
  }
  get isOpen(): boolean {
    return this.state === "open";
  }
  copy(): PullRequest {
    return new PullRequest(this);
  }
  static fromApi(raw: Json, repoId: number): PullRequest {
    const head = jsonObject(raw.head),
      base = jsonObject(raw.base);
    const date = (value: unknown) =>
      typeof value === "string" && Number.isFinite(Date.parse(value)) ? new Date(value) : undefined;
    return new PullRequest({
      number: raw.number as number,
      title: raw.title as string,
      url: raw.html_url as string | undefined,
      state: raw.state as string,
      merged: raw.merged === true || raw.merged_at != null,
      mergeCommit: typeof raw.merge_commit_sha === "string" ? raw.merge_commit_sha : undefined,
      draft: raw.draft === true,
      createdAt: date(raw.created_at),
      mergedAt: date(raw.merged_at),
      head: head.sha as string,
      headRef: head.ref as string,
      base: base.sha as string,
      baseRef: base.ref as string,
      sameRepo: object(head.repo).id === repoId && object(base.repo).id === repoId,
    });
  }
}

export class BranchChange {
  constructor(
    readonly number: number,
    readonly headRef: string,
    readonly oldHead: string,
    readonly newHead: string,
    readonly oldBase: string,
    readonly newBase: string,
  ) {}
  get changesHead(): boolean {
    return this.oldHead !== this.newHead;
  }
  get mutates(): boolean {
    return this.changesHead || this.oldBase !== this.newBase;
  }
}
export interface Job {
  id: string;
  event: string;
  payload: Json;
}
export class RestackException extends Error {
  constructor(
    message: string,
    readonly number?: number,
    readonly files: string[] = [],
  ) {
    super(message);
  }
}
export class RetryException extends Error {}
