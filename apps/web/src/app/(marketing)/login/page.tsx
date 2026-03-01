'use client'

import { Link } from '@/marketing-components/link'
import { Mark } from '@/marketing-components/logo'
import { useRouter } from 'next/navigation'
import { useState, type FormEvent } from 'react'

export default function Login() {
  const router = useRouter()
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [isAgreed, setIsAgreed] = useState(true)
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const handleSignIn = async (e: FormEvent) => {
    e.preventDefault()
    if (!isAgreed) return
    setLoading(true)
    setError(null)
    try {
      // TODO: Integrate with Supabase Auth
      setError(
        'Authentication is being migrated to Supabase. Please try again later.',
      )
    } finally {
      setLoading(false)
    }
  }

  const handleCreateAccount = async () => {
    if (!isAgreed || !email || !password) return
    setLoading(true)
    setError(null)
    try {
      // TODO: Integrate with Supabase Auth
      setError(
        'Authentication is being migrated to Supabase. Please try again later.',
      )
    } finally {
      setLoading(false)
    }
  }

  return (
    <main className="overflow-hidden bg-gray-50">
      <div className="isolate flex min-h-dvh items-center justify-center p-6 lg:p-8">
        <div className="w-full max-w-md rounded-xl bg-white shadow-md ring-1 ring-black/5">
          <form onSubmit={handleSignIn} className="p-7 sm:p-11">
            <div className="flex items-start">
              <Link href="/" title="Home">
                <Mark className="h-9 fill-black" />
              </Link>
            </div>
            <h1 className="mt-8 text-base/6 font-medium">OpenCI</h1>
            <p className="mt-1 text-sm/5 text-gray-600">
              Sign in to your account to continue.
            </p>
            {error && (
              <div className="mt-4 rounded-lg bg-red-50 p-3 text-sm text-red-600">
                {error}
              </div>
            )}
            <div className="mt-8 space-y-3">
              <label className="text-sm/5 font-medium">Email</label>
              <input
                required
                autoFocus
                type="email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                className="block w-full rounded-lg border border-transparent px-2 py-1.5 text-base/6 shadow-sm ring-1 ring-black/10 focus:outline-2 focus:-outline-offset-1 focus:outline-black sm:text-sm/6"
              />
            </div>
            <div className="mt-8 space-y-3">
              <label className="text-sm/5 font-medium">Password</label>
              <input
                required
                type="password"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                className="block w-full rounded-lg border border-transparent px-2 py-1.5 text-base/6 shadow-sm ring-1 ring-black/10 focus:outline-2 focus:-outline-offset-1 focus:outline-black sm:text-sm/6"
              />
            </div>
            <div className="mt-8 flex items-center gap-3">
              <input
                type="checkbox"
                checked={isAgreed}
                onChange={(e) => setIsAgreed(e.target.checked)}
                className="size-4 rounded-sm border border-transparent shadow-sm ring-1 ring-black/10"
              />
              <span className="text-sm/5">
                I agree to the{' '}
                <Link
                  href="/terms-of-service"
                  className="font-medium text-blue-600 hover:text-blue-500"
                >
                  Terms of Service
                </Link>
              </span>
            </div>
            <div className="mt-8 flex flex-col gap-3">
              <button
                type="submit"
                disabled={!isAgreed || loading}
                className="w-full rounded-lg bg-gray-900 px-4 py-2.5 text-sm font-medium text-white shadow-sm hover:bg-gray-800 disabled:opacity-50"
              >
                {loading ? 'Signing in...' : 'Log in'}
              </button>
              <button
                type="button"
                onClick={handleCreateAccount}
                disabled={!isAgreed || loading || !email || !password}
                className="w-full rounded-lg bg-blue-600 px-4 py-2.5 text-sm font-medium text-white shadow-sm hover:bg-blue-500 disabled:opacity-50"
              >
                Create new account
              </button>
            </div>
          </form>
        </div>
      </div>
    </main>
  )
}
