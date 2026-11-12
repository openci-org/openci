const articles = [...document.querySelectorAll("[data-article-category]")];
const filters = [...document.querySelectorAll("[data-category-filter]")];
const count = document.querySelector("[data-article-count]");
for (const button of filters) {
  button.addEventListener("click", () => {
    const category = button.dataset.categoryFilter;
    for (const filter of filters)
      filter.setAttribute("aria-pressed", String(filter === button));
    let visible = 0;
    for (const article of articles) {
      article.hidden =
        category !== "all" && article.dataset.articleCategory !== category;
      if (!article.hidden) visible += 1;
    }
    count.textContent =
      document.documentElement.lang === "ja"
        ? visible + "件"
        : visible + (visible === 1 ? " article" : " articles");
  });
}

const contents = document.querySelector(".article-sidebar details");
if (contents && matchMedia("(max-width: 800px)").matches) contents.open = false;
