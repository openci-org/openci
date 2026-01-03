import { MetadataRoute } from 'next'

export default function robots(): MetadataRoute.Robots {
  return {
    rules: {
      userAgent: '*',
      allow: '/',
      disallow: [
        '/work',
        '/work/*',
        '/process',
        '/blog',
        '/blog/*',
        '/contact',
      ],
    },
  }
}
