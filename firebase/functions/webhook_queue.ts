import { randomUUID } from "node:crypto";
import type { DataConnect } from "firebase-admin/data-connect";
import { createWebhookTask, getWebhookTaskByDeliveryId } from "@openci/webhooks-admin";

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
  try {
    await createWebhookTask(dataConnect, {
      id: randomUUID(),
      ...delivery,
      // The legacy table stores Unix seconds; never take this from the payload.
      receivedAt: Math.floor(Date.now() / 1000).toString(),
    });
    return "created";
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
    return "duplicate";
  }
}
