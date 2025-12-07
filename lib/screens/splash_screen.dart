import 'package:flutter/material.dart';
import '../widgets/fondo_inicio.dart'; // Importa el widget BackgroundContainer
import 'principal.dart'; // Importa la página principal

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _animation;
  int _currentIndex = 0;

  final List<String> _messages = [
    'Cargando usuarios...',
    'Cargando interfaz...',
    'Preparándolo todo...',
    '¡Listo, a jugar!',
  ];

  @override
  void initState() {
    super.initState();

    // Configura el controlador de animación
    _controller = AnimationController(
      duration: const Duration(
        milliseconds: 4000,
      ), // Duración total de entrada, pausa y salida
      vsync: this,
    );

    _animation = Tween<Offset>(
      begin: const Offset(1.0, 0.0), // Comienza fuera de la pantalla (derecha)
      end: const Offset(-1.0, 0.0), // Termina fuera de la pantalla (izquierda)
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    // Repite la animación con un cambio de mensaje
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _currentIndex = (_currentIndex + 1) % _messages.length;
        });
        _controller.reset();
        _controller.forward();
      }
    });

    _controller.forward();

    // Navega a la página principal después de 14 segundos
    Future.delayed(const Duration(seconds: 14), () {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const PrincipalPage()),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      body: BackgroundContainerInicio(
        child: Stack(
          children: [
            // Contenido central (texto, logo, indicador)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Bienvenido a la App',
                    style: TextStyle(
                      fontSize: 44,
                      fontWeight: FontWeight.bold,
                      color: Color.fromRGBO(63, 46, 31, 1),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Transform.translate(
                    offset: const Offset(
                      80,
                      0,
                    ), // Mover 80 píxeles a la derecha
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 450,
                          height: 450,
                          child: CircularProgressIndicator(
                            strokeWidth: 44, // Más ancho
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Color.fromRGBO(63, 46, 31, 1),
                            ),
                          ),
                        ),
                        Image.asset(
                          'assets/images/letrero.png',
                          width: 200,
                          height: 200,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  SlideTransition(
                    position: _animation,
                    child: Text(
                      _messages[_currentIndex],
                      style: const TextStyle(
                        fontSize: 54,
                        fontWeight: FontWeight.bold,
                        color: Color.fromRGBO(63, 46, 31, 1),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Imagen de Lula en primer plano (por encima del CircularProgressIndicator)
            Positioned(
              bottom: 60,
              left: -100,
              child: Image.asset(
                'assets/images/lula.png',
                width: screenWidth * 2 / 3,
                height: screenHeight * 2 / 3,
                fit: BoxFit.contain,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
