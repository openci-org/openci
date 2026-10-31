import { defineString } from "firebase-functions/params";
import type { GlobalOptions } from "firebase-functions/v2";

// Only Orchard clients join this network. GitHub and Google API traffic keeps
// the normal serverless route, so no VPC connector or Cloud NAT is required.
export const orchardNetworkOptions = {
  networkInterface: {
    network: defineString("ORCHARD_VPC_NETWORK", { default: "orchard" }),
    subnetwork: defineString("ORCHARD_VPC_SUBNETWORK", { default: "orchard-tokyo" }),
    tags: ["orchard-client"],
  },
  vpcEgress: "PRIVATE_RANGES_ONLY",
} satisfies Pick<GlobalOptions, "networkInterface" | "vpcEgress">;
