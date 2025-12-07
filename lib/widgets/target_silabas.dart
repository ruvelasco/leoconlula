import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

typedef OnAcceptSilaba = void Function(int index, String silaba);

class TargetSilabas extends StatelessWidget {
  final String? imageAsset;
  final String palabra;
  final List<String?> huecos;
  final OnAcceptSilaba onAccept;
  final Widget Function(BuildContext context, int index, Widget? child)?
  huecoBuilder;

  const TargetSilabas({
    super.key,
    this.imageAsset,
    required this.palabra,
    required this.huecos,
    required this.onAccept,
    this.huecoBuilder,
  });

  @override
  Widget build(BuildContext context) {
    // Tamaño igual que TargetCard
    const double outerWidth = 225;
    const double outerHeight = 370;
    const double innerSize = 210;
    const double rectHeight = 60;

    return FutureBuilder<Directory>(
      future: getApplicationDocumentsDirectory(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();
        final docPath = snapshot.data!.path;
        return Center(
          child: Container(
            width: outerWidth,
            height: outerHeight,
            decoration: BoxDecoration(
              color: const Color.fromRGBO(63, 46, 31, 1), // Marrón
              borderRadius: BorderRadius.circular(16),
              border: null,
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
                const SizedBox(height: 5),
                Container(
                  width: innerSize,
                  height: innerSize,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Image.file(
                      File('$docPath/vocabulario/$imageAsset'),
                      width: 120,
                      height: 120,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                // Primer rectángulo blanco con el label
                Column(
                  children: [
                    const SizedBox(height: 10),
                    Container(
                      width: innerSize,
                      height: rectHeight,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          palabra,
                          style: const TextStyle(
                            color: Color.fromRGBO(63, 46, 31, 1),
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Huecos de sílabas bien alineados y centrados
                SizedBox(
                  width: innerSize,
                  height: rectHeight,
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(huecos.length, (index) {
                        final silaba = huecos[index];
                        Widget? child;
                        if (silaba != null) {
                          child = Text(
                            silaba,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color.fromRGBO(63, 46, 31, 1),
                            ),
                          );
                        }
                        Widget target = DragTarget<String>(
                          builder: (context, candidateData, rejectedData) {
                            if (huecoBuilder != null) {
                              return huecoBuilder!(context, index, child);
                            }
                            // Por defecto, hueco blanco con borde marrón
                            return Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              constraints: BoxConstraints(
                                minWidth: 210/huecos.length -8,
                                maxWidth: double.infinity,
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              height: 60,
                              child: Center(
                                child: child != null
                                    ? FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: child,
                                )
                                    : null,
                              ),
                            );
                          },
                          onWillAcceptWithDetails: (details) => silaba == null,
                          onAcceptWithDetails: (details) => onAccept(index, details.data),
                        );
                        return target;
                      }),
                    ),
                  ),
                // Palabra de referencia debajo (opcional)
              ],
            ),
          ),
        );
      },
    );
  }
}
