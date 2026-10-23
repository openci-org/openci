(() => {
  const tabs = [...document.querySelectorAll("[data-workflow]")];
  function select(tab) {
    tabs.forEach((item) => {
      const active = item === tab;
      item.classList.toggle("active", active);
      item.setAttribute("aria-selected", String(active));
      item.tabIndex = active ? 0 : -1;
      document.getElementById(item.getAttribute("aria-controls")).hidden =
        !active;
    });
  }
  tabs.forEach((tab, index) => {
    tab.addEventListener("click", () => select(tab));
    tab.addEventListener("keydown", (event) => {
      let next;
      if (event.key === "ArrowRight") next = (index + 1) % tabs.length;
      if (event.key === "ArrowLeft")
        next = (index + tabs.length - 1) % tabs.length;
      if (event.key === "Home") next = 0;
      if (event.key === "End") next = tabs.length - 1;
      if (next === undefined) return;
      event.preventDefault();
      select(tabs[next]);
      tabs[next].focus();
    });
  });
})();
// Keep shared section anchors when switching language. Translated Markdown
// headings have different IDs, so those switches start at the article itself.
(() => {
  const sharedAnchors = new Set([
    "main",
    "features",
    "workflow",
    "pricing",
    "get-started",
    "start",
    "guides",
    "write-dart",
    "open-source",
  ]);
  function updateLanguageLinks() {
    document.querySelectorAll("[data-language-link]").forEach((link) => {
      const url = new URL(link.href);
      url.search = window.location.search;
      url.hash =
        url.pathname === window.location.pathname ||
        sharedAnchors.has(window.location.hash.slice(1))
          ? window.location.hash
          : "";
      link.href = url.pathname + url.search + url.hash;
    });
  }
  updateLanguageLinks();
  window.addEventListener("hashchange", updateLanguageLinks);
})();
