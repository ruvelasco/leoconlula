import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';

class TargetCard extends StatelessWidget {
  final String imageAsset;
  final String label;
  final Widget? droppedChild; // Widget opcional para mostrar la palabra arrastrada
  final Function(String)? onAccept; // Callback para aceptar el drop
  final Color? borderColor; // Añade esto al constructor
  final ImageProvider? imageProvider; // <-- Añade esto
  final GlobalKey? dropZoneKey; // Key para la zona de drop

  const TargetCard({
    super.key,
    required this.imageAsset,
    required this.label,
    this.droppedChild,
    this.onAccept,
    this.borderColor,
    this.imageProvider,
    this.dropZoneKey,
  });



  @override
  Widget build(BuildContext context) {

    // Tamaño del contenedor marrón ampliado
    const double outerWidth = 225;
    const double outerHeight = 370;
    // Tamaño de los contenedores blancos
    const double innerSize = 210;
    const double rectHeight = 60;

    return DottedBorder(
      color: borderColor ?? Colors.transparent, // Usa el color del borde si se proporciona
      strokeWidth: 20,
      dashPattern: [8, 8],
      borderType: BorderType.RRect,
      radius: const Radius.circular(20),
      padding: EdgeInsets.zero,
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
              child: (imageAsset.isEmpty && imageProvider == null)
                  ? null
                  : Center(
                      child: Image(
                        image: imageProvider ?? const AssetImage('assets/images/lula.png'),
                        fit: BoxFit.contain,
                        width: innerSize * 0.8,
                        height: innerSize * 0.8,
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
            DragTarget<String>(
              onWillAcceptWithDetails: (details) => true,
              onAcceptWithDetails: (details) => onAccept?.call(details.data),
              builder: (context, candidateData, rejectedData) {
                return Container(
                  key: dropZoneKey,
                  width: innerSize,
                  height: rectHeight,
                  decoration: BoxDecoration(
                    color: candidateData.isNotEmpty ? Colors.green:Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: candidateData.isNotEmpty
                        ? Border.all(color: Colors.green, width: 2)
                        : null,
                  ),
                  child: Center(
                    child: droppedChild,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}