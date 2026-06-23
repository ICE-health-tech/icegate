/// SDLC phases stored on goals via `category`: `sdlc:planning`, etc.
enum SdlcPhase {
  planning,
  design,
  implementation,
  testing,
  deployment,
  maintenance,
}

class SdlcPhaseInfo {
  const SdlcPhaseInfo({
    required this.phase,
    required this.number,
  });

  final SdlcPhase phase;
  final int number;
}

class SdlcPhaseCodec {
  SdlcPhaseCodec._();

  static const prefix = 'sdlc:';

  static const phases = <SdlcPhaseInfo>[
    SdlcPhaseInfo(phase: SdlcPhase.planning, number: 1),
    SdlcPhaseInfo(phase: SdlcPhase.design, number: 2),
    SdlcPhaseInfo(phase: SdlcPhase.implementation, number: 3),
    SdlcPhaseInfo(phase: SdlcPhase.testing, number: 4),
    SdlcPhaseInfo(phase: SdlcPhase.deployment, number: 5),
    SdlcPhaseInfo(phase: SdlcPhase.maintenance, number: 6),
  ];

  static String toCategory(SdlcPhase phase) => '$prefix${phase.name}';

  static SdlcPhase fromCategory(String category) {
    if (!category.startsWith(prefix)) {
      return SdlcPhase.implementation;
    }
    final name = category.substring(prefix.length);
    return SdlcPhase.values.firstWhere(
      (p) => p.name == name,
      orElse: () => SdlcPhase.implementation,
    );
  }

  static SdlcPhaseInfo infoFor(SdlcPhase phase) {
    return phases.firstWhere((p) => p.phase == phase);
  }
}
