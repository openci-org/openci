import type { Metadata } from 'next';

const siteUrl = 'https://openci.org';
const siteName = 'OpenCI';
const defaultOgImage = '/ogp.png';

type PageMetadataInput = {
  title: string;
  description: string;
  path: string;
  image?: string;
  locale?: string;
  type?: 'website' | 'article';
  publishedTime?: string;
};

export function createPageMetadata({
  title,
  description,
  path,
  image = defaultOgImage,
  locale = 'ja_JP',
  type = 'website',
  publishedTime,
}: PageMetadataInput): Metadata {
  const url = absoluteUrl(path);
  const imageUrl = absoluteUrl(image);

  return {
    title,
    description,
    alternates: {
      canonical: url,
    },
    openGraph: {
      type,
      title,
      description,
      url,
      siteName,
      locale,
      images: [
        {
          url: imageUrl,
          width: 1200,
          height: 630,
          alt: `${siteName} preview image`,
        },
      ],
      ...(type === 'article' && publishedTime ? { publishedTime } : {}),
    },
    twitter: {
      card: 'summary_large_image',
      title,
      description,
      images: [imageUrl],
    },
  };
}

export function absoluteUrl(path: string) {
  return new URL(path, siteUrl).toString();
}
