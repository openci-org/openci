import { Storage } from "@google-cloud/storage";

import { OperationError, messageFrom } from "./errors";

type ServiceAccount = {
  client_email?: string;
  private_key?: string;
  project_id?: string;
};

export function createStorageClient(serviceAccountJson: string): Storage {
  let serviceAccount: ServiceAccount;
  try {
    serviceAccount = JSON.parse(serviceAccountJson) as ServiceAccount;
  } catch (error) {
    throw new OperationError(`Could not parse service account JSON: ${messageFrom(error)}`);
  }

  if (!serviceAccount.client_email || !serviceAccount.private_key) {
    throw new OperationError("Service account JSON must contain client_email and private_key");
  }

  return new Storage({
    credentials: {
      client_email: serviceAccount.client_email,
      private_key: serviceAccount.private_key,
    },
    projectId: serviceAccount.project_id,
  });
}
