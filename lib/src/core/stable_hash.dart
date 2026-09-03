import 'dart:convert';

class StableHash {
  const StableHash._();

  static int string32(String value) {
    var hash = 0x811C9DC5;
    for (final byte in utf8.encode(value)) {
      hash ^= byte;
      hash = (hash * 0x01000193) & 0xFFFFFFFF;
    }
    return hash;
  }

  static int combine32(Iterable<int> values) {
    var hash = 0x811C9DC5;
    for (final value in values) {
      final v = value & 0xFFFFFFFF;
      for (var shift = 0; shift < 32; shift += 8) {
        hash ^= (v >> shift) & 0xFF;
        hash = (hash * 0x01000193) & 0xFFFFFFFF;
      }
    }
    return hash;
  }
}
