import type { Firestore } from "firebase-admin/firestore";
import { describe, expect, it } from "vitest";

import { getTeamIdByInstallationId } from "./getTeamIdByInstallationId";

describe("getTeamIdByInstallationId", () => {
  function fakeDb(queryResult: { empty: boolean; docs: Array<{ id: string }> }): Firestore {
    return {
      collection: () => ({
        where: () => ({
          limit: () => ({
            get: async () => queryResult,
          }),
        }),
      }),
    } as unknown as Firestore;
  }

  it("returns teamId when team exists", async () => {
    const db = fakeDb({ empty: false, docs: [{ id: "team-abc" }] });

    const result = await getTeamIdByInstallationId(db, 12345);

    expect(result).toBe("team-abc");
  });

  it("returns undefined when no team found", async () => {
    const db = fakeDb({ empty: true, docs: [] });

    await expect(getTeamIdByInstallationId(db, 99999)).resolves.toBeUndefined();
  });
});
