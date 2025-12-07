import 'package:flutter/material.dart';

class BackgroundContainerPrincipal extends StatelessWidget {
  final Widget child;

  const BackgroundContainerPrincipal({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Stack(
      children: [
        SizedBox.expand(
          child: Image.asset(
            'assets/images/cielo.png',
            fit: BoxFit.cover, // Ajusta a toda la pantalla
          ),
        ),
        SizedBox.expand(
            child: Align(
            alignment: Alignment.bottomCenter,
            child: Image.asset(
              'assets/images/fondo_actividades.png',
              fit: BoxFit.fitWidth, // Ajusta a toda la pantalla
            ),
            ),
          ),
        
        Positioned(
          bottom: 60, // Posición en la parte inferior
          left: -100, // Posición en la parte izquierda
          child: Image.asset(
            'assets/images/lula.png',
            width: screenWidth * 2 / 3, // 2/3 del ancho de la pantalla
            height: screenHeight * 2 / 3, // 2/3 del alto de la pantalla
            fit: BoxFit.contain, // Ajusta la imagen manteniendo su proporción
          ),
        ),
        
        
        child, // Contenido encima del fondo
      ],
    );
  }
}