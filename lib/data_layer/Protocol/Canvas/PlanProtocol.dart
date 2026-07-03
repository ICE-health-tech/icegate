enum PlanNodeVariant { standard, highlight, warning, dashed }

/// Block type on the plan page — each [PlanColumn] is one visual block.
enum PlanColumnKind {
  /// Legacy persisted value — normalized to [schedule] on load.
  steps,
  notes,
  schedule,
  goals,
}

extension PlanColumnKindX on PlanColumnKind {
  bool get isNotes => this == PlanColumnKind.notes;

  bool get holdsSteps =>
      this == PlanColumnKind.schedule ||
      this == PlanColumnKind.steps ||
      this == PlanColumnKind.goals;

  PlanColumnKind get normalized =>
      this == PlanColumnKind.steps ? PlanColumnKind.schedule : this;
}

class PlanStep {
  const PlanStep({
    required this.id,
    required this.title,
    this.subtitle,
    this.variant = PlanNodeVariant.standard,
    this.connectorLabel,
    this.route,
  });

  final String id;
  final String title;
  final String? subtitle;
  final PlanNodeVariant variant;
  final String? connectorLabel;
  final String? route;

  PlanStep copyWith({
    String? id,
    String? title,
    String? subtitle,
    PlanNodeVariant? variant,
    String? connectorLabel,
    String? route,
    bool clearSubtitle = false,
    bool clearConnectorLabel = false,
    bool clearRoute = false,
  }) {
    return PlanStep(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: clearSubtitle ? null : (subtitle ?? this.subtitle),
      variant: variant ?? this.variant,
      connectorLabel: clearConnectorLabel
          ? null
          : (connectorLabel ?? this.connectorLabel),
      route: clearRoute ? null : (route ?? this.route),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    if (subtitle != null) 'subtitle': subtitle,
    'variant': variant.name,
    if (connectorLabel != null) 'connectorLabel': connectorLabel,
    if (route != null) 'route': route,
  };

  static PlanNodeVariant _variantFrom(String? raw) {
    return PlanNodeVariant.values.firstWhere(
      (v) => v.name == raw,
      orElse: () => PlanNodeVariant.standard,
    );
  }

  factory PlanStep.fromJson(Map<String, dynamic> json) {
    return PlanStep(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      subtitle: json['subtitle'] as String?,
      variant: _variantFrom(json['variant'] as String?),
      connectorLabel: json['connectorLabel'] as String?,
      route: json['route'] as String?,
    );
  }
}

class PlanColumn {
  const PlanColumn({
    required this.id,
    required this.title,
    this.kind = PlanColumnKind.schedule,
    this.steps = const [],
    this.notesBody = '',
    this.tags = const [],
    this.hidden = false,
    this.posX = -1,
    this.posY = -1,
  });

  final String id;
  final String title;
  final PlanColumnKind kind;
  final List<PlanStep> steps;
  final String notesBody;
  final List<String> tags;
  final bool hidden;
  /// Canvas X; `-1` means auto-place on load.
  final double posX;
  /// Canvas Y; `-1` means auto-place on load.
  final double posY;

  bool get hasPosition => posX >= 0 && posY >= 0;

  PlanColumn copyWith({
    String? id,
    String? title,
    PlanColumnKind? kind,
    List<PlanStep>? steps,
    String? notesBody,
    List<String>? tags,
    bool? hidden,
    double? posX,
    double? posY,
  }) {
    return PlanColumn(
      id: id ?? this.id,
      title: title ?? this.title,
      kind: kind ?? this.kind,
      steps: steps ?? this.steps,
      notesBody: notesBody ?? this.notesBody,
      tags: tags ?? this.tags,
      hidden: hidden ?? this.hidden,
      posX: posX ?? this.posX,
      posY: posY ?? this.posY,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'kind': kind.normalized.name,
    if (steps.isNotEmpty) 'steps': steps.map((s) => s.toJson()).toList(),
    if (notesBody.isNotEmpty) 'notesBody': notesBody,
    if (tags.isNotEmpty) 'tags': tags,
    if (hidden) 'hidden': true,
    if (hasPosition) 'posX': posX,
    if (hasPosition) 'posY': posY,
  };

  static PlanColumnKind _kindFrom(String? raw) {
    final kind = PlanColumnKind.values.firstWhere(
      (k) => k.name == raw,
      orElse: () => PlanColumnKind.schedule,
    );
    return kind.normalized;
  }

  factory PlanColumn.fromJson(Map<String, dynamic> json) {
    final rawSteps = json['steps'];
    final steps = rawSteps is List
        ? rawSteps
              .whereType<Map>()
              .map((e) => PlanStep.fromJson(Map<String, dynamic>.from(e)))
              .where((s) => s.id.isNotEmpty)
              .toList()
        : <PlanStep>[];
    final rawTags = json['tags'];
    final tags = rawTags is List
        ? rawTags.map((e) => e.toString()).where((t) => t.isNotEmpty).toList()
        : <String>[];
    return PlanColumn(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      kind: _kindFrom(json['kind'] as String?),
      steps: steps,
      notesBody: json['notesBody'] as String? ?? '',
      tags: tags,
      hidden: json['hidden'] as bool? ?? false,
      posX: (json['posX'] as num?)?.toDouble() ?? -1,
      posY: (json['posY'] as num?)?.toDouble() ?? -1,
    );
  }
}

/// Directed link between two plan blocks (software-flow connector).
class PlanLink {
  const PlanLink({
    required this.id,
    required this.fromColumnId,
    required this.toColumnId,
  });

  final String id;
  final String fromColumnId;
  final String toColumnId;

  Map<String, dynamic> toJson() => {
    'id': id,
    'from': fromColumnId,
    'to': toColumnId,
  };

  factory PlanLink.fromJson(Map<String, dynamic> json) {
    return PlanLink(
      id: json['id'] as String? ?? '',
      fromColumnId: json['from'] as String? ?? '',
      toColumnId: json['to'] as String? ?? '',
    );
  }
}

class PlanBoard {
  const PlanBoard({
    required this.rootLabel,
    required this.columns,
    this.focusNotes = '',
    this.focusTags = const [],
    this.links = const [],
  });

  final String rootLabel;
  final List<PlanColumn> columns;
  final String focusNotes;
  final List<String> focusTags;
  final List<PlanLink> links;

  Map<String, dynamic> toJson() => {
    'rootLabel': rootLabel,
    'columns': columns.map((c) => c.toJson()).toList(),
    if (focusNotes.isNotEmpty) 'focusNotes': focusNotes,
    if (focusTags.isNotEmpty) 'focusTags': focusTags,
    if (links.isNotEmpty) 'links': links.map((l) => l.toJson()).toList(),
  };

  factory PlanBoard.fromJson(Map<String, dynamic> json) {
    final rawCols = json['columns'];
    final columns = rawCols is List
        ? rawCols
              .whereType<Map>()
              .map((e) => PlanColumn.fromJson(Map<String, dynamic>.from(e)))
              .where((c) => c.id.isNotEmpty)
              .toList()
        : <PlanColumn>[];
    final rawTags = json['focusTags'];
    final focusTags = rawTags is List
        ? rawTags.map((e) => e.toString()).where((t) => t.isNotEmpty).toList()
        : <String>[];
    final rawLinks = json['links'];
    final links = rawLinks is List
        ? rawLinks
              .whereType<Map>()
              .map((e) => PlanLink.fromJson(Map<String, dynamic>.from(e)))
              .where((l) =>
                  l.id.isNotEmpty &&
                  l.fromColumnId.isNotEmpty &&
                  l.toColumnId.isNotEmpty)
              .toList()
        : <PlanLink>[];
    return PlanBoard(
      rootLabel: json['rootLabel'] as String? ?? 'My schedule',
      columns: columns,
      focusNotes: json['focusNotes'] as String? ?? '',
      focusTags: focusTags,
      links: links,
    );
  }
}
