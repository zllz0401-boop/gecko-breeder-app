import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class QrDialog extends StatelessWidget {
  final String animalName;
  final String animalId;

  const QrDialog({
    super.key,
    required this.animalName,
    required this.animalId,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 제목
            Text(
              animalName,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text("사육장 부착용 QR코드", style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 24),

            // QR 코드 (라이브러리 사용)
            SizedBox(
              height: 200,
              width: 200,
              child: QrImageView(
                data: animalId,
                version: QrVersions.auto,
                backgroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 24),

            // 닫기 버튼
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey.shade200,
                foregroundColor: Colors.black,
                elevation: 0,
              ),
              child: const Text("닫기"),
            )
          ],
        ),
      ),
    );
  }
}
