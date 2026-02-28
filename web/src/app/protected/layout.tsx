// This layout now only handles the redirect page at /protected.
// All sidebar/layout rendering is done in /orgs/[orgSlug]/layout.tsx.
export default function ProtectedLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return <>{children}</>;
}
