import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
  RulesTestEnvironment,
} from "@firebase/rules-unit-testing";
import { mkdirSync, readFileSync, writeFileSync } from "fs";
import { dirname, resolve } from "path";
import { fileURLToPath } from "url";
import { afterAll, beforeAll, beforeEach, describe, it } from "vitest";

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

let testEnv: RulesTestEnvironment;

beforeAll(async () => {
  const rulesPath = resolve(__dirname, "../../firestore.rules");
  const rules = readFileSync(rulesPath, "utf8");

  testEnv = await initializeTestEnvironment({
    projectId: "openci-b1b91",
    firestore: {
      rules,
      host: "127.0.0.1",
      port: 8080,
    },
  });
});

beforeEach(async () => {
  await testEnv.clearFirestore();
});

afterAll(async () => {
  try {
    const projectId = "openci-b1b91";
    const coverageUrl = `http://127.0.0.1:8080/emulator/v1/projects/${projectId}:ruleCoverage.html`;
    const response = await fetch(coverageUrl);
    if (response.ok) {
      const html = await response.text();
      const coverageDir = resolve(__dirname, "../coverage");
      mkdirSync(coverageDir, { recursive: true });
      writeFileSync(resolve(coverageDir, "rules-coverage.html"), html);
      console.log(
        `\n✔ Generated Firestore rules coverage report at ${resolve(coverageDir, "rules-coverage.html")}\n`,
      );
    }
  } catch (error) {
    console.error("Failed to generate rules coverage report:", error);
  }

  await testEnv.cleanup();
});

describe("Firestore Security Rules", () => {
  const aliceUid = "alice-user-id";
  const bobUid = "bob-user-id";

  describe("users_v0 collection", () => {
    it("allows authenticated user to create their own user document with valid data", async () => {
      const db = testEnv.authenticatedContext(aliceUid).firestore();
      const docRef = db.doc(`users_v0/${aliceUid}`);

      const validUserData = {
        id: aliceUid,
        email: "alice@example.com",
        displayName: "Alice",
        photoUrl: "https://example.com/alice.png",
        selectedTeamId: null,
        selectedRepository: null,
        selectedBranch: null,
        notificationPreference: "all",
        fcmTokens: [],
        createdAt: new Date(),
        updatedAt: new Date(),
      };

      await assertSucceeds(docRef.set(validUserData));
    });

    it("denies creating another user's document", async () => {
      const db = testEnv.authenticatedContext(aliceUid).firestore();
      const docRef = db.doc(`users_v0/${bobUid}`);

      const validUserData = {
        id: bobUid,
        email: "bob@example.com",
        displayName: "Bob",
        createdAt: new Date(),
        updatedAt: new Date(),
      };

      await assertFails(docRef.set(validUserData));
    });

    it("allows user to read their own user document", async () => {
      // データをあらかじめセットしておく
      await testEnv.withSecurityRulesDisabled(async (context) => {
        const db = context.firestore();
        await db.doc(`users_v0/${aliceUid}`).set({
          id: aliceUid,
          email: "alice@example.com",
        });
      });

      const db = testEnv.authenticatedContext(aliceUid).firestore();
      await assertSucceeds(db.doc(`users_v0/${aliceUid}`).get());
    });

    it("denies reading another user's document", async () => {
      await testEnv.withSecurityRulesDisabled(async (context) => {
        const db = context.firestore();
        await db.doc(`users_v0/${bobUid}`).set({
          id: bobUid,
          email: "bob@example.com",
        });
      });

      const db = testEnv.authenticatedContext(aliceUid).firestore();
      await assertFails(db.doc(`users_v0/${bobUid}`).get());
    });
  });

  describe("teams_v0 collection", () => {
    const teamId = "test-team-id";

    it("allows user to create a team when they are the only member in the members list", async () => {
      const db = testEnv.authenticatedContext(aliceUid).firestore();
      const docRef = db.doc(`teams_v0/${teamId}`);

      const validTeamData = {
        id: teamId,
        name: "Alice Team",
        members: [aliceUid],
        installationIds: [],
        aiEnabled: false,
        githubBaseUrl: null,
        githubApiBaseUrl: null,
        createdAt: new Date(),
        updatedAt: new Date(),
      };

      await assertSucceeds(docRef.set(validTeamData));
    });

    it("denies creating a team if the creator is not a member", async () => {
      const db = testEnv.authenticatedContext(aliceUid).firestore();
      const docRef = db.doc(`teams_v0/${teamId}`);

      const invalidTeamData = {
        id: teamId,
        name: "Alice Team",
        members: [bobUid], // creator is alice, but member is bob
        installationIds: [],
        aiEnabled: false,
        createdAt: new Date(),
        updatedAt: new Date(),
      };

      await assertFails(docRef.set(invalidTeamData));
    });

    it("allows team members to get team details", async () => {
      await testEnv.withSecurityRulesDisabled(async (context) => {
        const db = context.firestore();
        await db.doc(`teams_v0/${teamId}`).set({
          id: teamId,
          name: "Alice Team",
          members: [aliceUid],
        });
      });

      const db = testEnv.authenticatedContext(aliceUid).firestore();
      await assertSucceeds(db.doc(`teams_v0/${teamId}`).get());
    });

    it("denies non-team members from getting team details", async () => {
      await testEnv.withSecurityRulesDisabled(async (context) => {
        const db = context.firestore();
        await db.doc(`teams_v0/${teamId}`).set({
          id: teamId,
          name: "Alice Team",
          members: [aliceUid],
        });
      });

      const db = testEnv.authenticatedContext(bobUid).firestore();
      await assertFails(db.doc(`teams_v0/${teamId}`).get());
    });
  });

  describe("workspaces collection", () => {
    const workspaceId = "test-workspace-id";

    it("allows user to create a workspace when they are the owner", async () => {
      const db = testEnv.authenticatedContext(aliceUid).firestore();
      const docRef = db.doc(`workspaces/${workspaceId}`);

      const validWorkspaceData = {
        ownerUid: aliceUid,
        name: "Alice Workspace",
      };

      await assertSucceeds(docRef.set(validWorkspaceData));
    });

    it("denies workspace creation if ownerUid doesn't match authenticated user", async () => {
      const db = testEnv.authenticatedContext(aliceUid).firestore();
      const docRef = db.doc(`workspaces/${workspaceId}`);

      const invalidWorkspaceData = {
        ownerUid: bobUid,
        name: "Alice Workspace",
      };

      await assertFails(docRef.set(invalidWorkspaceData));
    });

    it("allows members to read the workspace", async () => {
      await testEnv.withSecurityRulesDisabled(async (context) => {
        const db = context.firestore();
        await db.doc(`workspaces/${workspaceId}`).set({
          ownerUid: bobUid,
          name: "Bob Workspace",
        });
        await db.doc(`workspaces/${workspaceId}/members/${aliceUid}`).set({
          role: "member",
        });
      });

      const db = testEnv.authenticatedContext(aliceUid).firestore();
      await assertSucceeds(db.doc(`workspaces/${workspaceId}`).get());
    });

    it("denies non-members from reading the workspace", async () => {
      await testEnv.withSecurityRulesDisabled(async (context) => {
        const db = context.firestore();
        await db.doc(`workspaces/${workspaceId}`).set({
          ownerUid: bobUid,
          name: "Bob Workspace",
        });
      });

      const db = testEnv.authenticatedContext(aliceUid).firestore();
      await assertFails(db.doc(`workspaces/${workspaceId}`).get());
    });

    it("allows members to access sub-collections (e.g. issues)", async () => {
      await testEnv.withSecurityRulesDisabled(async (context) => {
        const db = context.firestore();
        await db.doc(`workspaces/${workspaceId}`).set({
          ownerUid: bobUid,
          name: "Bob Workspace",
        });
        await db.doc(`workspaces/${workspaceId}/members/${aliceUid}`).set({
          role: "member",
        });
        await db.doc(`workspaces/${workspaceId}/issues/issue-1`).set({
          title: "Test Issue",
        });
      });

      const db = testEnv.authenticatedContext(aliceUid).firestore();
      await assertSucceeds(db.doc(`workspaces/${workspaceId}/issues/issue-1`).get());
    });

    it("denies non-members from accessing sub-collections", async () => {
      await testEnv.withSecurityRulesDisabled(async (context) => {
        const db = context.firestore();
        await db.doc(`workspaces/${workspaceId}`).set({
          ownerUid: bobUid,
          name: "Bob Workspace",
        });
        await db.doc(`workspaces/${workspaceId}/issues/issue-1`).set({
          title: "Test Issue",
        });
      });

      const db = testEnv.authenticatedContext(aliceUid).firestore();
      await assertFails(db.doc(`workspaces/${workspaceId}/issues/issue-1`).get());
    });
  });
});
