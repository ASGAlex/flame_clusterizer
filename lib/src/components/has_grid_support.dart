import 'dart:async';
import 'dart:collection';
import 'dart:math';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:flame_spatial_grid/flame_spatial_grid.dart';
import 'package:flutter/foundation.dart';
import 'package:meta/meta.dart';

/// Core mixin of spatial grid framework.
/// This mixin should have EVERY game component, working with spatial grid.
/// Components without this mixin will be hidden from collision detection
/// system.
///
/// The one thing you should do for you game component is to set initial
/// [currentCell]. If [currentCell] is not specified, system try to locate it by
/// searching corresponding cell for component's [position], but it is not cheap
/// operation and you should avoid it while can.
///
/// If component is outside of cells with state [CellState.active], it means
/// that it is outside of viewport and it will be hidden.
/// If component is outside of [SpatialGrid.unloadRadius], it will be suspended.
/// That means that no [updateTree] function would be called for such
/// components, but [updateSuspendedTree] will be called instead. The component
/// is very far from the player and most probably is not reachable, so main game
/// logic os suspended and you have to implement a lightweight one, if needed.
/// It is ok just to ignore it and do not implement anything.
/// If you need to catch a moment when component become suspended, use
/// [onSuspend] function. If you need to catch a moment when component become
/// active again, use [onResume].
///
/// Each component with grid support have default hitbox: [boundingBox].
/// This is required for component's movement tracking and calculating current
/// cells.
/// [boundingBox] could be enabled for checking collisions. If you need this
/// functionality, change it's "collisionType" from default
/// [CollisionType.inactive] value. Additionally, change
/// "boundingBox.defaultCollisionType" to that value too.
/// See [toggleCollisionOnSuspendChange] to discover, why.
///
/// [boundingBox] always has calculated size to include component itself and
/// all component's child components. So if you have an hitbox outside from
/// component, keep in mind that [boundingBox] will contain it too!
///
mixin HasGridSupport on PositionComponent {
  @internal
  static final componentHitboxes = HashMap<ShapeHitbox, HasGridSupport>();

  @internal
  static final cachedCenters = HashMap<ShapeHitbox, Vector2>();

  @internal
  static final defaultCollisionType = HashMap<ShapeHitbox, CollisionType>();

  @internal
  final suspendNotifier = ValueNotifier<bool>(false);

  /// If component's cell state become [CellState.inactive], the component
  /// become inactive too. It also become disabled in collision detection
  /// system, so [boundingBox.collisionType] become [CollisionType.inactive].
  /// After component is restored from suspension, we need to restore it's
  /// previous "collisionType" value. So by default we do this restoration.
  /// You might want to change [toggleCollisionOnSuspendChange] to false if
  /// you know that [boundingBox] should always have state
  /// [CollisionType.inactive] and want to optimise you code a bit.
  /// But you also can just to ignore this parameter.
  bool toggleCollisionOnSuspendChange = true;

  /// If component stay at cell with state [CellState.suspended]
  bool get isSuspended => suspendNotifier.value;

  set isSuspended(bool suspend) {
    if (suspendNotifier.value != suspend) {
      if (suspend) {
        onSuspend();
      } else {
        onResume(dtElapsedWhileSuspended);
        dtElapsedWhileSuspended = 0;
      }
    }
    suspendNotifier.value = suspend;
  }

  Cell? _currentCell;

  /// Component's current cell. If null - something definitely went wrong!
  Cell? get currentCell => _currentCell;

  set currentCell(Cell? value) {
    final previousCell = _currentCell;
    final hitboxes = children.whereType<ShapeHitbox>();

    _currentCell = value;
    value?.components.add(this);

    if (hitboxes.isNotEmpty) {
      final broadphase = spatialGrid.game.collisionDetection.broadphase;
      for (final hitbox in hitboxes) {
        if (previousCell != null) {
          previousCell.components.remove(this);
        }
        broadphase.updateHitboxIndexes(hitbox, previousCell);
      }
    }
  }

  SpatialGrid? _spatialGrid;

  SpatialGrid get spatialGrid => _spatialGrid!;

  @internal
  void setSpatialGrid(SpatialGrid spatialGrid) {
    _spatialGrid ??= spatialGrid;
  }

  /// If this component is that component which all spatial grid system keeps
  /// in center of grid?
  bool get isTracked => this == currentCell?.spatialGrid.trackedComponent;

  /// Bounding box for component and it's additional hitboxes. By default it is
  /// disabled from collision detection system, but you can change it's
  /// collisionType and defaultCollisionType values.
  late final boundingBox = BoundingHitbox(
    position: Vector2.zero(),
    size: Vector2.zero(),
    parentWithGridSupport: this,
  )..collisionType = CollisionType.inactive;

  @internal
  double dtElapsedWhileSuspended = 0;

  double _minDistanceQuad = 0;

  double get minDistanceQuad => _minDistanceQuad;

  double get minDistance => sqrt(_minDistanceQuad);

  double _minDistanceX = 0;

  double get minDistanceX => _minDistanceX;
  double _minDistanceY = 0;

  double get minDistanceY => _minDistanceY;

  bool _outOfCellBounds = false;

  /// If component fully lays inside cell bounds or overlaps other cells?
  bool get isOutOfCellBounds => _outOfCellBounds;

  /// [boundingBox] initialisation provided here. It is absolutely necessary for
  /// keeping framework to work correctly, so please never forgot to call
  /// super.onLoad in yours onLoad functions!
  @override
  @mustCallSuper
  FutureOr<void>? onLoad() {
    boundingBox.size.setFrom(Rect.fromLTWH(0, 0, size.x, size.y).toVector2());
    add(boundingBox);
    boundingBox.transform.addListener(_onBoundingBoxTransform);
    return null;
  }

  @override
  FutureOr<void>? add(Component component) {
    if (component != boundingBox && component is ShapeHitbox) {
      final currentRect = boundingBox.shouldFillParent
          ? Rect.fromLTWH(0, 0, size.x, size.y)
          : boundingBox.toRect();
      final addRect = component.toRect();
      final newRect = currentRect.expandToInclude(addRect);
      boundingBox.position.setFrom(newRect.topLeft.toVector2());
      boundingBox.size.setFrom(newRect.size.toVector2());
    }
    return super.add(component);
  }

  void _onBoundingBoxTransform() {
    _minDistanceQuad =
        (pow(boundingBox.width / 2, 2) + pow(boundingBox.height / 2, 2))
            .toDouble();
    _minDistanceX = boundingBox.width / 2;
    _minDistanceY = boundingBox.height / 2;
  }

  @override
  void onRemove() {
    boundingBox.transform.removeListener(_onBoundingBoxTransform);
  }

  @override
  void updateTree(double dt) {
    if (isSuspended) {
      dtElapsedWhileSuspended += dt;
      updateSuspendedTree(dtElapsedWhileSuspended);
    } else {
      super.updateTree(dt);
    }
  }

  /// Called instead of [updateTree] when component is suspended.
  /// [dtElapsedWhileSuspended] accumulates all [dt] values since
  /// component suspension
  void updateSuspendedTree(double dtElapsedWhileSuspended) {}

  /// Called when component state changes to "suspended". You should stop
  /// all undesired component's movements (for example) here
  void onSuspend() {}

  /// Called when component state changes from "suspended" to active.
  /// [dtElapsedWhileSuspended] accumulates all [dt] values since
  /// component suspension. Useful to calculate next animation step as if
  /// the component was never suspended.
  void onResume(double dtElapsedWhileSuspended) {}

  @override
  void renderTree(Canvas canvas) {
    if (currentCell?.state == CellState.active) {
      super.renderTree(canvas);
    }
    if (debugMode) {
      renderDebugMode(canvas);
    }
  }

  /// This is called on every [boundingBox]'s aabb recalculation. If bounding
  /// box was mover or resized - it is necessary to recalculate component's
  /// [currentCell], probably create new one...
  @internal
  void updateTransform() {
    boundingBox.aabbCenter = boundingBox.aabb.center;
    cachedCenters.remove(boundingBox);
    final componentCenter = boundingBox.aabbCenter;
    var current = currentCell;
    current ??= spatialGrid.findExistingCellByPosition(componentCenter) ??
        spatialGrid.createNewCellAtPosition(componentCenter);
    if (current.rect.containsPoint(componentCenter)) {
      if (current != _currentCell) {
        isSuspended = current.state == CellState.suspended;
      }
      _currentCell = current;
    } else {
      Cell? newCell;
      //look close neighbours
      for (final cell in current.neighbours) {
        if (cell.rect.containsPoint(componentCenter)) {
          newCell = cell;
          break;
        }
      }
      //if nothing - search among all cells
      if (newCell == null) {
        for (final cell in spatialGrid.cells.entries) {
          if (cell.value.rect.containsPoint(componentCenter)) {
            newCell = cell.value;
            break;
          }
        }
      }
      //if nothing again - try to locate new cell's position from component's
      //coordinates
      newCell ??= spatialGrid.createNewCellAtPosition(componentCenter);

      currentCell = newCell;
      isSuspended = newCell.state == CellState.suspended;
      if (isTracked) {
        spatialGrid.currentCell = newCell;
      }
    }
    _outOfCellBounds = !boundingBox.isFullyInsideRect(current.rect);
  }

  @override
  void renderDebugMode(Canvas canvas) {
    super.renderDebugMode(canvas);
    debugTextPaint.render(
      canvas,
      '$runtimeType',
      Vector2(0, 0),
    );
  }
}
