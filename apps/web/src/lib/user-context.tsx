'use client'

import { useAuth } from '@/lib/auth-context'
import { db } from '@/lib/firebase'
import { usersCollection } from '@/lib/firestore-paths'
import { doc, onSnapshot, updateDoc } from 'firebase/firestore'
import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useState,
  type ReactNode,
} from 'react'

export type NotificationPreference =
  | 'all'
  | 'successOnly'
  | 'failureOnly'
  | 'none'

export interface OpenCIUser {
  id: string
  selectedTeamId: string
  notificationPreference: NotificationPreference
  fcmTokens: string[]
}

interface UserContextType {
  openCIUser: OpenCIUser | null
  userLoading: boolean
  updateSelectedTeamId: (teamId: string) => Promise<void>
  updateNotificationPreference: (
    preference: NotificationPreference,
  ) => Promise<void>
}

const UserContext = createContext<UserContextType | undefined>(undefined)

export function UserProvider({ children }: { children: ReactNode }) {
  const { user } = useAuth()
  const [openCIUser, setOpenCIUser] = useState<OpenCIUser | null>(null)
  const [userLoading, setUserLoading] = useState(true)

  useEffect(() => {
    if (!user) {
      setOpenCIUser(null)
      setUserLoading(false)
      return
    }

    const userDocRef = doc(db, usersCollection, user.uid)
    const unsubscribe = onSnapshot(userDocRef, (snapshot) => {
      if (snapshot.exists()) {
        const data = snapshot.data()
        setOpenCIUser({
          id: user.uid,
          selectedTeamId: data.selectedTeamId ?? '',
          notificationPreference: data.notificationPreference ?? 'all',
          fcmTokens: data.fcmTokens ?? [],
        })
      } else {
        setOpenCIUser(null)
      }
      setUserLoading(false)
    })

    return unsubscribe
  }, [user])

  const updateSelectedTeamId = useCallback(
    async (teamId: string) => {
      if (!user) throw new Error('User is not authenticated')
      const userDocRef = doc(db, usersCollection, user.uid)
      await updateDoc(userDocRef, { selectedTeamId: teamId })
    },
    [user],
  )

  const updateNotificationPreference = useCallback(
    async (preference: NotificationPreference) => {
      if (!user) throw new Error('User is not authenticated')
      const userDocRef = doc(db, usersCollection, user.uid)
      await updateDoc(userDocRef, { notificationPreference: preference })
    },
    [user],
  )

  const value = useMemo(
    () => ({
      openCIUser,
      userLoading,
      updateSelectedTeamId,
      updateNotificationPreference,
    }),
    [
      openCIUser,
      userLoading,
      updateSelectedTeamId,
      updateNotificationPreference,
    ],
  )

  return <UserContext.Provider value={value}>{children}</UserContext.Provider>
}

export function useOpenCIUser() {
  const context = useContext(UserContext)
  if (context === undefined) {
    throw new Error('useOpenCIUser must be used within a UserProvider')
  }
  return context
}
