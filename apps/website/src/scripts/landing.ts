import { cloudRunners, formatRuntimeEstimate } from "../lib/pricing";

for (const card of document.querySelectorAll<HTMLElement>("[data-estimate]")) {
  const input = card.querySelector<HTMLInputElement>("input")!;
  const locale = document.documentElement.lang === "ja" ? "ja" : "en";
  function calculate() {
    for (const runner of cloudRunners) {
      const output = card.querySelector<HTMLOutputElement>(
        `output[data-runner="${runner}"]`,
      )!;
      output.value = formatRuntimeEstimate(input.valueAsNumber, locale, runner);
    }
  }
  input.addEventListener("input", calculate);
  input.addEventListener("change", calculate);
  calculate();
}

const menu = document.querySelector<HTMLDetailsElement>(".mobile-nav")!;
document.addEventListener("click", (event) => {
  if (
    event.target instanceof Element &&
    (!menu.contains(event.target) || event.target.closest("a"))
  )
    menu.open = false;
});
document.addEventListener("keydown", (event) => {
  if (event.key === "Escape" && menu.open) {
    menu.open = false;
    menu.querySelector("summary")?.focus();
  }
});
matchMedia("(min-width: 801px)").addEventListener("change", () => {
  menu.open = false;
});

const root = document.documentElement;
const controls = document.querySelector<HTMLElement>(".display-controls")!;
const themeButton = controls.querySelector<HTMLButtonElement>("[data-theme]")!;
const motionButton =
  controls.querySelector<HTMLButtonElement>("[data-motion]")!;
const systemDark = matchMedia("(prefers-color-scheme: dark)");
const systemStill = matchMedia("(prefers-reduced-motion: reduce)");
function preference(key: string, value?: string) {
  try {
    if (value !== undefined) localStorage.setItem("openci-" + key, value);
    return localStorage.getItem("openci-" + key);
  } catch {
    return null;
  }
}
let theme = preference("theme");
const pause = preference("paused") === "true";
function updateTheme() {
  const dark = theme ? theme === "dark" : systemDark.matches;
  root.dataset.theme = dark ? "dark" : "light";
  themeButton.setAttribute("aria-pressed", String(dark));
  themeButton.firstElementChild!.textContent = dark ? "☀" : "☾";
}
themeButton.addEventListener("click", () => {
  theme = root.dataset.theme === "dark" ? "light" : "dark";
  preference("theme", theme);
  updateTheme();
});
systemDark.addEventListener("change", updateTheme);
updateTheme();
controls.hidden = false;

motionButton.hidden = true;
root.dataset.motion = systemStill.matches || pause ? "paused" : "active";
