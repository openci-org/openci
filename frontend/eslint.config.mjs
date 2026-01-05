import nextCoreWebVitals from 'eslint-config-next/core-web-vitals'
import nextTypescript from 'eslint-config-next/typescript'

const eslintConfig = [
  {
    ignores: ['.next/**', 'node_modules/**', 'out/**', '.vercel/**'],
  },
  ...nextCoreWebVitals,
  ...nextTypescript,
  {
    rules: {
      '@next/next/no-img-element': 'off',
      'prefer-const': 'off',
    },
  },
]

export default eslintConfig
