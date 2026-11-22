import { languageHref } from "../lib/language-url";
function updateLanguageLinks() {
  for (const link of document.querySelectorAll("[data-language-link]")) {
    link.href = languageHref(new URL(link.href).pathname, window.location);
  }
}
updateLanguageLinks();
window.addEventListener("hashchange", updateLanguageLinks);
