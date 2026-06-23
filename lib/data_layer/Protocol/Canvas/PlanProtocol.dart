enum PlanNodeVariant { standard, highlight, warning, dashed }

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
    this.steps = const [],
  });

  final String id;
  final String title;
  final List<PlanStep> steps;

  PlanColumn copyWith({
    String? id,
    String? title,
    List<PlanStep>? steps,
  }) {
    return PlanColumn(
      id: id ?? this.id,
      title: title ?? this.title,
      steps: steps ?? this.steps,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'steps': steps.map((s) => s.toJson()).toList(),
  };

  factory PlanColumn.fromJson(Map<String, dynamic> json) {
    final rawSteps = json['steps'];
    final steps = rawSteps is List
        ? rawSteps
              .whereType<Map>()
              .map((e) => PlanStep.fromJson(Map<String, dynamic>.from(e)))
              .where((s) => s.id.isNotEmpty)
              .toList()
        : <PlanStep>[];
    return PlanColumn(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      steps: steps,
    );
  }
}

class PlanBoard {
  const PlanBoard({required this.rootLabel, required this.columns});

  final String rootLabel;
  final List<PlanColumn> columns;

  Map<String, dynamic> toJson() => {
    'rootLabel': rootLabel,
    'columns': columns.map((c) => c.toJson()).toList(),
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
    return PlanBoard(
      rootLabel: json['rootLabel'] as String? ?? 'My schedule',
      columns: columns,
    );
  }
}
