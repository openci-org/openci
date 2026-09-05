// A smoke-test Activity with no external side effects.
export async function EchoActivity(message: string): Promise<string> {
  return message;
}
