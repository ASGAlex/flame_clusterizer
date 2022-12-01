import 'package:cluisterizer_test/clusterizer/cell_builder.dart';
import 'package:flame/components.dart';
import 'package:flame/extensions.dart';

import 'cell.dart';
import 'clusterized_component.dart';

class Clusterizer {
  Clusterizer(
      {required this.blockSize,
      required this.trackedComponent,
      this.cellBuilder,
      int? activeRadius,
      int? unloadRadius}) {
    this.activeRadius = (activeRadius ?? 1);
    this.unloadRadius = (unloadRadius ?? 10);
    final cell = Cell(
        clusterizer: this,
        rect: Rect.fromCenter(
            center: trackedComponent.position.toOffset(),
            width: blockSize.width,
            height: blockSize.height));

    setActiveCell(cell);
    trackedComponent.currentCell = cell;
  }

  @override
  dispose() {
    for (var cell in cells.values) {
      cell.dispose();
    }
    cells.clear();
  }

  final cells = <Rect, Cell>{};
  Cell? _currentCell;
  CellBuilder? cellBuilder;

  final Size blockSize;
  final ClusterizedComponent trackedComponent;

  var activeRadius = 1;
  var unloadRadius = 3;

  void setActiveCell(Cell newActiveCell) {
    _currentCell = newActiveCell;
    for (var cell in cells.values) {
      cell.state = CellState.suspended;
    }

    final cellsToInactivate = _findCellsInRadius(unloadRadius);
    for (var cell in cellsToInactivate) {
      cell.state = CellState.inactive;
    }

    final cellsToActivate = _findCellsInRadius(activeRadius, create: true);
    for (var cell in cellsToActivate) {
      cell.state = CellState.active;
    }
    newActiveCell.state = CellState.active;
  }

  Set<Cell> _findCellsInRadius(int radius, {bool create = false}) {
    final current = _currentCell;
    if (current == null) throw 'current cell cant be null!';

    Set<Cell> cells = {};
    var tmpDirection = current;
    for (var leftCounter = 1; leftCounter <= radius; leftCounter++) {
      if (create) {
        tmpDirection = tmpDirection.left;
      } else {
        final rawLeft = tmpDirection.leftChecked;
        if (rawLeft == null) break;
        tmpDirection = rawLeft;
      }
      cells.add(tmpDirection);

      var topDirection = tmpDirection;
      for (var topCounter = 1; topCounter <= leftCounter; topCounter++) {
        if (create) {
          topDirection = topDirection.top;
        } else {
          final rawTop = topDirection.topChecked;
          if (rawTop == null) break;
          topDirection = rawTop;
        }
        cells.add(topDirection);
      }

      var bottomDirection = tmpDirection;
      for (var bottomCounter = 1;
          bottomCounter <= leftCounter;
          bottomCounter++) {
        if (create) {
          bottomDirection = bottomDirection.bottom;
        } else {
          final rawBottom = bottomDirection.bottomChecked;
          if (rawBottom == null) break;
          bottomDirection = rawBottom;
        }
        cells.add(bottomDirection);
      }
    }

    tmpDirection = current;
    for (var rightCounter = 1; rightCounter <= radius; rightCounter++) {
      if (create) {
        tmpDirection = tmpDirection.right;
      } else {
        final rawRight = tmpDirection.rightChecked;
        if (rawRight == null) break;
        tmpDirection = rawRight;
      }
      cells.add(tmpDirection);

      var topDirection = tmpDirection;
      for (var topCounter = 1; topCounter <= rightCounter; topCounter++) {
        if (create) {
          topDirection = topDirection.top;
        } else {
          final rawTop = topDirection.topChecked;
          if (rawTop == null) break;
          topDirection = rawTop;
        }
        cells.add(topDirection);
      }

      var bottomDirection = tmpDirection;
      for (var bottomCounter = 1;
          bottomCounter <= rightCounter;
          bottomCounter++) {
        if (create) {
          bottomDirection = bottomDirection.bottom;
        } else {
          final rawBottom = bottomDirection.bottomChecked;
          if (rawBottom == null) break;
          bottomDirection = rawBottom;
        }
        cells.add(bottomDirection);
      }
    }

    tmpDirection = current;
    for (var topCounter = 1; topCounter <= radius; topCounter++) {
      if (create) {
        tmpDirection = tmpDirection.top;
      } else {
        final rawTop = tmpDirection.topChecked;
        if (rawTop == null) break;
        tmpDirection = rawTop;
      }
      cells.add(tmpDirection);

      var leftDirection = tmpDirection;
      for (var leftCounter = 1; leftCounter <= topCounter; leftCounter++) {
        if (create) {
          leftDirection = leftDirection.left;
        } else {
          final rawLeft = leftDirection.leftChecked;
          if (rawLeft == null) break;
          leftDirection = rawLeft;
        }
        cells.add(leftDirection);
      }

      var rightDirection = tmpDirection;
      for (var rightCounter = 1; rightCounter <= topCounter; rightCounter++) {
        if (create) {
          rightDirection = rightDirection.right;
        } else {
          final rawRight = rightDirection.rightChecked;
          if (rawRight == null) break;
          rightDirection = rawRight;
        }
        cells.add(rightDirection);
      }
    }

    tmpDirection = current;
    for (var bottomCounter = 1; bottomCounter <= radius; bottomCounter++) {
      if (create) {
        tmpDirection = tmpDirection.bottom;
      } else {
        final rawBottom = tmpDirection.bottomChecked;
        if (rawBottom == null) break;
        tmpDirection = rawBottom;
      }
      cells.add(tmpDirection);

      var leftDirection = tmpDirection;
      for (var leftCounter = 1; leftCounter <= bottomCounter; leftCounter++) {
        if (create) {
          leftDirection = leftDirection.left;
        } else {
          final rawLeft = leftDirection.leftChecked;
          if (rawLeft == null) break;
          leftDirection = rawLeft;
        }
        cells.add(leftDirection);
      }

      var rightDirection = tmpDirection;
      for (var rightCounter = 1;
          rightCounter <= bottomCounter;
          rightCounter++) {
        if (create) {
          rightDirection = rightDirection.right;
        } else {
          final rawRight = rightDirection.rightChecked;
          if (rawRight == null) break;
          rightDirection = rawRight;
        }
        cells.add(rightDirection);
      }
    }
    return cells;
  }

  Cell? findExistingCellByPosition(Vector2 position) {
    final nearest = findNearestCellToPosition(position);
    if (nearest?.rect.containsPoint(position) == true) {
      return nearest;
    }
    return null;
  }

  Cell? findNearestCellToPosition(Vector2 position) {
    double shortestDistance = double.maxFinite;
    Cell? nearestCell;
    for (final cell in cells.entries) {
      final distance = cell.value.center.distanceToSquared(position);
      if (distance < shortestDistance) {
        shortestDistance = distance;
        nearestCell = cell.value;
      }
    }
    return nearestCell;
  }

  Cell? createNewCellAtPosition(Vector2 position) {
    final nearest = findNearestCellToPosition(position);
    if (nearest == null) throw "There are no cells probably?";

    var startPoint = nearest.center;
    final diff = position - startPoint;
    final xSign = diff.x > 0 ? 1 : -1;
    final ySign = diff.y > 0 ? 1 : -1;
    var moveByX = diff.x.abs();
    var moveByY = diff.y.abs();

    while (moveByX >= blockSize.width / 2) {
      moveByX -= blockSize.width;
      if (xSign > 0) {
        startPoint.x += blockSize.width;
      } else {
        startPoint.x -= blockSize.width;
      }
    }
    while (moveByY >= blockSize.height / 2) {
      moveByY -= blockSize.height;
      if (ySign > 0) {
        startPoint.y += blockSize.height;
      } else {
        startPoint.y -= blockSize.height;
      }
    }

    final rect = Rect.fromCenter(
        center: startPoint.toOffset(),
        width: blockSize.width,
        height: blockSize.height);
    if (!rect.containsPoint(position)) {
      print(rect);
      print(position);
      print(startPoint);
      //throw 'Error creating new cell';
    }

    final cell = Cell(clusterizer: this, rect: rect);
    cell.left;
    cell.right;
    cell.top;
    cell.bottom;

    return cell;
  }
}
