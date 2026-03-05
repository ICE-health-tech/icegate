import 'dart:async';
import 'package:flutter/material.dart';
import 'package:signals/signals.dart';
import 'package:ice_shield/data_layer/DataSources/local_database/Database.dart';
import 'package:ice_shield/data_layer/Protocol/User/ContentProtocols.dart';

class ContentBlock {
  final analyses = listSignal<AiAnalysisProtocol>([]);

  StreamSubscription? _analysisSubscription;

  void updateAnalyses(List<AiAnalysisProtocol> data) => analyses.value = data;

  void init(AiAnalysisDAO dao, String personID) {
    if (personID.isEmpty) {
      debugPrint("ContentBlock: Skipping init, personID is empty.");
      return;
    }
    _analysisSubscription?.cancel();
    _analysisSubscription = dao.watchAnalyses(personID).listen((data) {
      updateAnalyses(
        data
            .map(
              (e) => AiAnalysisProtocol(
                analysisID: e.id,
                personID: e.personID,
                title: e.title,
                summary: e.summary,
                detailedAnalysis: e.detailedAnalysis,
                status: e.status,
                isFeatured: e.isFeatured,
                publishedAt: e.publishedAt,
                category: e.category,
                aiModel: e.aiModel,
                promptContext: e.promptContext,
                sentimentScore: e.sentimentScore,
              ),
            )
            .toList(),
      );
    });
  }

  void dispose() {
    _analysisSubscription?.cancel();
  }
}
