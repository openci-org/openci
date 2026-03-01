import { getUserTeams } from '@/lib/supabase/queries'
import { createClient } from '@/lib/supabase/server'
import { redirect } from 'next/navigation'

export default async function ProtectedPage() {
  const supabase = await createClient()
  const { data, error } = await supabase.auth.getClaims()
  if (error || !data?.claims) redirect('/auth/login')

  const teams = await getUserTeams(supabase)
  if (teams.length > 0) {
    redirect(`/teams/${teams[0].slug}`)
  }

  redirect('/onboarding')
}
