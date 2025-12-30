import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'view/home/animal_list_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 파이어베이스 초기화 (google-services.json을 자동으로 읽어옵니다)
  await Firebase.initializeApp();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // 오른쪽 위 'DEBUG' 띠 제거
      title: 'Gecko Breeder',
      theme: ThemeData(
        useMaterial3: true,
        primarySwatch: Colors.deepOrange,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
        scaffoldBackgroundColor: const Color(0xFFF5F5F5), // 연한 회색 배경
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black, // 앱바 글씨색 검정
        ),
      ),
      home: const AnimalListScreen(),
    );
  }
}
