import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../../features/family/models/family_model.dart';

class PdfExportService {
  static Future<void> printFamilyDirectory(List<FamilyModel> families) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (pw.Context context) {
          return pw.Column(
            children: [
              pw.Row(
                main: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Audichya Gadhiya Brahm Samaj (AGBS)',
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.teal900,
                    ),
                  ),
                  pw.Text(
                    'Family Registry Directory',
                    style: pw.TextStyle(
                      fontSize: 12,
                      color: PdfColors.grey700,
                    ),
                  ),
                ],
              ),
              pw.Divider(thickness: 1, color: PdfColors.teal800),
              pw.SizedBox(height: 10),
            ],
          );
        },
        footer: (pw.Context context) {
          return pw.Container(
            alignment: pw.Alignment.centerRight,
            margin: const pw.EdgeInsets.only(top: 10),
            child: pw.Text(
              'Page ${context.pageNumber} of ${context.pagesCount}',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
            ),
          );
        },
        build: (pw.Context context) {
          if (families.isEmpty) {
            return [
              pw.Center(
                child: pw.Padding(
                  padding: const pw.EdgeInsets.all(40),
                  child: pw.Text(
                    'No registered family records found in the database.',
                    style: pw.TextStyle(fontSize: 14, color: PdfColors.grey700),
                  ),
                ),
              )
            ];
          }

          return [
            pw.Text(
              'Total Registered Families: ${families.length}',
              style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.grey800),
            ),
            pw.SizedBox(height: 12),
            pw.TableHelper.fromTextArray(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
                fontSize: 10,
              ),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.teal800),
              cellStyle: const pw.TextStyle(fontSize: 9),
              cellAlignment: pw.Alignment.centerLeft,
              cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
              headers: ['Code', 'Head of Family', 'Father / Husband', 'Gender', 'Blood Group', 'Members', 'Address'],
              data: families.map((f) {
                return [
                  f.familyCode,
                  f.fullName,
                  f.fatherHusbandName,
                  f.gender,
                  f.bloodGroup,
                  f.memberCount.toString(),
                  f.address,
                ];
              }).toList(),
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'AGBS_Samaj_Family_Directory_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
    );
  }
}
