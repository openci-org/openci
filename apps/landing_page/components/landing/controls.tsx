"use client";
import { useEffect, useRef, useState, type KeyboardEvent } from "react";
import { type Locale, translator } from "../../../website/src/lib/i18n";
import { Icon } from "./Icon";

export function moveTab(
  event: KeyboardEvent<HTMLButtonElement>,
  index: number,
  count: number,
  vertical = false,
) {
  const forward = event.key === "ArrowRight" || (vertical && event.key === "ArrowDown");
  const back = event.key === "ArrowLeft" || (vertical && event.key === "ArrowUp");
  let next: number;
  if (forward) next = (index + 1) % count;
  else if (back) next = (index + count - 1) % count;
  else if (event.key === "Home") next = 0;
  else if (event.key === "End") next = count - 1;
  else return;
  event.preventDefault();
  const tab = event.currentTarget
    .closest('[role="tablist"]')
    ?.querySelectorAll<HTMLButtonElement>('[role="tab"]')[next];
  tab?.focus();
  tab?.click();
}

export function CopyCode({ code, locale }: { code: string; locale: Locale }) {
  const t = translator(locale);
  const [copied, setCopied] = useState(false);
  const timer = useRef<ReturnType<typeof setTimeout> | undefined>(undefined);
  useEffect(() => () => clearTimeout(timer.current), []);
  async function copy(button: HTMLButtonElement) {
    try {
      await navigator.clipboard.writeText(code);
      setCopied(true);
      clearTimeout(timer.current);
      timer.current = setTimeout(() => setCopied(false), 1800);
    } catch {
      const content = button.closest(".code-block")?.querySelector("code");
      if (content) {
        const range = document.createRange();
        range.selectNodeContents(content);
        const selection = window.getSelection();
        selection?.removeAllRanges();
        selection?.addRange(range);
      }
    }
  }
  const label = copied ? t("コピーしました", "Copied") : t("コードをコピー", "Copy code");
  return (
    <button
      type="button"
      data-copy-code=""
      onClick={(event) => void copy(event.currentTarget)}
      aria-label={label}
      title={label}
    >
      <Icon name={copied ? "check" : "copy"} />
    </button>
  );
}
