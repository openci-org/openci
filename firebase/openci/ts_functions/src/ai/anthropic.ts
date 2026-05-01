import { accessSecret } from "../secretManager";

let cachedApiKey: string | undefined;

async function getAnthropicApiKey(): Promise<string> {
  cachedApiKey ??= await accessSecret("ANTHROPIC_API_KEY");
  return cachedApiKey;
}

export async function createAnthropicMessage({
  model,
  maxTokens,
  system,
  messages,
}: {
  model: string;
  maxTokens: number;
  system?: string;
  messages: Array<{ role: string; content: string }>;
}): Promise<string> {
  const apiKey = await getAnthropicApiKey();
  const response = await fetch("https://api.anthropic.com/v1/messages", {
    method: "POST",
    headers: {
      "x-api-key": apiKey,
      "anthropic-version": "2023-06-01",
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      model,
      max_tokens: maxTokens,
      ...(system ? { system } : {}),
      messages,
    }),
  });

  const data = (await response.json()) as {
    content?: Array<{ type?: string; text?: string }>;
    error?: { message?: string };
  };

  if (!response.ok) {
    throw new Error(data.error?.message ?? `Anthropic API error: ${response.status}`);
  }

  return (data.content ?? [])
    .filter((block) => block.type === "text" && typeof block.text === "string")
    .map((block) => block.text)
    .join("");
}
