import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../services/supabase_service.dart';
import '../../features/family/models/family_model.dart';
import '../../features/members/models/family_member_model.dart';

class PdfExportService {
  static Future<void> printFamilyDirectory(List<FamilyModel> families) async {
    final fontRegular = await PdfGoogleFonts.poppinsRegular();
    final fontBold = await PdfGoogleFonts.poppinsBold();

    List<FamilyModel> familyList = List.from(families);
    if (familyList.isEmpty) {
      try {
        final response = await SupabaseService.client.from('families').select('*, profiles:created_by(mobile_number)').order('created_at', ascending: false);
        familyList = (response as List).map((e) => FamilyModel.fromJson(e)).toList();
      } catch (_) {}
    }

    // Fetch all family members across all families from database
    final Map<String, List<FamilyMemberModel>> membersByFamilyId = {};
    try {
      final response = await SupabaseService.client.from('family_members').select('*');
      for (final item in response as List) {
        final member = FamilyMemberModel.fromJson(item);
        if (member.familyId != null && member.familyId!.isNotEmpty) {
          membersByFamilyId.putIfAbsent(member.familyId!, () => []).add(member);
        }
      }
    } catch (_) {
      // Fallback if network or table query fails
    }

    // Fetch all profiles to map HOF mobile numbers by profile id
    final Map<String, String> profileMobileById = {};
    try {
      final profilesResponse = await SupabaseService.client.from('profiles').select('id, mobile_number');
      for (final p in profilesResponse as List) {
        if (p['id'] != null && p['mobile_number'] != null) {
          profileMobileById[p['id'].toString()] = p['mobile_number'].toString();
        }
      }
    } catch (_) {}

    final pdf = pw.Document(
      theme: pw.ThemeData.withFont(
        base: fontRegular,
        bold: fontBold,
      ),
    );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        header: (pw.Context context) {
          return pw.Column(
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
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
                    'Family Directory Report',
                    style: pw.TextStyle(
                      fontSize: 12,
                      color: PdfColors.grey700,
                    ),
                  ),
                ],
              ),
              pw.Divider(thickness: 1, color: PdfColors.teal800),
              pw.SizedBox(height: 8),
            ],
          );
        },
        footer: (pw.Context context) {
          return pw.Container(
            alignment: pw.Alignment.centerRight,
            margin: const pw.EdgeInsets.only(top: 10),
            child: pw.Text(
              'Page ${context.pageNumber} of ${context.pagesCount}',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
            ),
          );
        },
        build: (pw.Context context) {
          if (familyList.isEmpty) {
            return [
              pw.Center(
                child: pw.Padding(
                  padding: const pw.EdgeInsets.all(40),
                  child: pw.Text(
                    'No registered family records found.',
                    style: pw.TextStyle(fontSize: 14, color: PdfColors.grey700),
                  ),
                ),
              )
            ];
          }

          final List<pw.Widget> widgets = [];
          widgets.add(
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Total Families Registered: ${familyList.length}',
                  style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.grey800),
                ),
                pw.Text(
                  'Generated Date: ${DateFormat('dd MMM yyyy').format(DateTime.now())}',
                  style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
                ),
              ],
            ),
          );
          widgets.add(pw.SizedBox(height: 12));

          for (int i = 0; i < familyList.length; i++) {
            final f = familyList[i];
            final members = membersByFamilyId[f.id] ?? [];
            final mobileNum = f.mobileNumber ?? (f.createdBy != null ? profileMobileById[f.createdBy!] : null) ?? 'N/A';

            widgets.add(
              pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 16),
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.teal800, width: 0.8),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // HOF Header
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: const pw.BoxDecoration(
                        color: PdfColors.teal800,
                        borderRadius: pw.BorderRadius.all(pw.Radius.circular(4)),
                      ),
                      child: pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            'Head of Family: ${f.fullName}',
                            style: pw.TextStyle(
                              color: PdfColors.white,
                              fontSize: 11,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.Text(
                            'Code: ${f.familyCode}',
                            style: pw.TextStyle(
                              color: PdfColors.white,
                              fontSize: 10,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    pw.SizedBox(height: 8),

                    // HOF Details Grid
                    pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Expanded(
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              _buildPdfTextRow('Registered Mobile:', mobileNum),
                              _buildPdfTextRow('Father / Husband:', f.fatherHusbandName),
                              _buildPdfTextRow('Mother Name:', f.motherName),
                              _buildPdfTextRow('Marital Status:', f.maritalStatus),
                            ],
                          ),
                        ),
                        pw.SizedBox(width: 12),
                        pw.Expanded(
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              _buildPdfTextRow('Gender:', f.gender),
                              _buildPdfTextRow('Blood Group:', f.bloodGroup),
                              _buildPdfTextRow('Address:', f.address),
                            ],
                          ),
                        ),
                      ],
                    ),

                    pw.SizedBox(height: 10),
                    pw.Divider(thickness: 0.5, color: PdfColors.grey400),
                    pw.SizedBox(height: 6),

                    // Sub-section: Family Members
                    pw.Text(
                      'Family Members (${members.length}):',
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.teal900,
                      ),
                    ),
                    pw.SizedBox(height: 6),

                    if (members.isEmpty)
                      pw.Padding(
                        padding: const pw.EdgeInsets.only(left: 4),
                        child: pw.Text(
                          'No additional family members registered.',
                          style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
                        ),
                      )
                    else
                      pw.TableHelper.fromTextArray(
                        border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                        headerStyle: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                          fontSize: 8,
                        ),
                        headerDecoration: const pw.BoxDecoration(color: PdfColors.teal700),
                        cellStyle: const pw.TextStyle(fontSize: 8),
                        cellAlignment: pw.Alignment.centerLeft,
                        cellPadding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                        headers: ['#', 'Member Name', 'Relation', 'Age', 'Blood Group'],
                        data: members.asMap().entries.map((entry) {
                          final idx = entry.key + 1;
                          final m = entry.value;
                          return [
                            idx.toString(),
                            m.fullName,
                            m.relation,
                            '${m.age} yrs',
                            m.bloodGroup ?? '-',
                          ];
                        }).toList(),
                      ),
                  ],
                ),
              ),
            );
          }

          return widgets;
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'AGBS_Samaj_Family_Directory_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
    );
  }

  static pw.Widget _buildPdfTextRow(String label, String value) {
    if (value.trim().isEmpty) return pw.SizedBox.shrink();
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 3),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 85,
            child: pw.Text(
              label,
              style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey900),
            ),
          ),
        ],
      ),
    );
  }
}
