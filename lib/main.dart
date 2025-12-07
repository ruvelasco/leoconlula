import 'package:flutter/material.dart';
import 'screens/splash_screen.dart'; // Importa la pantalla de splash

void main() => runApp(const MyApp());

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


