// Blog code controls use the browser clipboard without a framework runtime.
for (const button of document.querySelectorAll("[data-blog-copy]")) {
  button.addEventListener("click", async () => {
    const code = button.closest(".code-block").querySelector("code");
    const label = button.getAttribute("aria-label");
    try {
      await navigator.clipboard.writeText(code.textContent);
      button.setAttribute(
        "aria-label",
        document.documentElement.lang === "ja" ? "コピーしました" : "Copied",
      );
      setTimeout(() => button.setAttribute("aria-label", label), 2000);
    } catch {
      const range = document.createRange();
      range.selectNodeContents(code);
      const selection = window.getSelection();
      selection.removeAllRanges();
      selection.addRange(range);
    }
  });
}
