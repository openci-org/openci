import { defineLive } from 'next-sanity'
import { client } from './client'

export const { sanityFetch, SanityLive } = defineLive({
  client,
  // See the `next-sanity` readme to setup visual editing for interactive live preview
  // https://github.com/sanity-io/next-sanity?tab=readme-ov-file#live-content-api
  browserToken: false,
  serverToken: false,
})
