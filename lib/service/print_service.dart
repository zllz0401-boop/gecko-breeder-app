import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

class PrintService {
  static Future<Uint8List> generateClutchLabel(
    PdfPageFormat format, {
    required String maleName,
    required String femaleName,
    required int order,
    required DateTime pairingDate,
    required DateTime layDate,
    required int eggCount,
    required String memo,
  }) async {
    final doc = pw.Document();
    final font = await PdfGoogleFonts.nanumGothicExtraBold();

    // QR 데이터 (데이터 순서도 암컷 x 수컷으로 변경)
    final String qrData =
        "Clutch:$order/P:$femaleName x $maleName/Lay:${DateFormat('yyMMdd').format(layDate)}";

    doc.addPage(
      pw.Page(
        pageFormat: format,
        build: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(5),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(width: 2),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
            ),
            child: pw.Row(
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    mainAxisAlignment: pw.MainAxisAlignment.center,
                    children: [
                      // 1. [위] 부모 이름 (암컷 x 수컷)
                      pw.Text("$femaleName x $maleName", // ★ 순서 변경됨
                          style: pw.TextStyle(
                              font: font,
                              fontSize: 14,
                              fontWeight: pw.FontWeight.bold),
                          maxLines: 2,
                          overflow: pw.TextOverflow.clip),

                      pw.SizedBox(height: 2),

                      // 2. [중간] 산란 차수 (배경 제거, 폰트 사이즈 10으로 축소)
                      pw.Text(
                        "$order차 산란",
                        // ★ Eggs 폰트와 동일하게 fontSize: 10, 배경색 제거
                        style: pw.TextStyle(
                            font: font,
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold),
                      ),

                      pw.Divider(height: 6, thickness: 1),

                      // 3. 날짜 정보
                      _buildDateRow("합사일", pairingDate, font),
                      pw.SizedBox(height: 1),
                      _buildDateRow("산란일", layDate, font, isBold: true),

                      pw.SizedBox(height: 4),

                      // 4. 알 개수
                      pw.Row(
                        children: [
                          pw.Text("Eggs: $eggCount ",
                              style: pw.TextStyle(
                                  font: font,
                                  fontSize: 10,
                                  fontWeight: pw.FontWeight.bold)),
                          if (memo.isNotEmpty)
                            pw.Text("($memo)",
                                style: pw.TextStyle(font: font, fontSize: 10)),
                        ],
                      ),
                    ],
                  ),
                ),

                // [우측] QR 코드 (사이즈 확대)
                pw.Container(
                  margin: const pw.EdgeInsets.only(left: 5),
                  padding: const pw.EdgeInsets.all(0), // 여백 제거해서 공간 확보
                  decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey400)),
                  child: pw.BarcodeWidget(
                    barcode: pw.Barcode.qrCode(),
                    data: qrData,
                    width: 52, // ★ 기존 42 -> 52로 확대
                    height: 52, // ★ 기존 42 -> 52로 확대
                    drawText: false,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
    return doc.save();
  }

  static pw.Widget _buildDateRow(String label, DateTime date, pw.Font font,
      {bool isBold = false}) {
    return pw.Row(
      children: [
        pw.Text("$label: ",
            style: pw.TextStyle(
                font: font, fontSize: 8, color: PdfColors.grey700)),
        pw.Text(
          DateFormat('yyyy-MM-dd').format(date),
          style: pw.TextStyle(
              font: font,
              fontSize: 10,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal),
        ),
      ],
    );
  }
}
