import 'package:flutter/material.dart';

class BackgroundContainer extends StatelessWidget {
  final Widget child;

  const BackgroundContainer({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SizedBox.expand(
          child: Image.asset(
            'assets/images/cielo.png',
            fit: BoxFit.cover, // Ajusta a toda la pantalla
          ),
        ),
        SizedBox.expand(
          child: Image.asset(
            'assets/images/fondo_actividades.png',
            fit: BoxFit.fitWidth, // Ajusta a toda la pantalla
          ),
        ),
        child, // Contenido encima del fondo
      ],
    );
  }
}