/// Run with: dart run tool/create_sample_docx.dart
/// Output: sample_import.docx (di root project)
library;

import 'dart:io';
import 'dart:convert';
import 'package:archive/archive.dart';

void main() {
  final body = StringBuffer();

  // ── Title ─────────────────────────────────────────────────────────────────
  body.write(p('Formulir Survei Kepuasan Pelanggan', style: 'Title'));

  // ── Heading 2 → akan jadi section Wawancara ──────────────────────────────
  body.write(p('Identitas Responden', style: 'Heading2'));
  body.write(p('Nama lengkap responden:'));
  body.write(p('Ahmad Fauzi'));

  body.write(p('Usia responden:'));
  body.write(p('32 tahun'));

  // ── Heading 2 → section Wawancara ke-2 ───────────────────────────────────
  body.write(p('Penilaian Layanan', style: 'Heading2'));
  body.write(p('Bagaimana penilaian Anda terhadap kecepatan layanan kami?'));
  body.write(p('Layanan cukup cepat, namun bisa ditingkatkan terutama di jam sibuk.'));

  body.write(p('Apa yang paling Anda sukai dari produk kami?', style: 'Heading3'));
  body.write(p('Kualitas produk sangat baik dan kemasan menarik. Harga juga terjangkau.'));

  // ── Plain paragraph → akan jadi section TeksBebas ─────────────────────────
  body.write(p('Catatan Tambahan', style: 'Heading2'));
  body.write(p(
    'Kami sangat menghargai masukan dari pelanggan untuk terus meningkatkan '
    'kualitas layanan. Formulir ini dijaga kerahasiaannya dan hanya digunakan '
    'untuk keperluan internal perusahaan.',
  ));
  body.write(p('Terima kasih telah meluangkan waktu untuk mengisi survei ini.'));

  // ── List (numPr) → akan jadi section Checklist ───────────────────────────
  body.write(pList('☑  Produk diterima dalam kondisi baik'));
  body.write(pList('☑  Pengiriman tepat waktu'));
  body.write(pList('☐  Mendapat notifikasi status pengiriman'));
  body.write(pList('☐  Puas dengan layanan pelanggan'));
  body.write(pList('☑  Akan merekomendasikan ke teman'));

  // ── Table → akan jadi section Tabel ──────────────────────────────────────
  body.write(table(
    headers: ['No', 'Aspek Penilaian', 'Nilai (1-5)', 'Keterangan'],
    rows: [
      ['1', 'Kualitas Produk', '5', 'Sangat memuaskan'],
      ['2', 'Kecepatan Pengiriman', '4', 'Cukup cepat'],
      ['3', 'Harga', '4', 'Sesuai kualitas'],
      ['4', 'Layanan Pelanggan', '3', 'Perlu ditingkatkan'],
      ['5', 'Kemasan', '5', 'Menarik dan aman'],
    ],
  ));

  final docXml = wrapDocument(body.toString());

  // ── Build archive ─────────────────────────────────────────────────────────
  final archive = Archive();
  addFile(archive, '[Content_Types].xml', contentTypes());
  addFile(archive, '_rels/.rels', rootRels());
  addFile(archive, 'word/document.xml', docXml);
  addFile(archive, 'word/_rels/document.xml.rels', docRels());
  addFile(archive, 'word/styles.xml', styles());
  addFile(archive, 'word/settings.xml',
      '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
      '<w:settings xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">'
      '<w:defaultTabStop w:val="720"/></w:settings>');

  final bytes = ZipEncoder().encode(archive)!;
  final outFile = File('sample_import.docx');
  outFile.writeAsBytesSync(bytes);

  print('✅  File berhasil dibuat: ${outFile.absolute.path}');
  print('    Pindahkan file ini ke perangkat Android lalu coba fitur Import dari Word.');
}

// ── XML helpers ──────────────────────────────────────────────────────────────

String xe(String t) => t
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;');

String p(String text, {String style = 'Normal'}) =>
    '<w:p>'
    '<w:pPr><w:pStyle w:val="$style"/></w:pPr>'
    '<w:r><w:t xml:space="preserve">${xe(text)}</w:t></w:r>'
    '</w:p>';

// List paragraph (numPr) so the importer treats it as checklist
String pList(String text) =>
    '<w:p>'
    '<w:pPr>'
    '<w:pStyle w:val="Normal"/>'
    '<w:numPr><w:ilvl w:val="0"/><w:numId w:val="1"/></w:numPr>'
    '</w:pPr>'
    '<w:r><w:t xml:space="preserve">${xe(text)}</w:t></w:r>'
    '</w:p>';

String table({
  required List<String> headers,
  required List<List<String>> rows,
}) {
  final sb = StringBuffer();
  sb.write('<w:tbl>');
  sb.write(
    '<w:tblPr>'
    '<w:tblStyle w:val="TableGrid"/>'
    '<w:tblW w:w="0" w:type="auto"/>'
    '<w:tblBorders>'
    '<w:top w:val="single" w:sz="4"/><w:left w:val="single" w:sz="4"/>'
    '<w:bottom w:val="single" w:sz="4"/><w:right w:val="single" w:sz="4"/>'
    '<w:insideH w:val="single" w:sz="4"/><w:insideV w:val="single" w:sz="4"/>'
    '</w:tblBorders>'
    '</w:tblPr>',
  );
  // Header row
  sb.write('<w:tr>');
  for (final h in headers) {
    sb.write(
      '<w:tc><w:tcPr><w:shd w:val="clear" w:color="auto" w:fill="D0E8F5"/></w:tcPr>'
      '<w:p><w:r><w:rPr><w:b/></w:rPr>'
      '<w:t xml:space="preserve">${xe(h)}</w:t></w:r></w:p></w:tc>',
    );
  }
  sb.write('</w:tr>');
  // Data rows
  for (final row in rows) {
    sb.write('<w:tr>');
    for (var ci = 0; ci < headers.length; ci++) {
      final cell = ci < row.length ? row[ci] : '';
      sb.write(
        '<w:tc><w:p><w:r>'
        '<w:t xml:space="preserve">${xe(cell)}</w:t>'
        '</w:r></w:p></w:tc>',
      );
    }
    sb.write('</w:tr>');
  }
  sb.write('</w:tbl>');
  return sb.toString();
}

String wrapDocument(String body) =>
    '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
    '<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">'
    '<w:body>$body<w:sectPr/></w:body>'
    '</w:document>';

void addFile(Archive archive, String path, String content) {
  final bytes = utf8.encode(content);
  archive.addFile(ArchiveFile(path, bytes.length, bytes));
}

String contentTypes() =>
    '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
    '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">'
    '<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>'
    '<Default Extension="xml" ContentType="application/xml"/>'
    '<Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>'
    '<Override PartName="/word/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.styles+xml"/>'
    '<Override PartName="/word/settings.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.settings+xml"/>'
    '</Types>';

String rootRels() =>
    '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
    '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
    '<Relationship Id="rId1" '
    'Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" '
    'Target="word/document.xml"/>'
    '</Relationships>';

String docRels() =>
    '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
    '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
    '<Relationship Id="rId1" '
    'Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" '
    'Target="styles.xml"/>'
    '</Relationships>';

String styles() =>
    '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
    '<w:styles xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">'
    '<w:style w:type="paragraph" w:default="1" w:styleId="Normal"><w:name w:val="Normal"/></w:style>'
    '<w:style w:type="paragraph" w:styleId="Title"><w:name w:val="Title"/>'
    '<w:rPr><w:b/><w:sz w:val="56"/></w:rPr></w:style>'
    '<w:style w:type="paragraph" w:styleId="Heading1"><w:name w:val="heading 1"/>'
    '<w:rPr><w:b/><w:sz w:val="36"/></w:rPr></w:style>'
    '<w:style w:type="paragraph" w:styleId="Heading2"><w:name w:val="heading 2"/>'
    '<w:rPr><w:b/><w:sz w:val="30"/></w:rPr></w:style>'
    '<w:style w:type="paragraph" w:styleId="Heading3"><w:name w:val="heading 3"/>'
    '<w:rPr><w:b/><w:i/><w:sz w:val="24"/></w:rPr></w:style>'
    '<w:style w:type="table" w:styleId="TableGrid"><w:name w:val="Table Grid"/></w:style>'
    '</w:styles>';
