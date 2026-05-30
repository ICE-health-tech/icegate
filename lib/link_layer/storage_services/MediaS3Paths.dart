/// S3 object keys and local paths for user media (meals ↔ food alias, etc.).
List<String> mediaS3KeysForRelativePath(String relativePath) {
  final normalized = relativePath.replaceAll('\\', '/').trim();
  if (normalized.isEmpty) return const [];

  final keys = <String>{normalized};
  if (normalized.contains('/meals/')) {
    keys.add(normalized.replaceFirst('/meals/', '/food/'));
  } else if (normalized.contains('/food/')) {
    keys.add(normalized.replaceFirst('/food/', '/meals/'));
  }
  return keys.toList();
}

/// Prefer on-device layout (`meals/`) when mapping from S3.
String canonicalLocalMediaPath(String path) {
  return path.replaceAll('\\', '/').replaceFirst('/food/', '/meals/');
}

/// S3 key for meal images (matches [AIFoodCaloriesService] uploads).
String mealImageS3Key({required String personId, required String fileName}) {
  return '$personId/food/$fileName';
}
