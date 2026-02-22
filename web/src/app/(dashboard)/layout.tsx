import { AuthProvider } from '@/lib/auth-context'
import type { Metadata } from 'next'
import DashboardLayout from './dashboard-layout'

export const metadata: Metadata = {
  title: {
    template: '%s - OpenCI Dashboard',
    default: 'Dashboard - OpenCI',
  },
}

export default function Layout({ children }: { children: React.ReactNode }) {
  return (
    <AuthProvider>
      <DashboardLayout>{children}</DashboardLayout>
    </AuthProvider>
  )
}
