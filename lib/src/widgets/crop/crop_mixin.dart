import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:video_editor/src/controller.dart';
import 'package:video_editor/src/utils/helpers.dart';
import 'package:video_editor/src/models/transform_data.dart';
import 'package:video_editor/src/widgets/crop/crop_grid.dart';
import 'package:video_editor/src/widgets/crop/crop_grid_painter.dart';
import 'package:video_editor/src/widgets/image_viewer.dart';
import 'package:video_editor/src/widgets/transform.dart';
import 'package:video_editor/src/widgets/video_viewer.dart';

mixin CropPreviewMixin<T extends StatefulWidget> on State<T> {
  final ValueNotifier<Rect> rect = ValueNotifier<Rect>(Rect.zero);
  final ValueNotifier<Rect> videoRect = ValueNotifier<Rect>(Rect.zero);
  final ValueNotifier<TransformData> transform =
      ValueNotifier<TransformData>(const TransformData());

  Size viewerSize = Size.zero;
  Size layout = Size.zero;

  /// 是否锁定裁剪区域范围
  var cropAreaLock = true;

  @override
  void dispose() {
    transform.dispose();
    rect.dispose();
    videoRect.dispose();
    super.dispose();
  }

  /// Returns the size of the max crop dimension based on available space and
  /// original video aspect ratio
  Size computeLayout(
    VideoEditorController controller, {
    EdgeInsets margin = EdgeInsets.zero,
    bool shouldFlipped = false,
  }) {
    if (viewerSize == Size.zero) return Size.zero;
    final videoRatio = controller.video.value.aspectRatio;
    final size = Size(viewerSize.width - margin.horizontal,
        viewerSize.height - margin.vertical);
    if (shouldFlipped) {
      return computeSizeWithRatio(videoRatio > 1 ? size.flipped : size,
              getOppositeRatio(videoRatio))
          .flipped;
    }
    return computeSizeWithRatio(size, videoRatio);
  }

  Rect computeVideoRect(
    VideoEditorController controller, {
    EdgeInsets margin = EdgeInsets.zero,
    bool shouldFlipped = false,
  }) {
    final size = Size(viewerSize.width - margin.horizontal,
        viewerSize.height - margin.vertical);
    double containerWidth = size.width;
    double containerHeight = size.height;
    var trueWidth = 0.0;
    var trueHeight = 0.0;
    var left = 0.0;
    var right = 0.0;
    var top = 0.0;
    var bottom = 0.0;
    final aspectRatio = controller.video.value.aspectRatio;
    if (aspectRatio > containerWidth / containerHeight) {
      trueHeight = containerHeight;
      trueWidth = controller.video.value.size.width *
          trueHeight /
          controller.video.value.size.height;

      left = -((containerWidth - trueWidth) * 0.5).abs();
      right = -((containerWidth - trueWidth) * 0.5).abs();
    } else {
      trueWidth = containerWidth > controller.video.value.size.width
          ? containerWidth
          : controller.video.value.size.width;
      trueHeight = controller.video.value.size.height *
          trueWidth /
          controller.video.value.size.width;

      top = -((containerHeight - trueHeight) * 0.5).abs();
      bottom = -((containerHeight - trueHeight) * 0.5).abs();
    }
    return Rect.fromLTWH(left, top, trueWidth, trueHeight);
    // return Rect.fromLTRB(left, top, right, bottom);
    // return computeSizeWithRatio(size, videoRatio);
  }

  void updateRectFromBuild();

  Widget buildView(BuildContext context, TransformData transform);

  /// Returns the [VideoViewer] tranformed with editing view
  /// Paint rect on top of the video area outside of the crop rect
  Widget buildVideoView(
    VideoEditorController controller,
    TransformData transform,
    CropBoundaries boundary, {
    bool showGrid = false,
  }) {
    return Container(
        color: const Color(0xff35394D),
        child: ValueListenableBuilder(
          valueListenable: videoRect,
          builder: (context, Rect value, child) {
            return CropTransformWithAnimation(
              shouldAnimate: layout != Size.zero,
              transform: transform,
              child: Stack(
                children: [
                  Positioned(
                    left: value.left,
                    // right: value.right,
                    width: value.width,
                    height: value.height,
                    top: value.top,
                    // bottom: videoRect.value.bottom,
                    child: VideoViewer(
                      controller: controller,
                    ),
                  ),
                  Positioned.fill(
                    child: buildPaint(
                      controller,
                      boundary: boundary,
                      showGrid: showGrid,
                      showCenterRects:
                          controller.preferredCropAspectRatio == null,
                    ),
                  )
                ],
              ),
            );
          },
        ));
  }

  /// Returns the [ImageViewer] tranformed with editing view
  /// Paint rect on top of the video area outside of the crop rect
  Widget buildImageView(
    VideoEditorController controller,
    Uint8List bytes,
    TransformData transform,
  ) {
    return SizedBox.fromSize(
      size: layout,
      child: CropTransformWithAnimation(
        shouldAnimate: layout != Size.zero,
        transform: transform,
        child: ImageViewer(
          controller: controller,
          bytes: bytes,
          child:
              buildPaint(controller, showGrid: false, showCenterRects: false),
        ),
      ),
    );
  }

  Widget buildPaint(
    VideoEditorController controller, {
    CropBoundaries? boundary,
    bool showGrid = false,
    bool showCenterRects = false,
  }) {
    return ValueListenableBuilder(
      valueListenable: rect,

      /// Build a [Widget] that hides the cropped area and show the crop grid if widget.showGris is true
      builder: (_, Rect value, __) => RepaintBoundary(
        child: CustomPaint(
          size: Size.infinite,
          painter: CropGridPainter(
            value,
            style: controller.cropStyle,
            boundary: boundary,
            showGrid: showGrid,
            showCenterRects: showCenterRects,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (_, constraints) {
      final size = constraints.biggest;
      if (size != viewerSize) {
        viewerSize = constraints.biggest;
        updateRectFromBuild();
      }

      return ValueListenableBuilder(
        valueListenable: transform,
        builder: (_, TransformData transform, __) =>
            buildView(context, transform),
      );
    });
  }
}
