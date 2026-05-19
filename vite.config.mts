const generatedPaths = [
  "**/.next/**",
  "**/dist/**",
  "**/lib/**",
  "**/node_modules/**",
  "**/out/**",
  "firebase/functions/src/generated/**",
];

export default {
  fmt: {
    ignorePatterns: generatedPaths,
  },
  lint: {
    ignorePatterns: generatedPaths,
  },
};
