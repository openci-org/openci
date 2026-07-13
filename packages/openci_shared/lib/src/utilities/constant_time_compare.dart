/// Performs a constant-time comparison of two lists of integers (e.g., cryptographic signatures)
/// to prevent timing attacks.
bool constantTimeCompare(List<int> a, List<int> b) {
  if (a.length != b.length) {
    return false;
  }

  var result = 0;
  for (var i = 0; i < a.length; i++) {
    result |= a[i] ^ b[i];
  }
  return result == 0;
}

/// Performs a constant-time comparison of two strings (e.g., API keys)
/// to prevent timing attacks.
bool constantTimeCompareString(String a, String b) {
  if (a.length != b.length) {
    return false;
  }
  var result = 0;
  for (var i = 0; i < a.length; i++) {
    result |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
  }
  return result == 0;
}
