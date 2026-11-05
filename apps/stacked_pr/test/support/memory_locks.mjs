import { RetryException, StackBusyException } from "../../lib/models.js";

// Service tests use a shared coordinator without accessing a real project.
// Firestore's cross-client atomicity is exercised separately against its emulator.
export class MemoryStackLocks {
  held = new Set();
  async acquire(scope, resources) {
    const keys = [...new Set(resources.map((key) => JSON.stringify([scope, key])))];
    if (keys.some((key) => this.held.has(key)))
      throw new StackBusyException("Stack is already being processed");
    keys.forEach((key) => this.held.add(key));
    let released = false;
    return {
      assertActive() {
        if (released) throw new RetryException("Stack lease expired");
      },
      release: async () => {
        if (released) return;
        released = true;
        keys.forEach((key) => this.held.delete(key));
      },
    };
  }
}
