import Link from "next/link";
export default function HomeRedirect() {
  return (
    <main>
      <meta httpEquiv="refresh" content="0;url=/en/" />
      <Link href="/en/">OpenCI in English</Link>
    </main>
  );
}
