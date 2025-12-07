import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'screens/splash_screen.dart'; // Importa la pantalla de splash

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
    databaseFactory = databaseFactoryFfiWeb; // Usa IndexedDB en web
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Drag & Drop Integrado',
      debugShowCheckedModeBanner: false, // Elimina la marca de debug
      home: const SplashScreen(), // Usa la pantalla de splash como inicial
      routes: {
        '/splash': (context) => const SplashScreen(),
        // otras rutas...
      },
    );
  }
}

