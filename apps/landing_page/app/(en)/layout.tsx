import type { Metadata } from "next";
import "../globals.css";

export const metadata: Metadata = {
  metadataBase: new URL("https://openci.org"),
  icons: {
    icon: "/favicon.png",
  },
};

export default function EnglishRootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en" className="antialiased" data-scroll-behavior="smooth">
      <body className="isolate min-h-dvh bg-white text-neutral-950">{children}</body>
    </html>
  );
}
