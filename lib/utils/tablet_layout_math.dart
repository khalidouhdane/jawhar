class TabletLayoutMath {
  /// Maps a 1-604 page number to a 1-302 spread index.
  ///
  /// Page 1 and 2 map to Spread 1.
  /// Page 3 and 4 map to Spread 2.
  /// Page 603 and 604 map to Spread 302.
  static int pageToSpread(int page) {
    if (page < 1) return 1;
    if (page > 604) return 302;
    return (page + 1) ~/ 2;
  }

  /// Maps a 1-302 spread index to its Right page number (always Odd).
  static int spreadToRightPage(int spread) {
    if (spread < 1) return 1;
    if (spread > 302) return 603;
    return 2 * spread - 1;
  }

  /// Maps a 1-302 spread index to its Left page number (always Even).
  static int spreadToLeftPage(int spread) {
    if (spread < 1) return 2;
    if (spread > 302) return 604;
    return 2 * spread;
  }
}
