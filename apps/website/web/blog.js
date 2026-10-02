(() => {
  const filters = [...document.querySelectorAll("[data-category-filter]")];
  const articles = [...document.querySelectorAll("[data-article-category]")];
  const count = document.querySelector("[data-article-count]");
  filters.forEach((button) => {
    button.addEventListener("click", () => {
      const category = button.dataset.categoryFilter;
      filters.forEach((filter) => filter.setAttribute("aria-pressed", String(filter === button)));
      let visible = 0;
      articles.forEach((article) => {
        article.hidden = category !== "すべて" && article.dataset.articleCategory !== category;
        if (!article.hidden) visible += 1;
      });
      count.textContent = `${String(visible).padStart(2, "0")} ${visible === 1 ? "ARTICLE" : "ARTICLES"}`;
    });
  });
})();
