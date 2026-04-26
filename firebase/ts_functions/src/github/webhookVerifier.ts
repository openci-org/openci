export async function verifyGitHubSignature({
  payload,
  signatureHeader,
  secret,
}: {
  payload: string;
  signatureHeader?: string;
  secret: string;
}): Promise<boolean> {
  if (!signatureHeader) {
    return false;
  }
  const { Webhooks } = await import("@octokit/webhooks");
  const webhooks = new Webhooks({ secret });
  return webhooks.verify(payload, signatureHeader);
}
