'use client'

import { useAuth } from '@/lib/auth-context'
import { UserProvider } from '@/lib/user-context'
import { useRouter } from 'next/navigation'
import { useEffect } from 'react'

export default function DashboardLayout({
  children,
}: {
  children: React.ReactNode
}) {
  const { user, loading } = useAuth()
  const router = useRouter()

  useEffect(() => {
    if (!loading && !user) {
      router.replace('/login')
    }
  }, [user, loading, router])

  if (loading) {
    return (
      <div className="flex min-h-dvh items-center justify-center bg-gray-50">
        <div className="size-8 animate-spin rounded-full border-4 border-gray-300 border-t-gray-900" />
      </div>
    )
  }

  if (!user) return null

  return (
    <UserProvider>
      <div className="flex min-h-dvh bg-gray-50">{children}</div>
    </UserProvider>
  )
}
