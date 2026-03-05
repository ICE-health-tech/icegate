class AiAnalysisProtocol {
  final String analysisID;
  final String? personID;
  final String title;
  final String? summary;
  final String detailedAnalysis;
  final String status;
  final bool? isFeatured;
  final DateTime? publishedAt;
  final String? category;
  final String? aiModel;
  final String? promptContext;
  final double? sentimentScore;

  AiAnalysisProtocol({
    required this.analysisID,
    this.personID,
    required this.title,
    this.summary,
    required this.detailedAnalysis,
    this.status = 'draft',
    this.isFeatured = false,
    this.publishedAt,
    this.category,
    this.aiModel,
    this.promptContext,
    this.sentimentScore,
  });
}
