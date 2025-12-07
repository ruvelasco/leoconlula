import 'package:flutter/material.dart';

class BackgroundContainerInicio extends StatelessWidget {
  final Widget child;

  const BackgroundContainerInicio({super.key, required this.child});

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

        child, // Contenido encima del fondo
      ],
    );
  }
}