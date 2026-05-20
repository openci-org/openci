export type Action = "restore" | "save";

export type Inputs = {
  action: Action;
  serviceAccount: string;
  storageBucket: string;
  firebaseOptionsPath: string;
  cachePath: string;
  keyPrefix: string;
  dependencyPaths: string;
  workingDirectory: string;
  repository: string;
  failOnError: boolean;
};
