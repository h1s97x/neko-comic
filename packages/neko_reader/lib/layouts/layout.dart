/// Reader layout interface
abstract class ReaderLayoutStrategy {
  bool get isHorizontal;
  bool get isVertical;
  ScrollPhysics get scrollPhysics;
}
