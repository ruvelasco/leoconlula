import 'package:flutter/material.dart';

class BarraProgreso extends StatelessWidget {
  final int aciertos;
  final int maxAciertos;

  const BarraProgreso({
    super.key,
    required this.aciertos,
    required this.maxAciertos,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Container(
            width: 700,
            height: 42,
            decoration: BoxDecoration(
              color: const Color.fromRGBO(63, 46, 31, 0.18),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: LinearProgressIndicator(
                value: aciertos / maxAciertos,
                minHeight: 42,
                backgroundColor: Colors.transparent,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  Color.fromRGBO(63, 46, 31, 1),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Aciertos: $aciertos / $maxAciertos',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color.fromRGBO(63, 46, 31, 1),
            ),
          ),
        ],
      ),
    );
  }
}