class SeededRng {
  SeededRng(int seed)
      : _state = (seed & 0xFFFFFFFF) == 0
            ? 0x6D2B79F5
            : seed & 0xFFFFFFFF;

  int _state;

  int nextUint32() {
    var x = _state;
    x ^= (x << 13) & 0xFFFFFFFF;
    x ^= x >> 17;
    x ^= (x << 5) & 0xFFFFFFFF;
    _state = x & 0xFFFFFFFF;
    return _state;
  }

  double nextDouble() => nextUint32() / 4294967296.0;
}
