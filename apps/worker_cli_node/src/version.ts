declare const __PACKAGE_VERSION__: string | undefined;

export const version =
  typeof __PACKAGE_VERSION__ === "string" && __PACKAGE_VERSION__.length > 0
    ? __PACKAGE_VERSION__
    : "0.0.0";
