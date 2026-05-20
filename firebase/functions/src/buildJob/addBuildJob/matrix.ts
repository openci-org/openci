export type MatrixValue = string | number | boolean;
export type MatrixCell = Record<string, MatrixValue>;

function isRecord(value: unknown): value is Record<string, unknown> {
  if (typeof value !== "object") return false;
  if (value === null) return false;
  if (Array.isArray(value)) return false;
  return true;
}

function matrixValue(value: unknown): MatrixValue | undefined {
  if (typeof value === "string") return value;
  if (typeof value === "number" && Number.isFinite(value)) return value;
  if (typeof value === "boolean") return value;
  return undefined;
}

function normalizeCell(value: unknown): MatrixCell | undefined {
  if (!isRecord(value)) return undefined;
  const cell: MatrixCell = {};
  for (const [key, rawValue] of Object.entries(value)) {
    const normalized = matrixValue(rawValue);
    if (normalized === undefined) return undefined;
    cell[key] = normalized;
  }
  return cell;
}

function cartesianProduct(axes: [string, MatrixValue[]][]): MatrixCell[] {
  let combinations: MatrixCell[] = [{}];
  for (const [key, values] of axes) {
    if (values.length === 0) return [];
    const next: MatrixCell[] = [];
    for (const combination of combinations) {
      for (const value of values) {
        next.push({ ...combination, [key]: value });
      }
    }
    combinations = next;
  }
  return combinations;
}

function cellMatches(candidate: MatrixCell, pattern: MatrixCell): boolean {
  return Object.entries(pattern).every(([key, value]) => candidate[key] === value);
}

function canMergeInclude(
  combination: MatrixCell,
  include: MatrixCell,
  axisKeys: ReadonlySet<string>,
): boolean {
  return Object.entries(include).every(([key, value]) => {
    if (!axisKeys.has(key)) return true;
    return !(key in combination) || combination[key] === value;
  });
}

export function expandMatrix(strategy: unknown): MatrixCell[] | null {
  if (!isRecord(strategy)) return null;
  const matrix = strategy.matrix;
  if (!isRecord(matrix)) return null;

  const axes: [string, MatrixValue[]][] = [];
  for (const [key, rawValue] of Object.entries(matrix)) {
    if (key === "include" || key === "exclude") continue;
    if (!Array.isArray(rawValue)) return null;
    const values = rawValue.map(matrixValue);
    if (values.some((value) => value === undefined)) return null;
    axes.push([key, values as MatrixValue[]]);
  }

  const axisKeys = new Set(axes.map(([key]) => key));
  let combinations = axes.length === 0 ? [] : cartesianProduct(axes);

  const excludes = Array.isArray(matrix.exclude)
    ? matrix.exclude.map(normalizeCell).filter((cell): cell is MatrixCell => cell !== undefined)
    : [];
  if (excludes.length > 0) {
    combinations = combinations.filter(
      (combination) => !excludes.some((exclude) => cellMatches(combination, exclude)),
    );
  }

  const includes = Array.isArray(matrix.include)
    ? matrix.include.map(normalizeCell).filter((cell): cell is MatrixCell => cell !== undefined)
    : [];
  for (const include of includes) {
    if (axisKeys.size === 0) {
      combinations.push(include);
      continue;
    }
    let didMerge = false;
    combinations = combinations.map((combination) => {
      if (!canMergeInclude(combination, include, axisKeys)) return combination;
      didMerge = true;
      return { ...combination, ...include };
    });
    if (!didMerge) {
      combinations.push(include);
    }
  }

  if (axes.length === 0 && includes.length === 0) return null;
  return combinations;
}

export function matrixLabel(matrix: MatrixCell): string {
  const name = matrix.name;
  if (typeof name === "string" && name.trim().length > 0) return name;
  return matrixKeyValueLabel(matrix);
}

export function matrixInstanceKey(jobId: string, matrix: MatrixCell): string {
  return `${jobId}[${matrixKeyValueLabel(matrix)}]`;
}

export function matrixKeyValueLabel(matrix: MatrixCell): string {
  return Object.entries(matrix)
    .sort(([left], [right]) => left.localeCompare(right))
    .map(([key, value]) => `${key}=${String(value)}`)
    .join(",");
}

const matrixExpressionPattern = /\$\{\{\s*matrix\.([A-Za-z_][A-Za-z0-9_-]*)\s*\}\}/gu;

export function resolveMatrixExpressions(value: unknown, matrix: MatrixCell): unknown {
  if (typeof value === "string") {
    return value.replace(matrixExpressionPattern, (match, key: string) => {
      const replacement = matrix[key];
      return replacement === undefined ? match : String(replacement);
    });
  }
  if (Array.isArray(value)) {
    return value.map((item) => resolveMatrixExpressions(item, matrix));
  }
  if (isRecord(value)) {
    return Object.fromEntries(
      Object.entries(value).map(([key, item]) => [key, resolveMatrixExpressions(item, matrix)]),
    );
  }
  return value;
}
