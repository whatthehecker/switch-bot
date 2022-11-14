enum JoyconButton {
  a('A'),
  b('B'),
  x('X'),
  y('Y'),
  plus('Plus'),
  minus('Minus'),
  capture('Capture'),
  home('Home'),
  l('L'),
  r('R'),
  zl('ZL'),
  zr('ZR'),
  directionUp('Up'),
  directionLeft('Left'),
  directionDown('Down'),
  directionRight('Right');

  final String name;

  const JoyconButton(this.name);
}