// automatically generated by the FlatBuffers compiler, do not modify
// ignore_for_file: unused_import, unused_field, unused_element, unused_local_variable

library optimizer;

import 'dart:typed_data' show Uint8List;

import 'package:flame_spatial_grid/src/collisions/optimizer/isolate/flat_buffers/flat_buffers_optimizer.dart';
import 'package:flat_buffers/flat_buffers.dart' as fb;

class OptimizedCollisions {
  OptimizedCollisions._(this._bc, this._bcOffset);
  factory OptimizedCollisions(List<int> bytes) {
    final rootRef = fb.BufferContext.fromBytes(bytes);
    return reader.read(rootRef, 0);
  }

  static const fb.Reader<OptimizedCollisions> reader =
      _OptimizedCollisionsReader();

  final fb.BufferContext _bc;
  final int _bcOffset;

  List<int>? get indicies => const fb.ListReader<int>(fb.Int32Reader())
      .vTableGetNullable(_bc, _bcOffset, 4);
  Rect? get optimizedBoundingRect =>
      Rect.reader.vTableGetNullable(_bc, _bcOffset, 6);

  @override
  String toString() {
    return 'OptimizedCollisions{indicies: $indicies, optimizedBoundingRect: $optimizedBoundingRect}';
  }

  OptimizedCollisionsT unpack() => OptimizedCollisionsT(
      indicies: const fb.ListReader<int>(fb.Int32Reader(), lazy: false)
          .vTableGetNullable(_bc, _bcOffset, 4),
      optimizedBoundingRect: optimizedBoundingRect?.unpack());

  static int pack(fb.Builder fbBuilder, OptimizedCollisionsT? object) {
    if (object == null) return 0;
    return object.pack(fbBuilder);
  }
}

class OptimizedCollisionsT implements fb.Packable {
  List<int>? indicies;
  RectT? optimizedBoundingRect;

  OptimizedCollisionsT({this.indicies, this.optimizedBoundingRect});

  @override
  int pack(fb.Builder fbBuilder) {
    final int? indiciesOffset =
        indicies == null ? null : fbBuilder.writeListInt32(indicies!);
    fbBuilder.startTable(2);
    fbBuilder.addOffset(0, indiciesOffset);
    if (optimizedBoundingRect != null) {
      fbBuilder.addStruct(1, optimizedBoundingRect!.pack(fbBuilder));
    }
    return fbBuilder.endTable();
  }

  @override
  String toString() {
    return 'OptimizedCollisionsT{indicies: $indicies, optimizedBoundingRect: $optimizedBoundingRect}';
  }
}

class _OptimizedCollisionsReader extends fb.TableReader<OptimizedCollisions> {
  const _OptimizedCollisionsReader();

  @override
  OptimizedCollisions createObject(fb.BufferContext bc, int offset) =>
      OptimizedCollisions._(bc, offset);
}

class OptimizedCollisionsBuilder {
  OptimizedCollisionsBuilder(this.fbBuilder);

  final fb.Builder fbBuilder;

  void begin() {
    fbBuilder.startTable(2);
  }

  int addIndiciesOffset(int? offset) {
    fbBuilder.addOffset(0, offset);
    return fbBuilder.offset;
  }

  int addOptimizedBoundingRect(int offset) {
    fbBuilder.addStruct(1, offset);
    return fbBuilder.offset;
  }

  int finish() {
    return fbBuilder.endTable();
  }
}

class OptimizedCollisionsObjectBuilder extends fb.ObjectBuilder {
  final List<int>? _indicies;
  final RectObjectBuilder? _optimizedBoundingRect;

  OptimizedCollisionsObjectBuilder({
    List<int>? indicies,
    RectObjectBuilder? optimizedBoundingRect,
  })  : _indicies = indicies,
        _optimizedBoundingRect = optimizedBoundingRect;

  /// Finish building, and store into the [fbBuilder].
  @override
  int finish(fb.Builder fbBuilder) {
    final int? indiciesOffset =
        _indicies == null ? null : fbBuilder.writeListInt32(_indicies!);
    fbBuilder.startTable(2);
    fbBuilder.addOffset(0, indiciesOffset);
    if (_optimizedBoundingRect != null) {
      fbBuilder.addStruct(1, _optimizedBoundingRect!.finish(fbBuilder));
    }
    return fbBuilder.endTable();
  }

  /// Convenience method to serialize to byte list.
  @override
  Uint8List toBytes([String? fileIdentifier]) {
    final fbBuilder = fb.Builder(deduplicateTables: false);
    fbBuilder.finish(finish(fbBuilder), fileIdentifier);
    return fbBuilder.buffer;
  }
}
