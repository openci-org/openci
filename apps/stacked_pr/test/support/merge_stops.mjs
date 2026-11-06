export class MemoryMergeStops {
  records = new Map();
  sequences = new Map();
  rollbacks = new Map();
  async get(key) {
    return this.records.get(key);
  }
  async close(key, state) {
    if (!this.records.has(key)) this.records.set(key, state);
    return this.records.get(key);
  }
  async advance(key, sequence) {
    if (this.records.has(key) || (this.sequences.get(key) ?? -1) > sequence) return false;
    this.sequences.set(key, sequence);
    return true;
  }
  async rollback(key) {
    return this.rollbacks.get(key);
  }
  async saveRollback(key, value) {
    if (this.records.has(key)) return false;
    this.rollbacks.set(key, structuredClone(value));
    return true;
  }
}
