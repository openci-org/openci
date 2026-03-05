'use client'

import { useAuth } from '@/lib/auth-context'

export default function DashboardPage() {
  const { user, signOut } = useAuth()

  if (!user) return null

  return (
    <div className="flex flex-1 flex-col">
      <header className="flex items-center justify-between border-b border-gray-200 bg-white px-6 py-4">
        <h1 className="text-lg font-semibold text-gray-900">Dashboard</h1>
        <div className="flex items-center gap-4">
          <span className="text-sm text-gray-700">
            {user.displayName ?? user.email}
          </span>
          <button
            type="button"
            onClick={signOut}
            className="rounded-lg px-3 py-1.5 text-sm font-medium text-gray-600 hover:bg-gray-100"
          >
            Sign out
          </button>
        </div>
      </header>
      <main className="flex-1 p-6">
        <div className="mx-auto max-w-5xl">
          <h2 className="text-2xl font-bold text-gray-900">
            Welcome, {user.displayName ?? 'there'}!
          </h2>
          <p className="mt-2 text-gray-600">
            Your CI/CD dashboard is ready. Start by connecting a repository.
          </p>
        </div>
      </main>
    </div>
  )
}
