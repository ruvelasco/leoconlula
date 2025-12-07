import 'package:flutter/material.dart';

class WordWidget extends StatelessWidget {
  final String word;
  const WordWidget({super.key, required this.word});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 210, // Ancho fijo
      height: 60, // Alto fijo
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(63, 46, 31, 1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center( // Centra el texto dentro del contenedor
        child: Text(
          word,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}