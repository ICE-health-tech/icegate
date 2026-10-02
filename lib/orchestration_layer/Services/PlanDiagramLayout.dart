import 'dart:math' as math;
import 'dart:ui';

import 'package:ice_gate/data_layer/Protocol/Canvas/PlanProtocol.dart';

/// Measured size of one plan block (software-diagram node).
class PlanDiagramMetrics {
  const PlanDiagramMetrics({required this.width, required this.height});

  final double width;
  final double height;
}

/// Positioned node on the diagram board.
class PlanDiagramNodeLayout {
  const PlanDiagramNodeLayout({
    required this.column,
    required this.x,
    required this.y,
    required this.metrics,
  });

  final PlanColumn column;
  final double x;
  final double y;
  final PlanDiagramMetrics metrics;

  double get width => metrics.width;
  double get height => metrics.height;

  Offset get bottomCenter => Offset(x + width / 2, y + height);
  Offset get topCenter => Offset(x + width / 2, y);
}

/// Connector between two diagram nodes (flow order).
class PlanDiagramEdge {
  const PlanDiagramEdge({required this.from, required this.to});

  final Offset from;
  final Offset to;
}

/// Full board layout — calculated in orchestration, rendered in sensor.
class PlanDiagramBoardLayout {
  const PlanDiagramBoardLayout({
    required this.nodes,
    required this.edges,
    required this.boardWidth,
    required this.boardHeight,
  });

  final List<PlanDiagramNodeLayout> nodes;
  final List<PlanDiagramEdge> edges;
  final double boardWidth;
  final double boardHeight;

  PlanDiagramNodeLayout? nodeById(String id) {
    for (final n in nodes) {
      if (n.column.id == id) return n;
    }
    return null;
  }
}

/// Software-diagram layout calculator (Lucidchart / FlowchartCanvas sizing).
abstract final class PlanDiagramLayout {
  PlanDiagramLayout._();

  static const double grid = 24;
  static const double pad = 48;
  static const double headerBand = 88;
  static const double columnGap = 44;
  static const double minBoardWidth = 1280;
  static const double minBoardHeight = 720;

  static const double _headerH = 36;
  static const double _footerH = 30;
  static const double _stepRowH = 26;
  static const double _emptyRowH = 22;
  static const double _notesLineH = 16;
  static const double _minNodeW = 168;
  static const double _maxNodeW = 208;

  static double snap(double value) => (value / grid).round() * grid;

  /// Measure node size from column content.
  static PlanDiagramMetrics measure(PlanColumn column) {
    final kind = column.kind.normalized;
    if (kind.isNotes) {
      final chars = column.notesBody.trim().length;
      final lines = math.max(2, math.min(6, (chars / 24).ceil() + 1));
      return PlanDiagramMetrics(
        width: _minNodeW,
        height: snap(_headerH + lines * _notesLineH + _footerH + 16),
      );
    }

    final stepCount = column.steps.length;
    final bodyH = stepCount == 0
        ? _emptyRowH
        : stepCount * _stepRowH + math.max(0, stepCount - 1) * 6;

    final titleLen = column.title.length;
    final width = snap(
      (_minNodeW + math.min(40, titleLen * 1.8)).clamp(_minNodeW, _maxNodeW),
    );

    return PlanDiagramMetrics(
      width: width,
      height: snap(_headerH + bodyH + _footerH),
    );
  }

  /// Auto-place block [index] in horizontal swimlane (diagram left → right).
  static ({double x, double y}) autoSlot(
    int index,
    List<PlanColumn> priorVisible,
  ) {
    var x = pad;
    for (var i = 0; i < index && i < priorVisible.length; i++) {
      x += measure(priorVisible[i]).width + columnGap;
    }
    return (x: snap(x), y: snap(headerBand));
  }

  static double clampX(double x, double nodeWidth, double boardWidth) =>
      x.clamp(0, math.max(0, boardWidth - nodeWidth)).toDouble();

  static double clampY(double y, double nodeHeight, double boardHeight) =>
      y.clamp(0, math.max(0, boardHeight - nodeHeight)).toDouble();

  /// Build full layout: positions, sizes, edges, board bounds.
  static PlanDiagramBoardLayout compute({
    required List<PlanColumn> visibleColumns,
    List<PlanLink> links = const [],
    double viewportWidth = 1280,
  }) {
    final nodes = <PlanDiagramNodeLayout>[];
    final placed = <PlanColumn>[];

    for (var i = 0; i < visibleColumns.length; i++) {
      final column = visibleColumns[i];
      final metrics = measure(column);
      final double x;
      final double y;

      if (column.hasPosition) {
        x = column.posX;
        y = column.posY;
      } else {
        final slot = autoSlot(i, placed);
        x = slot.x;
        y = slot.y;
      }

      placed.add(column);
      nodes.add(
        PlanDiagramNodeLayout(column: column, x: x, y: y, metrics: metrics),
      );
    }

    final edges = links.isNotEmpty
        ? _explicitEdges(nodes, links)
        : _flowEdges(nodes);
    final bounds = _boardBounds(nodes, viewportWidth);

    return PlanDiagramBoardLayout(
      nodes: nodes,
      edges: edges,
      boardWidth: bounds.width,
      boardHeight: bounds.height,
    );
  }

  static List<PlanDiagramEdge> _explicitEdges(
    List<PlanDiagramNodeLayout> nodes,
    List<PlanLink> links,
  ) {
    final byId = {for (final n in nodes) n.column.id: n};
    final edges = <PlanDiagramEdge>[];
    for (final link in links) {
      final from = byId[link.fromColumnId];
      final to = byId[link.toColumnId];
      if (from == null || to == null) continue;
      edges.add(
        PlanDiagramEdge(from: from.bottomCenter, to: to.topCenter),
      );
    }
    return edges;
  }

  static List<PlanDiagramEdge> _flowEdges(List<PlanDiagramNodeLayout> nodes) {
    if (nodes.length < 2) return const [];

    final sorted = List<PlanDiagramNodeLayout>.from(nodes)
      ..sort((a, b) {
        final dy = a.y.compareTo(b.y);
        if (dy != 0) return dy;
        return a.x.compareTo(b.x);
      });

    final edges = <PlanDiagramEdge>[];
    for (var i = 0; i < sorted.length - 1; i++) {
      edges.add(
        PlanDiagramEdge(
          from: sorted[i].bottomCenter,
          to: sorted[i + 1].topCenter,
        ),
      );
    }
    return edges;
  }

  static Size _boardBounds(
    List<PlanDiagramNodeLayout> nodes,
    double viewportWidth,
  ) {
    var maxRight = math.max(minBoardWidth, viewportWidth);
    var maxBottom = minBoardHeight;

    for (final n in nodes) {
      maxRight = math.max(maxRight, n.x + n.width + pad);
      maxBottom = math.max(maxBottom, n.y + n.height + pad + 80);
    }

    return Size(snap(maxRight), snap(maxBottom));
  }
}
