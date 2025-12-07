import 'dart:io';
import 'package:flutter/material.dart';
import 'package:leoconlula/widgets/target_vacia.dart';
import 'package:path_provider/path_provider.dart';
import 'package:leoconlula/helpers/db_helper.dart';
import 'package:leoconlula/widgets/fondo.dart';
import 'package:leoconlula/widgets/barra_progreso.dart';
import 'package:leoconlula/widgets/avatar_usuario.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:confetti/confetti.dart';

class ImagenArrastrePage extends StatefulWidget {
  const ImagenArrastrePage({super.key});

  @override
  State<ImagenArrastrePage> createState() => _ImagenArrastrePageState();
}

class _ImagenArrastrePageState extends State<ImagenArrastrePage> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  int aciertos = 0;
  int maxAciertos = 5;
  int erroresTotales = 0;
  bool _finalizado = false;
  int? _sesionId;
  int? _userId;
  late ConfettiController _confettiController;

  Map<String, dynamic>? palabraCorrecta;
  Map<String, dynamic>? palabraIncorrecta;
  bool imagenColocada = false;
  bool acierto = false;
  String? imagenAcertada;

  // 1. Declara una variable de estado para el orden de las imágenes:
  List<Map<String, dynamic>> imagenes = [];

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
    _cargarRepeticiones();
    _cargarPalabras();
  }

  @override
  void dispose() {
    _cerrarSesion(resultado: 'salida');
    _confettiController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _cargarPalabras() async {
    final db = await DBHelper.database;
    final resultado = await db.query('vocabulario');
    final listaMutable = List<Map<String, dynamic>>.from(resultado);
    listaMutable.shuffle(); // Baraja solo al cargar nueva palabra
    await _iniciarSesionSiNoExiste(palabras: [
      (listaMutable.first['label'] ?? '').toString(),
      (listaMutable[1]['label'] ?? '').toString(),
    ]);
    setState(() {
      palabraCorrecta = listaMutable.first;
      palabraIncorrecta = listaMutable[1];
      imagenColocada = false;
      acierto = false;
      imagenes = [palabraCorrecta!, palabraIncorrecta!];
      imagenes.shuffle(); // Baraja solo aquí
    });
  }

  Future<void> reproducirSonido(String asset) async {
    await _audioPlayer.stop();
    await _audioPlayer.play(AssetSource(asset));
  }

  void _onAccept(String nombreImagen) async {
    setState(() {
      imagenAcertada = nombreImagen;
      imagenColocada = true;
      acierto = nombreImagen == palabraCorrecta!['nombreImagen'];
      if (acierto) aciertos++;
      if (!acierto) erroresTotales++;
    });

    if (acierto) {
      await reproducirSonido('sonidos/applause.mp3');
    } else {
      await reproducirSonido('sonidos/error.mp3');
    }

    Future.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      final fueAcierto = acierto;
      setState(() {
        imagenAcertada = null;
        imagenColocada = false;
        acierto = false;
      });
      if (fueAcierto && aciertos < maxAciertos) {
        _cargarPalabras();
      } else if (fueAcierto && aciertos >= maxAciertos) {
        _finalizarActividad();
      }
    });
  }

  Future<void> _cargarRepeticiones() async {
    final rep = await DBHelper.obtenerNumeroRepeticiones();
    setState(() {
      maxAciertos = rep;
    });
  }

  // 1. Función auxiliar para saber si la imagen está colocada correctamente
  bool imagenAcertadaCorrecta(String nombreImagen) {
    return imagenAcertada == nombreImagen && acierto;
  }

  Future<void> _iniciarSesionSiNoExiste({List<String>? palabras}) async {
    if (_sesionId != null) return;
    _userId ??= await _resolverUserId();
    if (_userId == null) return;
    _sesionId = await DBHelper.crearSesionActividad(
      userId: _userId!,
      actividad: 'arrastre',
      inicio: DateTime.now(),
      palabras: palabras,
    );
  }

  Future<int?> _resolverUserId() async {
    final db = await DBHelper.database;
    final res = await db.query('usuarios', limit: 1);
    if (res.isNotEmpty) return res.first['id'] as int;
    return null;
  }

  Future<void> _cerrarSesion({String? resultado}) async {
    if (_sesionId == null) return;
    await DBHelper.finalizarSesionActividad(
      _sesionId!,
      fin: DateTime.now(),
      aciertos: aciertos,
      errores: erroresTotales,
      resultado: resultado,
    );
    _sesionId = null;
  }

  Future<void> _finalizarActividad() async {
    if (_finalizado) return;
    _finalizado = true;
    await _cerrarSesion(resultado: 'completada');
    if (!mounted) return;
    _confettiController.play();
    await _mostrarModalFinal();
  }

  Future<void> _mostrarModalFinal() async {
    final estrellas = _calcularEstrellas();
    if (!mounted) return;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            '¡Buen trabajo!',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(estrellas, (index) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(Icons.star, color: Colors.amber, size: 32),
                  );
                }),
              ),
              const SizedBox(height: 12),
              Text('Aciertos: $aciertos  Errores: $erroresTotales'),
            ],
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).maybePop();
              },
              child: const Text(
                'Continuar',
                style: TextStyle(
                  color: Color.fromRGBO(63, 46, 31, 1),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  int _calcularEstrellas() {
    if (aciertos >= maxAciertos && erroresTotales == 0) return 4;
    if (erroresTotales <= 1) return 3;
    if (erroresTotales <= 3) return 2;
    return 1;
  }

  @override
  Widget build(BuildContext context) {
    if (palabraCorrecta == null || palabraIncorrecta == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.home, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text('Arrastra la imagen correcta', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color.fromRGBO(63, 46, 31, 1),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: AvatarUsuario(),
          ),
        ],
      ),
      body: Stack(
        alignment: Alignment.center,
        children: [
          BackgroundContainer(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: FutureBuilder<Directory>(
                future: getApplicationDocumentsDirectory(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                  final docPath = snapshot.data!.path;
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      BarraProgreso(aciertos: aciertos, maxAciertos: maxAciertos),
                      const SizedBox(height: 32),
                      TargetCardSinImagen(
                        label: palabraCorrecta!['label'] ?? '',
                        acierto: acierto,
                        droppedChild: imagenAcertada != null
                            ? Image.file(
                                File('$docPath/vocabulario/$imagenAcertada'),
                                width: 120,
                                height: 120,
                                fit: BoxFit.contain,
                              )
                            : null,
                        onAccept: (data) => _onAccept(data),
                      ),
                      const SizedBox(height: 40),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: imagenes.map((palabra) {
                          final nombreImagen = palabra['nombreImagen'];
                          if (imagenAcertadaCorrecta(nombreImagen)) {
                            return const SizedBox(width: 120, height: 120);
                          }
                          final estaColocada = imagenAcertada == nombreImagen;
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Draggable<String>(
                              data: nombreImagen,
                              feedback: Material(
                                color: Colors.transparent,
                                child: Container(
                                  width: 120,
                                  height: 120,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: const Color.fromRGBO(63, 46, 31, 1), width: 3),
                                  ),
                                  child: Image.file(
                                    File('$docPath/vocabulario/$nombreImagen'),
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                              childWhenDragging: Opacity(
                                opacity: 0.3,
                                child: Container(
                                  width: 120,
                                  height: 120,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: const Color.fromRGBO(63, 46, 31, 1), width: 3),
                                  ),
                                  child: Image.file(
                                    File('$docPath/vocabulario/$nombreImagen'),
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                              child: Opacity(
                                opacity: estaColocada ? 0.3 : 1.0,
                                child: Container(
                                  width: 120,
                                  height: 120,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: const Color.fromRGBO(63, 46, 31, 1), width: 3),
                                  ),
                                  child: Image.file(
                                    File('$docPath/vocabulario/$nombreImagen'),
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
          ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            numberOfParticles: 30,
            gravity: 0.5,
          ),
        ],
      ),
    );
  }
}
