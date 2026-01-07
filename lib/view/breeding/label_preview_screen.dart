import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import '../../service/print_service.dart';

class LabelPreviewScreen extends StatelessWidget {
  final String maleName;
  final String femaleName;
  final int order;
  final DateTime pairingDate;
  final DateTime layDate;
  final int eggCount;
  final String memo; // ★ 추가됨

  const LabelPreviewScreen({
    super.key,
    required this.maleName,
    required this.femaleName,
    required this.order,
    required this.pairingDate,
    required this.layDate,
    required this.eggCount,
    required this.memo, // ★ 추가됨
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("라벨 미리보기")),
      body: PdfPreview(
        initialPageFormat: PdfPageFormat.roll80,
        allowSharing: true,
        canChangePageFormat: false,
        build: (format) => PrintService.generateClutchLabel(
          format,
          maleName: maleName,
          femaleName: femaleName,
          order: order,
          pairingDate: pairingDate,
          layDate: layDate,
          eggCount: eggCount,
          memo: memo, // ★ 전달
        ),
      ),
    );
  }
}
