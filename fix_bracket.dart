import 'dart:io';

void main() {
  var file = File('lib/ui_layer/home_page/HomePage.dart');
  var lines = file.readAsLinesSync();
  
  var fixes = {
    1255: "            ),",
    1256: "          ),",
    1257: "        ],",
    1258: "      ],",
    1259: "    );",
    1260: "  }",
  };
  
  for (var entry in fixes.entries) {
      if (entry.key - 1 < lines.length) {
         lines[entry.key - 1] = entry.value; 
      }
  }
  
  file.writeAsStringSync(lines.join('\n'));
}
