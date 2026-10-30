import { randomUUID } from "node:crypto";
import type { DataConnect } from "firebase-admin/data-connect";
import {
  createWebhookTask,
  getWebhookTaskByDeliveryId,
  requestWebhookTaskPlanning,
} from "@openci/webhooks-admin";

export interface WebhookDelivery {
  deliveryId: string;
  eventType: "push" | "pull_request";
  payload: string;
}

export class ConflictingWebhookDeliveryError extends Error {
  constructor() {
    super("Delivery ID is already associated with another event or payload");
  }
}

export async function enqueueWebhook(
  dataConnect: DataConnect,
  delivery: WebhookDelivery,
): Promise<"created" | "duplicate"> {
  let id: string = randomUUID();
  let result: "created" | "duplicate" = "created";
  try {
    await createWebhookTask(dataConnect, {
      id,
      ...delivery,
      // The legacy table stores Unix seconds; never take this from the payload.
      receivedAt: Math.floor(Date.now() / 1000).toString(),
    });
  } catch (error) {
    // A constraint error or lost response is only a successful duplicate if
    // this exact delivery was durably saved. Never classify every DB error as
    // a duplicate, and never upsert an existing task back to pending.
    const existing = (
      await getWebhookTaskByDeliveryId(dataConnect, {
        deliveryId: delivery.deliveryId,
      })
    ).data.webhookTask;
    if (!existing) {
      throw error;
    }
    if (existing.eventType !== delivery.eventType || existing.payload !== delivery.payload) {
      throw new ConflictingWebhookDeliveryError();
    }
    id = existing.id;
    result = "duplicate";
  }
  // Await the small ID-only mutation before acknowledging GitHub. If dispatch
  // fails after storage, redelivery looks up the same task and signals it again.
  await requestWebhookTaskPlanning(dataConnect, { id });
  return result;
}
