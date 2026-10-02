import 'package:flutter/material.dart';
import 'package:ice_gate/sensor_layer/ui_layer/finance_page/widgets/JobWorkTaskPickerSheet.dart';

/// Opens the 2-step task picker (group → detail → timer).
@Deprecated('Use showJobWorkTaskPicker')
Future<void> showJobWorkTimeSheet(
  BuildContext context, {
  required String personId,
  required String jobId,
  required String jobTitle,
  required DateTime day,
  required Color accent,
}) {
  return showJobWorkTaskPicker(
    context,
    personId: personId,
    jobId: jobId,
    jobTitle: jobTitle,
    day: day,
    accent: accent,
  );
}
