const generatedPaths = [
  "**/.next/**",
  "**/dist/**",
  "**/lib/**",
  "**/node_modules/**",
  "**/out/**",
];

export default {
  fmt: {
    ignorePatterns: generatedPaths,
  },
  lint: {
    ignorePatterns: generatedPaths,
  },
};
