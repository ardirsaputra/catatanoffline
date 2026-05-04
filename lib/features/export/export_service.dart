import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';
import '../../shared/models/berkas_model.dart';
import '../../shared/models/bundel_model.dart';
import '../../shared/models/section_model.dart';

/// Exports BerkasModel or BundelModel to .docx and shares via system share sheet.
class ExportService {
  // ── Public API ─────────────────────────────────────────────────────────────

  static Future<void> exportBerkasToDocx(BerkasModel berkas) async {
    final builder = _DocxBuilder();
    builder.addTitle(berkas.title);
    for (final section in berkas.sections) {
      await builder.addSection(section);
    }
    final bytes = builder.build();
    await _saveAndShare(bytes, _sanitize(berkas.title));
  }

  static Future<void> exportBundelToDocx(
    BundelModel bundel,
    List<BerkasModel> berkasInBundle,
  ) async {
    final builder = _DocxBuilder();
    builder.addTitle(bundel.title);
    if (bundel.description.isNotEmpty) {
      builder.addParagraph(bundel.description, style: 'subtitle');
    }
    builder.addPageBreakParagraph();

    for (var i = 0; i < berkasInBundle.length; i++) {
      final berkas = berkasInBundle[i];
      if (i > 0) builder.addPageBreakParagraph();
      builder.addHeading('${berkas.iconName}  ${berkas.title}', level: 1);
      for (final section in berkas.sections) {
        await builder.addSection(section);
      }
    }
    final bytes = builder.build();
    await _saveAndShare(bytes, _sanitize(bundel.title));
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  static Future<void> _saveAndShare(Uint8List bytes, String baseName) async {
    final dir = await getApplicationDocumentsDirectory();
    final exportDir = Directory(p.join(dir.path, 'exports'));
    await exportDir.create(recursive: true);
    final filePath = p.join(exportDir.path, '$baseName.docx');
    await File(filePath).writeAsBytes(bytes);
    await Share.shareXFiles(
      [XFile(filePath, mimeType: 'application/vnd.openxmlformats-officedocument.wordprocessingml.document')],
      subject: baseName,
    );
  }

  static String _sanitize(String name) {
    return name.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_').trim();
  }
}

// ── DOCX Builder ──────────────────────────────────────────────────────────────

class _DocxBuilder {
  final _bodyXml = StringBuffer();
  final _imageEntries = <_ImageEntry>[];
  int _imageCounter = 0;
  int _drawingId = 1;

  // ── Public methods ─────────────────────────────────────────────────────────

  void addTitle(String text) {
    _bodyXml.write(_paragraph(text, styleId: 'Title'));
  }

  void addHeading(String text, {int level = 2}) {
    _bodyXml.write(_paragraph(text, styleId: 'Heading$level'));
  }

  void addParagraph(String text, {String style = 'Normal'}) {
    if (text.isEmpty) return;
    _bodyXml.write(_paragraph(text, styleId: style));
  }

  void addPageBreakParagraph() {
    _bodyXml.write(
      '<w:p><w:r><w:br w:type="page"/></w:r></w:p>',
    );
  }

  Future<void> addSection(SectionModel section) async {
    final type = section.type;
    final data = section.data;

    switch (type) {
      case SectionType.wawancara:
        final question = data['question'] as String? ?? '';
        final answer = data['answer'] as String? ?? '';
        _bodyXml.write(_paragraph('Pertanyaan:', styleId: 'Heading3'));
        _bodyXml.write(_paragraph(question.isEmpty ? '(kosong)' : question));
        _bodyXml.write(_paragraph('Jawaban:', styleId: 'Heading3'));
        _bodyXml.write(_paragraph(answer.isEmpty ? '(kosong)' : answer));
        _bodyXml.write(_spacer());

      case SectionType.esai:
        final question = data['question'] as String? ?? '';
        final answer = data['answer'] as String? ?? '';
        _bodyXml.write(_paragraph('Pertanyaan:', styleId: 'Heading3'));
        _bodyXml.write(_paragraph(question.isEmpty ? '(kosong)' : question));
        _bodyXml.write(_paragraph('Jawaban Esai:', styleId: 'Heading3'));
        _bodyXml.write(_paragraph(answer.isEmpty ? '(belum diisi)' : answer));
        _bodyXml.write(_spacer());

      case SectionType.checklist:
        final title = data['title'] as String? ?? 'Daftar Periksa';
        final items = (data['items'] as List? ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        _bodyXml.write(_paragraph(title, styleId: 'Heading3'));
        for (final item in items) {
          final text = item['text'] as String? ?? '';
          final checked = item['checked'] as bool? ?? false;
          final checkChar = checked ? '☑' : '☐';
          _bodyXml.write(_paragraph('$checkChar  $text'));
        }
        _bodyXml.write(_spacer());

      case SectionType.pilihanGanda:
        final questions = (data['questions'] as List? ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        for (var qi = 0; qi < questions.length; qi++) {
          final q = questions[qi];
          final questionText = q['question'] as String? ?? '';
          final options = (q['options'] as List? ?? []).cast<String>();
          final selectedIndex = q['selectedIndex'] as int?;
          _bodyXml.write(
              _paragraph('${qi + 1}. $questionText', styleId: 'Heading3'));
          for (var oi = 0; oi < options.length; oi++) {
            final bullet = oi == selectedIndex ? '◉' : '○';
            _bodyXml.write(_paragraph('   $bullet  ${options[oi]}'));
          }
        }
        _bodyXml.write(_spacer());

      case SectionType.tandaTangan:
        final label = data['label'] as String? ?? 'Tanda Tangan';
        final signerName = data['signerName'] as String? ?? '';
        final signatureBase64 = data['signatureBase64'] as String?;
        _bodyXml.write(_paragraph(label, styleId: 'Heading3'));
        if (signerName.isNotEmpty) {
          _bodyXml.write(_paragraph('Nama: $signerName'));
        }
        if (signatureBase64 != null && signatureBase64.isNotEmpty) {
          try {
            final imgBytes = base64Decode(signatureBase64);
            final rId = _addImage(imgBytes, 'png');
            _bodyXml.write(_inlineImage(rId, widthEmu: 2286000, heightEmu: 686000));
          } catch (_) {
            _bodyXml.write(_paragraph('[Tanda tangan tersimpan]'));
          }
        } else {
          _bodyXml.write(_signatureLine());
        }
        _bodyXml.write(_spacer());

      case SectionType.gambar:
        final caption = data['caption'] as String? ?? '';
        final imagePath = data['imagePath'] as String?;
        if (imagePath != null && imagePath.isNotEmpty) {
          try {
            final file = File(imagePath);
            if (await file.exists()) {
              final imgBytes = await file.readAsBytes();
              final ext = p.extension(imagePath).replaceFirst('.', '').toLowerCase();
              final rId = _addImage(imgBytes, ext.isEmpty ? 'jpeg' : ext);
              _bodyXml.write(_inlineImage(rId));
              if (caption.isNotEmpty) {
                _bodyXml.write(_paragraph(caption, styleId: 'Caption'));
              }
            } else {
              _bodyXml.write(_paragraph('[Gambar tidak ditemukan: $imagePath]'));
            }
          } catch (_) {
            _bodyXml.write(_paragraph('[Gagal memuat gambar]'));
          }
        } else {
          _bodyXml.write(_paragraph('[Belum ada gambar]'));
          if (caption.isNotEmpty) {
            _bodyXml.write(_paragraph(caption, styleId: 'Caption'));
          }
        }
        _bodyXml.write(_spacer());

      case SectionType.tabel:
        final headers = (data['headers'] as List? ?? []).cast<String>();
        final rows = (data['rows'] as List? ?? [])
            .map((r) => (r as List).cast<String>())
            .toList();
        if (headers.isNotEmpty) {
          _bodyXml.write(_table(headers, rows));
        }
        _bodyXml.write(_spacer());

      case SectionType.teksBebas:
        final deltaJson = data['deltaJson'] as String?;
        final plainText = deltaJson != null ? _deltaToPlainText(deltaJson) : '';
        _bodyXml.write(_paragraph(plainText.isEmpty ? '(kosong)' : plainText));
        _bodyXml.write(_spacer());
    }
  }

  /// Build the final .docx bytes
  Uint8List build() {
    final documentXml = _wrapDocument(_bodyXml.toString());
    final contentTypes = _buildContentTypes();
    final rootRels = _buildRootRels();
    final docRels = _buildDocRels();
    final stylesXml = _buildStyles();
    final settingsXml = _buildSettings();

    final archive = Archive();

    _addToArchive(archive, '[Content_Types].xml', contentTypes);
    _addToArchive(archive, '_rels/.rels', rootRels);
    _addToArchive(archive, 'word/document.xml', documentXml);
    _addToArchive(archive, 'word/_rels/document.xml.rels', docRels);
    _addToArchive(archive, 'word/styles.xml', stylesXml);
    _addToArchive(archive, 'word/settings.xml', settingsXml);

    for (final img in _imageEntries) {
      archive.addFile(ArchiveFile(
        'word/media/${img.filename}',
        img.bytes.length,
        img.bytes,
      ));
    }

    final zipBytes = ZipEncoder().encode(archive);
    return Uint8List.fromList(zipBytes!);
  }

  // ── Private XML helpers ────────────────────────────────────────────────────

  static String _paragraph(String text, {String styleId = 'Normal'}) {
    final escaped = _xe(text);
    return '<w:p>'
        '<w:pPr><w:pStyle w:val="$styleId"/></w:pPr>'
        '<w:r><w:t xml:space="preserve">$escaped</w:t></w:r>'
        '</w:p>';
  }

  static String _spacer() => '<w:p><w:pPr><w:spacing w:after="120"/></w:pPr></w:p>';

  static String _signatureLine() {
    return '<w:p>'
        '<w:r><w:t>___________________________________</w:t></w:r>'
        '</w:p>';
  }

  static String _table(List<String> headers, List<List<String>> rows) {
    final sb = StringBuffer();
    sb.write('<w:tbl>');
    sb.write(
      '<w:tblPr>'
      '<w:tblStyle w:val="TableGrid"/>'
      '<w:tblW w:w="0" w:type="auto"/>'
      '<w:tblBorders>'
      '<w:top w:val="single" w:sz="4"/>'
      '<w:left w:val="single" w:sz="4"/>'
      '<w:bottom w:val="single" w:sz="4"/>'
      '<w:right w:val="single" w:sz="4"/>'
      '<w:insideH w:val="single" w:sz="4"/>'
      '<w:insideV w:val="single" w:sz="4"/>'
      '</w:tblBorders>'
      '</w:tblPr>',
    );

    // Header row
    sb.write('<w:tr>');
    for (final h in headers) {
      sb.write('<w:tc><w:tcPr><w:shd w:val="clear" w:color="auto" w:fill="D0E8F5"/></w:tcPr>'
          '<w:p><w:pPr><w:jc w:val="left"/></w:pPr>'
          '<w:r><w:rPr><w:b/></w:rPr><w:t xml:space="preserve">${_xe(h)}</w:t></w:r>'
          '</w:p></w:tc>');
    }
    sb.write('</w:tr>');

    // Data rows
    for (final row in rows) {
      sb.write('<w:tr>');
      for (var ci = 0; ci < headers.length; ci++) {
        final cell = ci < row.length ? row[ci] : '';
        sb.write('<w:tc><w:p><w:r>'
            '<w:t xml:space="preserve">${_xe(cell)}</w:t>'
            '</w:r></w:p></w:tc>');
      }
      sb.write('</w:tr>');
    }

    sb.write('</w:tbl>');
    return sb.toString();
  }

  String _inlineImage(
    String rId, {
    int widthEmu = 3657600,
    int heightEmu = 2743200,
  }) {
    final id = _drawingId++;
    return '<w:p><w:r><w:drawing>'
        '<wp:inline xmlns:wp="http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing">'
        '<wp:extent cx="$widthEmu" cy="$heightEmu"/>'
        '<wp:docPr id="$id" name="Image$id"/>'
        '<a:graphic xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main">'
        '<a:graphicData uri="http://schemas.openxmlformats.org/drawingml/2006/picture">'
        '<pic:pic xmlns:pic="http://schemas.openxmlformats.org/drawingml/2006/picture">'
        '<pic:nvPicPr>'
        '<pic:cNvPr id="0" name="image$id.png"/>'
        '<pic:cNvPicPr/>'
        '</pic:nvPicPr>'
        '<pic:blipFill>'
        '<a:blip r:embed="$rId" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"/>'
        '<a:stretch><a:fillRect/></a:stretch>'
        '</pic:blipFill>'
        '<pic:spPr>'
        '<a:xfrm><a:off x="0" y="0"/><a:ext cx="$widthEmu" cy="$heightEmu"/></a:xfrm>'
        '<a:prstGeom prst="rect"><a:avLst/></a:prstGeom>'
        '</pic:spPr>'
        '</pic:pic>'
        '</a:graphicData>'
        '</a:graphic>'
        '</wp:inline>'
        '</w:drawing></w:r></w:p>';
  }

  String _addImage(Uint8List bytes, String ext) {
    _imageCounter++;
    final rid = 'rId${_imageCounter + 1}';
    final filename = 'image$_imageCounter.$ext';
    _imageEntries.add(_ImageEntry(
      rId: rid,
      filename: filename,
      bytes: bytes,
      ext: ext,
    ));
    return rid;
  }

  static String _wrapDocument(String body) {
    return '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<w:document '
        'xmlns:wpc="http://schemas.microsoft.com/office/word/2010/wordprocessingCanvas" '
        'xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006" '
        'xmlns:o="urn:schemas-microsoft-com:office:office" '
        'xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships" '
        'xmlns:m="http://schemas.openxmlformats.org/officeDocument/2006/math" '
        'xmlns:v="urn:schemas-microsoft-com:vml" '
        'xmlns:wp14="http://schemas.microsoft.com/office/word/2010/wordprocessingDrawing" '
        'xmlns:wp="http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing" '
        'xmlns:w10="urn:schemas-microsoft-com:office:word" '
        'xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main" '
        'xmlns:w14="http://schemas.microsoft.com/office/word/2010/wordml" '
        'xmlns:wpg="http://schemas.microsoft.com/office/word/2010/wordprocessingGroup" '
        'xmlns:wpi="http://schemas.microsoft.com/office/word/2010/wordprocessingInk" '
        'xmlns:wne="http://schemas.microsoft.com/office/word/2006/wordml" '
        'xmlns:wps="http://schemas.microsoft.com/office/word/2010/wordprocessingShape" '
        'mc:Ignorable="w14 wp14">'
        '<w:body>$body<w:sectPr/></w:body>'
        '</w:document>';
  }

  String _buildContentTypes() {
    final sb = StringBuffer();
    sb.write('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>');
    sb.write('<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">');
    sb.write('<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>');
    sb.write('<Default Extension="xml" ContentType="application/xml"/>');
    sb.write('<Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>');
    sb.write('<Override PartName="/word/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.styles+xml"/>');
    sb.write('<Override PartName="/word/settings.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.settings+xml"/>');

    final seenExts = <String>{};
    for (final img in _imageEntries) {
      if (seenExts.add(img.ext)) {
        final mime = img.ext == 'png' ? 'image/png' : 'image/jpeg';
        sb.write('<Default Extension="${img.ext}" ContentType="$mime"/>');
      }
    }
    sb.write('</Types>');
    return sb.toString();
  }

  static String _buildRootRels() {
    return '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
        '<Relationship Id="rId1" '
        'Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" '
        'Target="word/document.xml"/>'
        '</Relationships>';
  }

  String _buildDocRels() {
    final sb = StringBuffer();
    sb.write('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>');
    sb.write('<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">');
    sb.write('<Relationship Id="rId1" '
        'Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" '
        'Target="styles.xml"/>');
    for (final img in _imageEntries) {
      sb.write('<Relationship Id="${img.rId}" '
          'Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/image" '
          'Target="media/${img.filename}"/>');
    }
    sb.write('</Relationships>');
    return sb.toString();
  }

  static String _buildStyles() {
    return '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<w:styles xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main" '
        'xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">'

        // Default paragraph font
        '<w:docDefaults>'
        '<w:rPrDefault><w:rPr>'
        '<w:rFonts w:ascii="Calibri" w:hAnsi="Calibri" w:cs="Calibri"/>'
        '<w:sz w:val="24"/><w:szCs w:val="24"/>'
        '</w:rPr></w:rPrDefault>'
        '</w:docDefaults>'

        // Normal
        '<w:style w:type="paragraph" w:default="1" w:styleId="Normal">'
        '<w:name w:val="Normal"/>'
        '<w:pPr><w:spacing w:after="160"/></w:pPr>'
        '</w:style>'

        // Title
        '<w:style w:type="paragraph" w:styleId="Title">'
        '<w:name w:val="Title"/>'
        '<w:pPr><w:jc w:val="center"/><w:spacing w:after="200"/></w:pPr>'
        '<w:rPr><w:b/><w:sz w:val="56"/><w:szCs w:val="56"/>'
        '<w:color w:val="1F3864"/></w:rPr>'
        '</w:style>'

        // Subtitle
        '<w:style w:type="paragraph" w:styleId="subtitle">'
        '<w:name w:val="subtitle"/>'
        '<w:pPr><w:jc w:val="center"/></w:pPr>'
        '<w:rPr><w:color w:val="595959"/><w:sz w:val="24"/></w:rPr>'
        '</w:style>'

        // Heading1
        '<w:style w:type="paragraph" w:styleId="Heading1">'
        '<w:name w:val="heading 1"/>'
        '<w:pPr><w:spacing w:before="240" w:after="120"/></w:pPr>'
        '<w:rPr><w:b/><w:sz w:val="36"/><w:szCs w:val="36"/>'
        '<w:color w:val="1F3864"/></w:rPr>'
        '</w:style>'

        // Heading2
        '<w:style w:type="paragraph" w:styleId="Heading2">'
        '<w:name w:val="heading 2"/>'
        '<w:pPr><w:spacing w:before="200" w:after="100"/></w:pPr>'
        '<w:rPr><w:b/><w:sz w:val="30"/><w:szCs w:val="30"/>'
        '<w:color w:val="2E74B5"/></w:rPr>'
        '</w:style>'

        // Heading3
        '<w:style w:type="paragraph" w:styleId="Heading3">'
        '<w:name w:val="heading 3"/>'
        '<w:pPr><w:spacing w:before="120" w:after="60"/></w:pPr>'
        '<w:rPr><w:b/><w:i/><w:sz w:val="24"/><w:szCs w:val="24"/>'
        '<w:color w:val="595959"/></w:rPr>'
        '</w:style>'

        // Caption
        '<w:style w:type="paragraph" w:styleId="Caption">'
        '<w:name w:val="caption"/>'
        '<w:pPr><w:jc w:val="center"/></w:pPr>'
        '<w:rPr><w:i/><w:sz w:val="18"/><w:color w:val="595959"/></w:rPr>'
        '</w:style>'

        // TableGrid
        '<w:style w:type="table" w:styleId="TableGrid">'
        '<w:name w:val="Table Grid"/>'
        '</w:style>'

        '</w:styles>';
  }

  static String _buildSettings() {
    return '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<w:settings xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">'
        '<w:defaultTabStop w:val="720"/>'
        '</w:settings>';
  }

  static void _addToArchive(Archive archive, String path, String content) {
    final bytes = utf8.encode(content);
    archive.addFile(ArchiveFile(path, bytes.length, bytes));
  }

  /// Escape XML special characters
  static String _xe(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }

  /// Extract plain text from Quill delta JSON string
  static String _deltaToPlainText(String deltaJson) {
    try {
      final ops = jsonDecode(deltaJson) as List;
      final buffer = StringBuffer();
      for (final op in ops) {
        if (op is Map && op['insert'] is String) {
          buffer.write(op['insert'] as String);
        }
      }
      return buffer.toString().trim();
    } catch (_) {
      return '';
    }
  }
}

class _ImageEntry {
  final String rId;
  final String filename;
  final Uint8List bytes;
  final String ext;

  const _ImageEntry({
    required this.rId,
    required this.filename,
    required this.bytes,
    required this.ext,
  });
}
