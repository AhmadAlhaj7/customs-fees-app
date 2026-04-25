import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'screens/databases_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Delete old database so it recreates fresh
  final dbPath = await getDatabasesPath();
  await deleteDatabase('$dbPath/customs_fees.db');
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: MaterialApp(
        title: 'التعرفة الجمركية',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange),
          useMaterial3: true,
        ),
        home: const DatabasesScreen(),
      ),
    );
  }
}