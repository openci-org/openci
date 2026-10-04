(() => {
  const root = document.querySelector('.docs-shell');
  if (!root) return;
  const codeThemeKey = 'genuineci.docs.codeTheme';
  const codeSurfaces = [...root.querySelectorAll('[data-code-theme]')];
  function applyCodeTheme(theme) {
    if (theme !== 'light' && theme !== 'dark') return;
    for (const surface of codeSurfaces) {
      surface.dataset.codeTheme = theme;
      surface.querySelectorAll('[data-code-theme-choice]').forEach((button) => {
        button.setAttribute('aria-pressed', String(button.dataset.codeThemeChoice === theme));
      });
    }
  }
  try { applyCodeTheme(localStorage.getItem(codeThemeKey)); } catch (_) { /* Storage may be unavailable. */ }
  root.querySelectorAll('[data-code-theme-choice]').forEach((button) => {
    button.addEventListener('click', () => {
      const theme = button.dataset.codeThemeChoice;
      applyCodeTheme(theme);
      try { localStorage.setItem(codeThemeKey, theme); } catch (_) { /* The current page still updates. */ }
    });
  });
  const dialog = document.getElementById('docs-search');
  const input = document.getElementById('docs-query');
  const results = document.getElementById('docs-results');
  const status = document.getElementById('docs-search-status');
  const pages = JSON.parse(document.getElementById('docs-search-data').textContent);
  let selected = -1;
  let visibleResults = [];
  function select(index) {
    visibleResults.forEach((item) => item.classList.remove('is-selected'));
    selected = index;
    if (selected >= 0 && visibleResults[selected]) {
      visibleResults[selected].classList.add('is-selected');
      visibleResults[selected].scrollIntoView({ block: 'nearest' });
    }
  }
  function render() {
    const terms = input.value.trim().toLowerCase().split(/\s+/).filter(Boolean);
    const matches = pages.filter((page) => terms.every((term) => `${page.title} ${page.description} ${page.body}`.toLowerCase().includes(term)));
    results.replaceChildren();
    selected = -1;
    status.textContent = terms.length ? `${matches.length}件のドキュメント` : 'ドキュメントから探す';
    for (const page of matches) {
      const link = document.createElement('a');
      link.href = page.url;
      link.className = 'd-search-result';
      const group = document.createElement('span'); group.textContent = page.group;
      const title = document.createElement('strong'); title.textContent = page.title;
      const desc = document.createElement('p'); desc.textContent = page.description;
      link.append(group, title, desc);
      results.append(link);
    }
    visibleResults = [...results.querySelectorAll('a')];
    if (!matches.length) {
      const empty = document.createElement('p');
      empty.className = 'd-search-empty';
      empty.textContent = '見つかりませんでした。別のキーワードで試してください。';
      results.append(empty);
    }
  }
  function openSearch() { render(); if (!dialog.open) dialog.showModal(); input.focus(); }
  document.querySelectorAll('[data-search-open]').forEach((button) => button.addEventListener('click', openSearch));
  document.querySelector('[data-search-close]').addEventListener('click', () => dialog.close());
  input.addEventListener('input', render);
  input.addEventListener('keydown', (event) => {
    if (event.key === 'ArrowDown' && visibleResults.length) { event.preventDefault(); select((selected + 1) % visibleResults.length); }
    if (event.key === 'ArrowUp' && visibleResults.length) { event.preventDefault(); select(selected <= 0 ? visibleResults.length - 1 : selected - 1); }
    if (event.key === 'Enter' && visibleResults.length) { event.preventDefault(); visibleResults[Math.max(selected, 0)].click(); }
  });
  document.addEventListener('keydown', (event) => {
    if ((event.metaKey || event.ctrlKey) && event.key.toLowerCase() === 'k') {
      event.preventDefault(); dialog.open ? dialog.close() : openSearch();
    }
  });
  const menu = document.getElementById('docs-menu');
  document.querySelector('[data-menu-open]').addEventListener('click', () => menu.showModal());
  document.querySelector('[data-menu-close]').addEventListener('click', () => menu.close());
  for (const modal of [menu, dialog]) {
    modal.addEventListener('click', (event) => {
      const rect = modal.getBoundingClientRect();
      if (event.target === modal && (event.clientX < rect.left || event.clientX > rect.right || event.clientY < rect.top || event.clientY > rect.bottom)) modal.close();
    });
    modal.addEventListener('close', () => { document.documentElement.style.overflow = ''; });
    new MutationObserver(() => { document.documentElement.style.overflow = menu.open || dialog.open ? 'hidden' : ''; }).observe(modal, { attributes: true, attributeFilter: ['open'] });
  }
  root.querySelectorAll('[data-doc-copy], [data-copy-home]').forEach((copy) => {
    copy.addEventListener('click', async () => {
      const code = copy.closest('.code-block, .d-home-code').querySelector('pre code');
      try {
        await navigator.clipboard.writeText(code.textContent);
        copy.querySelector('span').textContent = 'コピー済み';
        copy.setAttribute('aria-label', 'コピーしました');
        setTimeout(() => { copy.querySelector('span').textContent = 'コピー'; copy.setAttribute('aria-label', 'コードをコピー'); }, 2000);
      } catch (_) {
        copy.querySelector('span').textContent = '選択してコピー';
        copy.setAttribute('aria-label', 'コードを選択してコピーしてください');
        const range = document.createRange(); range.selectNodeContents(code);
        const selection = window.getSelection(); selection.removeAllRanges(); selection.addRange(range);
      }
    });
  });
  const links = [...document.querySelectorAll('.d-toc .d-toc-links a')];
  const headings = links.map((link) => document.getElementById(decodeURIComponent(link.hash.slice(1)))).filter(Boolean);
  if (headings.length) {
    function updateToc() {
      let active = headings[0];
      for (const heading of headings) if (heading.getBoundingClientRect().top < 180) active = heading;
      links.forEach((link) => {
        const current = decodeURIComponent(link.hash.slice(1)) === active.id;
        link.classList.toggle('is-current', current);
        if (current) link.setAttribute('aria-current', 'location'); else link.removeAttribute('aria-current');
      });
    }
    let queued = false;
    window.addEventListener('scroll', () => { if (!queued) { queued = true; requestAnimationFrame(() => { updateToc(); queued = false; }); } }, { passive: true });
    updateToc();
  }
})();
