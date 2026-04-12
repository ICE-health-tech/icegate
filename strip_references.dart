import 'dart:io';

void main() {
  final file = File('lib/data_layer/DataSources/local_database/database.dart');
  String content = file.readAsStringSync();
  
  // Regex to remove .references(...) completely
  content = content.replaceAll(RegExp(r'\n\s*\.references\([^)]+\)'), '');

  file.writeAsStringSync(content);
  print('Done stripping references.');
}
