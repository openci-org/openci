import { updateTag } from 'next/cache'

// This is optional, hides the console.log from the <SanityLive /> component
export const revalidateSyncTags = async (tags: string[]) => {
  'use server'
  updateTag('sanity:fetch-sync-tags')
  for (const _tag of tags) {
    const tag = `sanity:${_tag}`
    updateTag(tag)
    // console.log(`<SanityLive /> revalidated tag: ${tag}`)
  }
}
