import type { ImageLoaderProps } from 'next/image'

export default function cloudflareLoader({
  src,
  width,
  quality,
}: ImageLoaderProps) {
  const params = [`width=${width}`]
  if (quality) {
    params.push(`quality=${quality}`)
  }
  return `${src}?${params.join('&')}`
}
