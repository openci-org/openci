import { Resend } from "resend";

let resendInstance: Resend | null = null;

function getResendClient(): Resend {
  if (!resendInstance) {
    const apiKey = process.env.RESEND_API_KEY;
    if (!apiKey) {
      throw new Error("RESEND_API_KEY environment variable is not set");
    }
    resendInstance = new Resend(apiKey);
  }
  return resendInstance;
}

export interface SendEmailOptions {
  to: string | string[];
  subject: string;
  html: string;
  from?: string;
}

export async function sendEmail(
  options: SendEmailOptions,
): Promise<{ id: string }> {
  const client = getResendClient();
  const from = options.from ?? process.env.RESEND_FROM_EMAIL;
  if (!from) {
    throw new Error("RESEND_FROM_EMAIL environment variable is not set");
  }

  const { data, error } = await client.emails.send({
    from,
    to: options.to,
    subject: options.subject,
    html: options.html,
  });

  if (error) {
    throw new Error(`Resend API error: ${error.message}`);
  }

  return { id: data?.id ?? "" };
}

/** Reset the singleton — for testing only. */
export function _resetForTesting(): void {
  resendInstance = null;
}
