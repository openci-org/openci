/** Bound GitHub traffic and settle in-flight work before the caller releases its lease. */
export async function mapConcurrent<T, R>(
  items: readonly T[],
  action: (item: T) => Promise<R>,
): Promise<R[]> {
  const output: R[] = [];
  for (let start = 0; start < items.length; start += 4) {
    const results = await Promise.allSettled(
      items.slice(start, start + 4).map(async (item) => action(item)),
    );
    for (const result of results) {
      if (result.status === "rejected") throw result.reason;
      output.push(result.value);
    }
  }
  return output;
}
