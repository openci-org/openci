import nextConfig from 'eslint-config-next'
import coreWebVitals from 'eslint-config-next/core-web-vitals'

const eslintConfig = [
  ...nextConfig,
  ...coreWebVitals,
  {
    rules: {
      '@next/next/no-img-element': 'off',
      'prefer-const': 'off',
    },
  },
]

export default eslintConfig
