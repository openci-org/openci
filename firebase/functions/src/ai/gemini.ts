import { GoogleGenAI } from "@google/genai";

export interface GenerateGeminiContentOptions {
  apiKey: string;
  prompt: string;
  systemInstruction?: string;
  model?: string;
}

export async function generateGeminiContent({
  apiKey,
  prompt,
  systemInstruction,
  model = "gemini-3.5-flash",
}: GenerateGeminiContentOptions): Promise<string> {
  if (!apiKey) {
    throw new Error("GEMINI_API_KEY is not configured");
  }
  const ai = new GoogleGenAI({ apiKey });
  const response = await ai.models.generateContent({
    model,
    contents: prompt,
    config: {
      systemInstruction,
    },
  });

  const text = response.text;
  if (!text) {
    throw new Error("Gemini response did not contain text");
  }
  return text;
}
