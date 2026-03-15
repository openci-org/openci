import { defineConfig } from 'vite-plus';

export default defineConfig({
  fmt: {
    "semi": false,
    "singleQuote": true,
    "trailingComma": "all",
    "printWidth": 80,
    "experimentalTailwindcss": {
      "stylesheet": "./src/styles/tailwind.css",
      "functions": ["clsx"]
    }
  },
  lint: {
    "plugins": [
      "react",
      "typescript",
      "nextjs",
      "jsx-a11y",
      "import"
    ],
    "rules": {
      "no-unused-vars": "warn",
      "nextjs/no-img-element": "off",
      "jsx-a11y/no-autofocus": "off"
    },
    "ignorePatterns": [
      ".next/**",
      "node_modules/**",
      "out/**",
      ".vercel/**"
    ],
    "options": {
      "typeAware": true,
      "typeCheck": true
    }
  },
});
