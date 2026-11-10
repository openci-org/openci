{{flutter_js}}
{{flutter_build_config}}

(() => {
  const loader = document.getElementById("app-loader");
  let loaderHidden = false;

  function hideLoader() {
    if (!loader || loaderHidden) {
      return;
    }

    loaderHidden = true;
    loader.classList.add("is-hidden");
    window.setTimeout(() => {
      loader.remove();
    }, 220);
  }

  window.addEventListener("flutter-first-frame", hideLoader, { once: true });

  _flutter.loader.load({
    serviceWorkerSettings: {
      serviceWorkerVersion: null,
    },
    onEntrypointLoaded: async function (engineInitializer) {
      const appRunner = await engineInitializer.initializeEngine();

      await appRunner.runApp();
      window.setTimeout(hideLoader, 1500);
    },
  });
})();
