const baseMilliSeconds = 10_000;
const maxBackoffMilliSeconds = 5 * 60_000;

export function backoffMilliSeconds(consecutiveFailures: number): number {
  const delay = baseMilliSeconds * 2 ** Math.min(consecutiveFailures, 10);
  return Math.min(delay, maxBackoffMilliSeconds);
}
