enum Breakpoint {
  mobile(0),
  tablet(600),
  desktop(840)
  ;

  const Breakpoint(this.width);

  final double width;

  static Breakpoint fromWidth(double width) {
    if (width >= Breakpoint.desktop.width) return Breakpoint.desktop;
    if (width >= Breakpoint.tablet.width) return Breakpoint.tablet;
    return Breakpoint.mobile;
  }
}
