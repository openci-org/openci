{{flutter_js}}
{{flutter_build_config}}

const loader = document.getElementById('app-loader');
const loaderMessage = document.getElementById('app-loader-message');
let loaderHidden = false;

function updateLoaderMessage(message) {
  if (loaderMessage) {
    loaderMessage.textContent = message;
  }
}

function hideLoader() {
  if (!loader || loaderHidden) {
    return;
  }

  loaderHidden = true;
  loader.classList.add('is-hidden');
  window.setTimeout(() => {
    loader.remove();
  }, 220);
}

window.addEventListener('flutter-first-frame', hideLoader, { once: true });

_flutter.loader.load({
  onEntrypointLoaded: async function(engineInitializer) {
    updateLoaderMessage('アプリを初期化中...');
    const appRunner = await engineInitializer.initializeEngine();

    updateLoaderMessage('アプリを起動中...');
    await appRunner.runApp();
    window.setTimeout(hideLoader, 1500);
  },
});
