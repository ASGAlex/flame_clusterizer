import 'dart:async';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:flame/rendering.dart';
import 'package:flame_spatial_grid/flame_spatial_grid.dart';

class CellStaticLayer extends CellLayer {
  CellStaticLayer(super.cell, {super.name, super.isRenewable}) {
    paint.isAntiAlias = false;
    paint.filterQuality = FilterQuality.none;
  }

  final paint = Paint();
  Picture? layerPicture;
  Image? layerImage;

  bool renderAsImage = false;

  @override
  void render(Canvas canvas) {
    if (optimizeGraphics) {
      if (renderAsImage && layerImage != null) {
        canvas.drawImage(layerImage!, correctionTopLeft.toOffset(), paint);
      } else {
        if (layerPicture != null) {
          canvas.drawPicture(layerPicture!);
        }
      }
    } else {
      for (final c in children) {
        c.renderTree(canvas);
      }
    }
  }

  @override
  FutureOr compileToSingleLayer(Iterable<Component> children) {
    final renderingChildren =
        children.whereType<HasGridSupport>().toList(growable: false);
    if (renderingChildren.isEmpty) {
      return null;
    }

    final cell = currentCell;
    if (cell == null) {
      return null;
    }

    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);
    if (renderAsImage) {
      final decorator = Transform2DDecorator();
      decorator.transform2d.position = correctionTopLeft * -1;
      for (final component in renderingChildren) {
        decorator.applyChain(
          (canvas) {
            component.decorator.applyChain(component.render, canvas);
          },
          canvas,
        );
      }
      final newPicture = recorder.endRecording();
      layerImage?.dispose();
      layerImage = newPicture.toImageSync(
        layerCalculatedSize.width.toInt(),
        layerCalculatedSize.height.toInt(),
      );
      newPicture.dispose();
    } else {
      for (final component in renderingChildren) {
        component.decorator.applyChain(component.render, canvas);
      }
      layerPicture?.dispose();
      layerPicture = recorder.endRecording();
    }
  }

  @override
  void onResume(double dtElapsedWhileSuspended) {
    // isUpdateNeeded = true;
    super.onResume(dtElapsedWhileSuspended);
  }

  @override
  void onRemove() {
    try {
      layerImage?.dispose();
      layerPicture?.dispose();
      // ignore: avoid_catches_without_on_clauses, empty_catches
    } catch (e) {}
    layerImage = null;
    layerPicture = null;
    super.onRemove();
  }
}
