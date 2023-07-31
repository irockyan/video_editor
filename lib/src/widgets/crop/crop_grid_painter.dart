import 'package:flutter/material.dart';
import 'package:video_editor/src/models/crop_style.dart';
import 'package:video_editor/src/widgets/crop/crop_grid.dart';

class CropGridPainter extends CustomPainter {
  const CropGridPainter(
    this.rect, {
    required this.style,
    this.boundary,
    this.radius = 0,
    this.showGrid = false,
    this.showCenterRects = true,
  });

  final Rect rect;
  final CropBoundaries? boundary;
  final CropGridStyle style;
  final double radius;
  final bool showGrid, showCenterRects;

  @override
  void paint(Canvas canvas, Size size) {
    _drawBackground(canvas, size);
    if (showGrid) {
      _drawGrid(canvas, size);
      _drawBoundaries(canvas, size);
    }
  }

  void _drawBackground(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = showGrid ? style.croppingBackground : style.background;

    // when scaling, the positions might not be exactly accurates
    // so add an extra margin to be sure to overlay all video
    final margin = showGrid ? 0.0 : 1.0;

    // extract [rect] area from the canvas
    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()
          ..addRect(Rect.fromLTWH(-margin, -margin, size.width + margin * 2,
              size.height + margin * 2)),
        Path()
          ..addRRect(RRect.fromRectAndRadius(rect, Radius.circular(radius)))
          ..close(),
      ),
      paint,
    );
  }

  void _drawGrid(Canvas canvas, Size size) {
    final int gridSize = style.gridSize;
    final Paint paint = Paint()
      ..strokeWidth = style.gridLineWidth
      ..color = style.gridLineColor;

    for (int i = 0; i <= gridSize; i++) {
      double rowDy = rect.topLeft.dy + (rect.height / gridSize) * i;
      double columnDx = rect.topLeft.dx + (rect.width / gridSize) * i;
      if (i == 0 || i == gridSize) {
        paint.color = style.gridLineColor;
        canvas.drawLine(
          Offset(columnDx, rect.topLeft.dy),
          Offset(columnDx, rect.bottomLeft.dy),
          paint,
        );
        canvas.drawLine(
          Offset(rect.topLeft.dx, rowDy),
          Offset(rect.topRight.dx, rowDy),
          paint,
        );
      } else {
        paint.color = Colors.white.withOpacity(0.5);
        canvas.drawLine(
          Offset(columnDx, rect.topLeft.dy),
          Offset(columnDx, rect.bottomLeft.dy),
          paint,
        );
        drawDashedLine(canvas, paint, Offset(columnDx, rect.topLeft.dy),
            Offset(columnDx, rect.bottomLeft.dy), 5, 5);
        canvas.drawLine(
          Offset(rect.topLeft.dx, rowDy),
          Offset(rect.topRight.dx, rowDy),
          paint,
        );
      }
    }
  }

  void drawDashedLine(Canvas canvas1, Paint paint, Offset start, Offset end,
      double dashWidth, double dashSpace) {
    final path = Path();
    path.moveTo(start.dx, end.dy);
    path.lineTo(end.dx, end.dy);

    // final distance = end.dx - start.dx;
    // final dashCount = (distance / (dashWidth + dashSpace)).floor();

    // final dxStep = (end.dx - start.dx) / dashCount;
    // final dyStep = (end.dy - start.dy) / dashCount;

    // for (var i = 0; i < dashCount; ++i) {
    //   final from = Offset(start.dx + i * dxStep, start.dy + i * dyStep);
    //   final to =
    //       Offset(start.dx + (i + 1) * dxStep, start.dy + (i + 1) * dyStep);
    //   path.lineTo(from.dx, from.dy);
    //   path.moveTo(to.dx, to.dy);
    // }

    canvas1.drawPath(path, paint);
  }

  Paint getPaintFromBoundary(CropBoundaries offset) {
    return Paint()
      ..color = (boundary == CropBoundaries.inside || offset == boundary)
          ? style.selectedBoundariesColor
          : style.boundariesColor;
  }

  void _drawBoundaries(Canvas canvas, Size size) {
    final double width = style.boundariesWidth;
    final double length = style.boundariesLength;

    //----//
    //EDGE//
    //----//
    // TOP LEFT |-
    final topLeft = rect.topLeft.translate(-width, -width);
    canvas.drawRect(
      Rect.fromPoints(
        topLeft,
        topLeft + Offset(width, length),
      ),
      getPaintFromBoundary(CropBoundaries.topLeft),
    );
    canvas.drawRect(
      Rect.fromPoints(
        topLeft,
        topLeft + Offset(length, width),
      ),
      getPaintFromBoundary(CropBoundaries.topLeft),
    );

    // TOP RIGHT -|
    final topRight = rect.topRight.translate(width, -width);
    canvas.drawRect(
      Rect.fromPoints(
        topRight - Offset(length, 0.0),
        topRight + Offset(0.0, width),
      ),
      getPaintFromBoundary(CropBoundaries.topRight),
    );
    canvas.drawRect(
      Rect.fromPoints(
        topRight,
        topRight - Offset(width, -length),
      ),
      getPaintFromBoundary(CropBoundaries.topRight),
    );

    // BOTTOM RIGHT _|
    final bottomRight = rect.bottomRight.translate(width, width);

    canvas.drawRect(
      Rect.fromPoints(
        bottomRight - Offset(width, length),
        bottomRight,
      ),
      getPaintFromBoundary(CropBoundaries.bottomRight),
    );
    canvas.drawRect(
      Rect.fromPoints(
        bottomRight,
        bottomRight - Offset(length, width),
      ),
      getPaintFromBoundary(CropBoundaries.bottomRight),
    );

    // BOTTOM LEFT |_
    final bottomLeft = rect.bottomLeft.translate(-width, width);

    canvas.drawRect(
      Rect.fromPoints(
        bottomLeft - Offset(-width, length),
        bottomLeft,
      ),
      getPaintFromBoundary(CropBoundaries.bottomLeft),
    );
    canvas.drawRect(
      Rect.fromPoints(
        bottomLeft,
        bottomLeft + Offset(length, -width),
      ),
      getPaintFromBoundary(CropBoundaries.bottomLeft),
    );

    //------//
    //CENTER//
    //------//
    if (showCenterRects) {
      //TOPCENTER
      canvas.drawRect(
        Rect.fromPoints(
          rect.topCenter + Offset(-length / 2, 0.0),
          rect.topCenter + Offset(length / 2, width),
        ),
        getPaintFromBoundary(CropBoundaries.topCenter),
      );

      //BOTTOMCENTER
      canvas.drawRect(
        Rect.fromPoints(
          rect.bottomCenter + Offset(-length / 2, 0.0),
          rect.bottomCenter + Offset(length / 2, -width),
        ),
        getPaintFromBoundary(CropBoundaries.bottomCenter),
      );

      //CENTERLEFT
      canvas.drawRect(
        Rect.fromPoints(
          rect.centerLeft + Offset(0.0, -length / 2),
          rect.centerLeft + Offset(width, length / 2),
        ),
        getPaintFromBoundary(CropBoundaries.centerLeft),
      );

      //CENTERRIGHT
      canvas.drawRect(
        Rect.fromPoints(
          rect.centerRight + Offset(-width, -length / 2),
          rect.centerRight + Offset(0.0, length / 2),
        ),
        getPaintFromBoundary(CropBoundaries.centerRight),
      );
    }
  }

  @override
  bool shouldRepaint(CropGridPainter oldDelegate) =>
      oldDelegate.rect != rect ||
      oldDelegate.style != style ||
      oldDelegate.boundary != boundary ||
      oldDelegate.radius != radius ||
      oldDelegate.showCenterRects != showCenterRects ||
      oldDelegate.showGrid != showGrid;

  @override
  bool shouldRebuildSemantics(CropGridPainter oldDelegate) => false;
}
