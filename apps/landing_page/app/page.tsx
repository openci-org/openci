import type { Metadata } from 'next';

export const metadata: Metadata = {
  title: 'OpenCI',
  description: 'CI/CD for everyone.',
};

export default function HomeRedirectPage() {
  const redirectScript = `
    (function () {
      var lang = navigator.language || navigator.userLanguage || "en";
      if (lang.toLowerCase().startsWith("ja")) {
        window.location.replace("/ja/");
      } else {
        window.location.replace("/en/");
      }
    })();
  `;

  return (
    <main className="flex min-h-dvh items-center justify-center bg-neutral-50 px-6 text-center">
      <script dangerouslySetInnerHTML={{ __html: redirectScript }} />
      <noscript>
        <p className="text-base text-neutral-600">
          <a href="/en/" className="border-b border-neutral-950/25 text-neutral-950 transition-colors hover:border-neutral-950">
            English
          </a>
          {' | '}
          <a href="/ja/" className="border-b border-neutral-950/25 text-neutral-950 transition-colors hover:border-neutral-950">
            日本語
          </a>
        </p>
      </noscript>
    </main>
  );
}
