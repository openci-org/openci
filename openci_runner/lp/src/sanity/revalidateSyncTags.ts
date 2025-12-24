import { revalidateTag } from 'next/cache'

// This is optional, hides the console.log from the <SanityLive /> component
export const revalidateSyncTags = async (tags: string[]) => {
  'use server'
  await revalidateTag('sanity:fetch-sync-tags')
  for (const _tag of tags) {
    const tag = `sanity:${_tag}`
    await revalidateTag(tag)
    // console.log(`<SanityLive /> revalidated tag: ${tag}`)
  }
}
