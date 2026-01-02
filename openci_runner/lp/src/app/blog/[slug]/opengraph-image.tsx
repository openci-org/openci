import { image } from '@/sanity/image'
import { getPost } from '@/sanity/queries'
import { ImageResponse } from 'next/og'

// Image metadata
export const size = {
  width: 1200,
  height: 630,
}

export const contentType = 'image/png'

export default async function Image({
  params,
}: {
  params: Promise<{ slug: string }>
}) {
  const { slug } = await params

  const { data: post } = await getPost(slug)
  if (!post) {
    return new ImageResponse(
      <div
        style={{
          fontSize: 128,
          background: 'white',
          width: '100%',
          height: '100%',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
        }}
      >
        Post Not Found
      </div>,
    )
  }

  const imageUrl = post.mainImage
    ? image(post.mainImage).size(1200, 630).url()
    : null

  console.log('imageUrl', imageUrl)
  return new ImageResponse(
    <div
      style={{
        fontSize: 128,
        background: 'white',
        width: '100%',
        height: '100%',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        backgroundImage: `url(${imageUrl})`,
      }}
    ></div>,
  )
}
