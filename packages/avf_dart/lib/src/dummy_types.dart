import 'dart:ffi' as ffi;

// Dummy opaque types to resolve CoreGraphics / CoreImage missing type errors
final class CGColor extends ffi.Opaque {}

final class CGColorSpace extends ffi.Opaque {}

final class CGPath extends ffi.Opaque {}

final class CGContext extends ffi.Opaque {}

final class CIContext extends ffi.Opaque {}

final class CGImage extends ffi.Opaque {}

final class VZAvailability extends ffi.Opaque {}
