import 'package:flutter/material.dart';
import 'screens/login/login_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      // 🔥 TAMBAHAN THEME DI SINI
      theme: ThemeData(
        primaryColor: const Color(0xFF624D42),
        scaffoldBackgroundColor: Colors.grey[100],

        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF624D42),
          elevation: 0,
          centerTitle: true,
        ),

        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),

      home: const LoginPage(),
    );
  }
}