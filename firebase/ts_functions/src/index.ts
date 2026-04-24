import { setGlobalOptions } from "firebase-functions/v2";

setGlobalOptions({
  region: "asia-northeast1",
  maxInstances: 10,
});

export { acceptInvitation } from "./invitation/acceptInvitation";
