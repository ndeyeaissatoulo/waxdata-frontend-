import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/home_screen.dart';
import 'app_theme.dart';

void main() {
  runApp(const WaxDataApp());
}

class WaxDataApp extends StatelessWidget {
  const WaxDataApp({super.key});

  @override
  Widget build(BuildContext context) {
    final baseTheme = getAppTheme();

    return MaterialApp(
      title: 'WaxData',
      debugShowCheckedModeBanner: false,
      theme: baseTheme.copyWith(
        textTheme: GoogleFonts.interTextTheme(baseTheme.textTheme),
      ),
      home: const HomeScreen(),
    );
  }
}
