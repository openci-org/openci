import { getAuth } from "firebase-admin/auth";
import { HttpsError, onCall } from "firebase-functions/v2/https";
import { connectorConfig } from "@openci/teams-admin";
import { isolatedConnector } from "./executor/store.js";
import { TeamError, TeamManagement } from "./teams/service.js";
import { ManagedTeamStore } from "./teams/store.js";

let service: TeamManagement | undefined;
export const teamManagement = onCall(
  {
    region: "asia-northeast1",
    memory: "128MiB",
    cpu: 1,
    minInstances: 0,
    concurrency: 1,
    timeoutSeconds: 60,
  },
  async (request) => {
    if (!request.auth || request.auth.token.firebase?.sign_in_provider === "anonymous")
      throw new HttpsError("unauthenticated", "Sign in to manage teams");
    try {
      service ??= new TeamManagement(
        new ManagedTeamStore(isolatedConnector(connectorConfig)),
        getAuth(),
      );
      return await service.execute(request.auth.token, request.data);
    } catch (error) {
      if (error instanceof TeamError) throw new HttpsError(error.code, error.message);
      // Auth and FSC errors can include emails, tokens and operation variables.
      throw new HttpsError("unavailable", "Team operation failed; try again");
    }
  },
);
