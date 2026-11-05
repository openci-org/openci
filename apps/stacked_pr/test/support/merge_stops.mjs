export class MemoryMergeStops {
  records = new Map();
  async get(key) {
    return this.records.get(key);
  }
  async close(key, state) {
    if (!this.records.has(key)) this.records.set(key, state);
    return this.records.get(key);
  }
}
