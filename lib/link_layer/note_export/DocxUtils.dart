import 'dart:convert';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:xml/xml.dart';

/// Minimal DOCX <-> plain text helpers.
///
/// - Reading: extracts visible text from `word/document.xml` by concatenating all `<w:t>` nodes.
/// - Writing: generates a tiny DOCX zip with a single paragraph containing the provided text.
///
/// This is intentionally simple to support "edit in Drive -> sync back" workflows where
/// rich formatting is not required.
class DocxUtils {
  static String extractPlainText(Uint8List bytes) {
    final archive = ZipDecoder().decodeBytes(bytes, verify: true);
    final doc = archive.files
        .whereType<ArchiveFile>()
        .firstWhere((f) => f.name == 'word/document.xml',
            orElse: () => throw StateError('Invalid docx: missing document.xml'));

    final xmlString = utf8.decode(doc.content as List<int>);
    final xml = XmlDocument.parse(xmlString);
    final texts = xml
        .findAllElements('t', namespace: '*')
        .map((e) => e.innerText)
        .toList();
    // Word often uses separate runs; join them and normalize line endings.
    return texts.join().replaceAll('\r\n', '\n');
  }

  static Uint8List createDocxBytesFromPlainText(String text) {
    final escaped = const HtmlEscape(HtmlEscapeMode.element).convert(text);
    final documentXml = '''
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:body>
    <w:p>
      <w:r><w:t xml:space="preserve">$escaped</w:t></w:r>
    </w:p>
    <w:sectPr>
      <w:pgSz w:w="12240" w:h="15840"/>
      <w:pgMar w:top="1440" w:right="1440" w:bottom="1440" w:left="1440" w:header="720" w:footer="720" w:gutter="0"/>
    </w:sectPr>
  </w:body>
</w:document>
''';

    const contentTypesXml = '''
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
  <Default Extension="xml" ContentType="application/xml"/>
  <Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>
</Types>
''';

    const relsXml = '''
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>
</Relationships>
''';

    const wordRelsXml = '''
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"/>
''';

    final archive = Archive()
      ..addFile(ArchiveFile('[Content_Types].xml',
          utf8.encode(contentTypesXml).length, utf8.encode(contentTypesXml)))
      ..addFile(ArchiveFile('_rels/.rels', utf8.encode(relsXml).length,
          utf8.encode(relsXml)))
      ..addFile(ArchiveFile('word/document.xml', utf8.encode(documentXml).length,
          utf8.encode(documentXml)))
      ..addFile(ArchiveFile('word/_rels/document.xml.rels',
          utf8.encode(wordRelsXml).length, utf8.encode(wordRelsXml)));

    final zipped = ZipEncoder().encode(archive);
    return Uint8List.fromList(zipped);
  }
}

