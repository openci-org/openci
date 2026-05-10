import type { Response } from "express";

export interface ParsedWebhookRequest {
  eventType: string;
  payload: string;
  signatureHeader: string;
  deliveryId: string;
}

export interface WebhookRequest {
  header(name: string): string | undefined;
  rawBody?: Buffer;
}

export function branchFromRef(ref: string): string {
  return ref.replace(/^refs\/heads\//u, "");
}

export function ownerFromFullName(fullName: string): string {
  return fullName.split("/")[0] ?? "";
}

export function requireInstallationId(
  installation: { id?: number } | undefined,
  response: Response,
): number | undefined {
  const installationId = installation?.id;
  if (!installationId) {
    response.status(400).send("Missing installation ID in webhook payload");
    return undefined;
  }
  return installationId;
}

export function parseWebhookRequest(
  request: WebhookRequest,
  response: Response,
): ParsedWebhookRequest | undefined {
  const eventType = request.header("x-github-event");
  if (!eventType) {
    response.status(400).send("Missing x-github-event header");
    return undefined;
  }

  const payload = request.rawBody?.toString("utf8");
  if (!payload) {
    response.status(400).send("Missing request body");
    return undefined;
  }

  const signatureHeader = request.header("x-hub-signature-256");
  if (!signatureHeader) {
    response.status(400).send("Missing x-hub-signature-256 header");
    return undefined;
  }

  const deliveryId = request.header("x-github-delivery");
  if (!deliveryId) {
    response.status(400).send("Missing x-github-delivery header");
    return undefined;
  }

  return { eventType, payload, signatureHeader, deliveryId };
}
