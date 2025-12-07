import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:async';
import 'dart:math';
import 'widgets/fondo.dart';
import 'widgets/target_card.dart';
import 'widgets/word_widget.dart';

class DragGamePage extends StatefulWidget {
  const DragGamePage({super.key});

  @override
  State<DragGamePage> createState() => _DragGamePageState();
}

class _DragGamePageState extends State<DragGamePage> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  late ConfettiController _confettiController;

  final List<Alignment> _zonePositions = [
    Alignment.topLeft,
    Alignment.topCenter,
    Alignment.topRight,
  ];

  bool isCorrectAccepted = false;
  double posX = 0;
  double posY = 200; // Cambia esto en la declaración

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
    _shuffleZones();
    // Coloca la palabra a 200px del final al iniciar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        final centerX = (MediaQuery.of(context).size.width - 240) / 2;
        final bottomY = 200.0; // Cambia esto para que esté a 200px del final
        posX = centerX;
        posY = bottomY;
      });
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _playSound(String fileName) async {
    await _audioPlayer.play(AssetSource('/sonidos/$fileName'));
  }

  void _shuffleZones() {
    _zonePositions.shuffle();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.home, color: Colors.white), // Icono de casa en blanco
          onPressed: () {
            Navigator.pop(context); // Vuelve a la pantalla anterior
          },
        ),
        title: const Text(
          'ACTIVIDAD TIPO 1',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color.fromRGBO(63, 46, 31, 1),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: CircleAvatar(
              radius: 20,
              backgroundColor: Colors.white, // Fondo blanco para el borde
              child: CircleAvatar(
                radius: 18,
                backgroundImage: AssetImage('assets/images/lula.png'), // Ruta de la foto del usuario
              ),
            ),
          ),
        ],
      ),
      body: BackgroundContainer(
        child: Stack(
          children: [
            // Confetti
            Align(
              alignment: Alignment.center,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                shouldLoop: false,
                numberOfParticles: 100,
                emissionFrequency: 0.1,
                gravity: 0.5,
                colors: const [Colors.green, Colors.blue, Colors.pink, Colors.orange],
                createParticlePath: _drawStar,
              ),
            ),
            // Zonas de acierto/error
            Stack(
              children: [
                _buildZone(_zonePositions[0], 'assets/images/lula.png', 'perro', isCorrect: false),
                _buildZone(_zonePositions[1], 'assets/images/lula.png', 'gato', isCorrect: false),
                _buildZone(_zonePositions[2], 'assets/images/lula.png', 'araña', isCorrect: true),
              ],
            ),
            // Palabra arrastrable
AnimatedPositioned(
                duration: const Duration(milliseconds: 1500), // Duración más lenta (1.5 segundos)
                curve: Curves.easeInOut, // Curva de animación
                left: posX,
                top: posY,
                child: Draggable<String>(
                  data: 'araña',
                  feedback: const WordWidget(word: 'araña'), // Lo que se muestra mientras se arrastra
                  childWhenDragging: const SizedBox.shrink(), // No muestra nada mientras se arrastra
                  child: const WordWidget(word: 'araña'), // Palabra visible
                  onDragEnd: (details) {
                    if (!isCorrectAccepted) {
                      setState(() {
                        final centerX = (MediaQuery.of(context).size.width - 240) / 2;
                        final bottomY = MediaQuery.of(context).size.height - 200;
                        posX = centerX;
                        posY = bottomY;
                      });
                    }
                  },
                ),
              ),
    
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.refresh),
        onPressed: () {
          setState(() {
            isCorrectAccepted = false;
            _shuffleZones();
          });
        },
      ),
    );
  }

  Widget _buildZone(Alignment alignment, String imageAsset, String label, {required bool isCorrect}) {
    final screenWidth = MediaQuery.of(context).size.width;

    final double leftMargin = 60;
    final double zoneWidth = 250;
    final double totalZonesWidth = (zoneWidth * 3) + (leftMargin * 2);
    final double startX = (screenWidth - totalZonesWidth) / 2;

    final positions = {
      Alignment.topLeft: Offset(startX, 100),
      Alignment.topCenter: Offset(startX + zoneWidth + leftMargin, 100),
      Alignment.topRight: Offset(startX + (zoneWidth + leftMargin) * 2, 100),
    };

    final Offset pos = positions[alignment] ?? const Offset(60, 100);

    return Stack(
      children: [
        Positioned(
          top: pos.dy,
          left: pos.dx,
          child: DragTarget<String>(
            onWillAcceptWithDetails: (details) {
              // Devuelve true si deseas aceptar el elemento, pero no afecta el diseño
              return true;
            },
            onAcceptWithDetails: (details) {
              setState(() {
                if (isCorrect) {
                  isCorrectAccepted = true;
                  _confettiController.play();
                  _playSound('applause.mp3');

                  // Actualiza la posición para que se quede en la zona correcta
                  posX = pos.dx; // Posición X de la zona
                  posY = pos.dy; // Posición Y de la zona
                } else {
                  _playSound('error.mp3');
                  Timer(const Duration(seconds: 2), () {
                    setState(() {
                      // Regresa a la posición inicial si es incorrecto
                      final centerX = (MediaQuery.of(context).size.width - 240) / 2;
                      final bottomY = MediaQuery.of(context).size.height - 200;
                      posX = centerX;
                      posY = bottomY;
                    });
                  });
                }
              });
            },
            builder: (context, candidateData, rejectedData) {

              return TargetCard(
                imageAsset: imageAsset,
                label: label,
              );
            },
          ),
        ),
      ],
    );
  }

  Path _drawStar(Size size) {
    final path = Path();
    const numberOfPoints = 5;
    final double radius = size.width / 2;
    final double angle = (2 * pi) / numberOfPoints;
    final center = Offset(size.width / 2, size.height / 2);

    for (int i = 0; i <= numberOfPoints; i++) {
      final x = center.dx + radius * cos(i * angle);
      final y = center.dy + radius * sin(i * angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    return path;
  }
}