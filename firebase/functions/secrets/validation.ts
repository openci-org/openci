export const generatedSecretNames = new Set([
  "OPENCI_GENERATED_ASC_KEY_ID",
  "OPENCI_GENERATED_ASC_ISSUER_ID",
  "OPENCI_GENERATED_P8_BASE64",
  "OPENCI_GENERATED_IOS_CERTIFICATE_PRIVATE_KEY",
]);
export const certificateSecretName = "OPENCI_GENERATED_IOS_CERTIFICATE_PRIVATE_KEY";

export function validSecretName(name: string): boolean {
  return (
    /^[A-Za-z_][A-Za-z0-9_]{0,254}$/.test(name) &&
    (generatedSecretNames.has(name) ||
      !/^(OPENCI_|LOKI_|BASH_ENV$|ENV$|SHELLOPTS$|BASHOPTS$|HOME$|PATH$|FLUTTER_ROOT$)/.test(name))
  );
}

export function validSecretValue(value: string): boolean {
  return (
    Buffer.byteLength(value, "utf8") <= 65536 &&
    !value.includes("\0") &&
    Buffer.from(value, "utf8").toString("utf8") === value
  );
}
