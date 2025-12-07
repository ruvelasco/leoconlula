import 'package:flutter/material.dart';


class TargetCardSinImagen extends StatelessWidget {
  final String label;
  final Widget? droppedChild;
  final Color? borderColor;
  final void Function(String)? onAccept;
  final bool acierto;

  const TargetCardSinImagen({
    super.key,
    required this.label,
    this.droppedChild,
    this.borderColor,
    this.onAccept,
    this.acierto = false,
  });

  @override
  Widget build(BuildContext context) {
    const double outerWidth = 200;
    const double margin = 12; // Margen uniforme en todos los lados
    const double innerSize = outerWidth - (margin * 2); // 176
    const double rectHeight = 50;
    const double outerHeight = margin + rectHeight + 8 + innerSize + margin; // 258

    return Center(
      child: Container(
        width: outerWidth,
        height: outerHeight,
        decoration: BoxDecoration(
        color: const Color.fromRGBO(63, 46, 31, 1), // Marrón
        borderRadius: BorderRadius.circular(16),
        border: borderColor != null ? Border.all(color: borderColor!, width: 5) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
        child: Padding(
          padding: const EdgeInsets.all(margin),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Franja blanca con el texto arriba
              Container(
                width: innerSize,
                height: rectHeight,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(
                    color:  const Color.fromRGBO(63, 46, 31, 1),
                    width: 3,
                  ),
                ),
                child: Center(
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: Color.fromRGBO(63, 46, 31, 1),
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Zona blanca para la imagen (DragTarget)
              DragTarget<String>(
                builder: (context, candidateData, rejectedData) {
                  return Container(
                    width: innerSize,
                    height: innerSize,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(11),
                      border: Border.all(
                        color: const Color.fromRGBO(63, 46, 31, 1),
                        width: 3,
                      ),
                    ),
                    child: Center(
                      child: droppedChild,
                    ),
                  );
                },
                onWillAcceptWithDetails: (details) => onAccept != null,
                onAcceptWithDetails: (details) {
                  if (onAccept != null) onAccept!(details.data);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}