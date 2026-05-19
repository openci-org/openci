export default {
  lint: {
    ignorePatterns: ["lib/**", "src/generated/**", "node_modules/**"],
    options: {
      typeAware: true,
      typeCheck: true,
    },
  },
  fmt: {
    ignorePatterns: ["lib/**", "src/generated/**", "node_modules/**"],
  },
};
