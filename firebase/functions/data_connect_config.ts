import type { ConnectorConfig } from "firebase-admin/data-connect";

export function dataConnectServiceId(environment: NodeJS.ProcessEnv = process.env): string {
  const serviceId = environment.OPENCI_DATA_CONNECT_SERVICE_ID ?? "openci-b1b91-service";
  if (!/^[a-z][a-z0-9-]{0,62}$/.test(serviceId)) {
    throw new Error("Invalid OPENCI_DATA_CONNECT_SERVICE_ID");
  }
  return serviceId;
}

// Generated SDKs describe operations; deployment configuration selects the service.
export function configuredConnector(config: ConnectorConfig): ConnectorConfig {
  return { ...config, serviceId: dataConnectServiceId() };
}
