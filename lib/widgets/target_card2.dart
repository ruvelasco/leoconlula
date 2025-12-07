import 'package:flutter/material.dart';

class TargetCard2 extends StatelessWidget {
  final String imageAsset;
  final String label;
  final Widget? droppedChild; // Widget opcional para mostrar la palabra arrastrada
  final Function(String)? onAccept; // Callback para aceptar el drop

  const TargetCard2({
    super.key,
    required this.imageAsset,
    required this.label,
    this.droppedChild,
    this.onAccept,
  });

  @override
  Widget build(BuildContext context) {
    // Tamaño del contenedor marrón ampliado
    const double outerWidth = 225;
    const double outerHeight = 310;
    // Tamaño de los contenedores blancos
    const double innerSize = 210;
    const double rectHeight = 60;

    return Container(
      width: outerWidth,
      height: outerHeight,
      decoration: BoxDecoration(
        color: const Color.fromRGBO(63, 46, 31, 1), // Marrón
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Cuadrado blanco con la imagen
          Container(
            width: innerSize,
            height: innerSize,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Center(
              child: Image.network(
                imageAsset,
                width: 120,
                height: 120,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Image.asset(
                    'assets/images/lula.png',
                    width: 120,
                    height: 120,
                    fit: BoxFit.contain,
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 10),
          // Primer rectángulo blanco con el label
          Container(
            width: innerSize,
            height: rectHeight,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                label,
                style: const TextStyle(
                  color: Color.fromRGBO(63, 46, 31, 1),
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          const SizedBox(height: 10),
          // Segundo rectángulo blanco como área de drop
        ],
      ),
    );
  }
}