import { ImageResponse } from 'next/og'

export const size = {
  width: 1200,
  height: 630,
}

export const contentType = 'image/png'

export default async function Image() {
  return new ImageResponse(
    <div
      style={{
        width: '100%',
        height: '100%',
        display: 'flex',
        flexDirection: 'column',
        justifyContent: 'center',
        padding: '80px',
        background: 'linear-gradient(135deg, #e8f5e9 0%, #e0f2f1 50%, #e8eaf6 100%)',
        fontFamily: 'system-ui, sans-serif',
      }}
    >
      <div
        style={{
          display: 'flex',
          alignItems: 'center',
          gap: '16px',
          marginBottom: '48px',
        }}
      >
        <div
          style={{
            fontSize: 32,
            fontWeight: 700,
            color: '#1a1a1a',
          }}
        >
          OpenCI
        </div>
      </div>

      <div
        style={{
          fontSize: 72,
          fontWeight: 700,
          color: '#1a1a1a',
          lineHeight: 1.1,
          marginBottom: '24px',
        }}
      >
        CI/CD Made Easy.
      </div>

      <div
        style={{
          fontSize: 32,
          color: '#555555',
          lineHeight: 1.4,
        }}
      >
        Simple, fast, and surprisingly affordable.
      </div>

      <div
        style={{
          display: 'flex',
          gap: '32px',
          marginTop: '48px',
          fontSize: 22,
          color: '#777777',
        }}
      >
        <span>✅ 60 min/mo free</span>
        <span>✅ Apple Silicon Mac</span>
        <span>✅ GitHub Actions compatible</span>
      </div>
    </div>,
    {
      ...size,
    },
  )
}
