import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart'; // 패키지 import

class PhotoViewScreen extends StatelessWidget {
  final String photoUrl;

  const PhotoViewScreen({super.key, required this.photoUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 검은색 배경에 닫기 버튼이 있는 앱바
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        color: Colors.black,
        // 손가락으로 확대/축소 가능한 위젯
        child: PhotoView(
          imageProvider: NetworkImage(photoUrl),
          minScale: PhotoViewComputedScale.contained, // 화면에 딱 맞게 시작
          maxScale: PhotoViewComputedScale.covered * 2, // 최대 2배 확대
          loadingBuilder: (context, event) => const Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
        ),
      ),
    );
  }
}
