import { defineString } from "firebase-functions/params";

export const apiServiceAccount = defineString("OPENCI_API_SERVICE_ACCOUNT", {
  default: "openci-functions@openci-b1b91.iam.gserviceaccount.com",
});
export const dispatchServiceAccount = defineString("OPENCI_DISPATCH_SERVICE_ACCOUNT", {
  default: "openci-dispatch@openci-b1b91.iam.gserviceaccount.com",
});
export const recoveryServiceAccount = defineString("OPENCI_RECOVERY_SERVICE_ACCOUNT", {
  default: "openci-recovery@openci-b1b91.iam.gserviceaccount.com",
});
