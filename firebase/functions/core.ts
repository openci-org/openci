// Bootstrap entry point before GitHub/Orchard credentials are provisioned.
// The full index exports these same Functions in the same codebase.
import { initializeApp } from "firebase-admin/app";

initializeApp();
export { teamManagement } from "./team_functions.js";
export { teamSecrets, cleanSecretVersions } from "./secret_functions.js";
export { expireBuildLogs } from "./log_retention_functions.js";
export { teamBilling, cleanDeletedTeamCredentials } from "./billing_functions.js";
