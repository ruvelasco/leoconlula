import 'package:flutter/material.dart';
import '/widgets/target_card.dart';
import '/widgets/word_widget.dart';
import '/widgets/fondo.dart';
import 'dart:math';
import 'package:confetti/confetti.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:leoconlula/helpers/db_helper.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:leoconlula/widgets/barra_progreso.dart';
import 'package:leoconlula/widgets/avatar_usuario.dart';
import 'package:leoconlula/widgets/refuerzo.dart';
import 'package:leoconlula/helpers/db_helper.dart';

class DemoDragTarget extends StatefulWidget {
  const DemoDragTarget({super.key});

  @override
  State<DemoDragTarget> createState() => _DemoDragTargetState();
}

class _DemoDragTargetState extends State<DemoDragTarget> {
  List<Map<String, String>> tarjetas = []; // label y nombreImagen
  late List<int> orden;
  int zonaCorrecta = 0;

  List<String?> palabrasSoltadas = [];
  bool visibleDraggable = true;

  late RefuerzoController refuerzo;
  late ConfettiController _confettiController;
  final AudioPlayer _audioPlayer = AudioPlayer();

  int aciertos = 0;
  int maxAciertos = 5;
  bool mostrarConfettiFinal = false;
  bool _finalizado = false;
  int erroresTotales = 0;
  int? _sesionId;
  int? _userId;

  List<ImageProvider?> imageProviders = [];

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
    refuerzo = RefuerzoController(confettiController: _confettiController);
    _cargarRepeticiones();
    _cargarPalabras();
  }

  @override
  void dispose() {
    _cerrarSesion(resultado: 'salida');
    _audioPlayer.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _cargarPalabras() async {
    final vocabulario = await DBHelper.obtenerVocabulario();
    List<Map<String, String>> todas = vocabulario
        .map<Map<String, String>>((item) => {
              'label': item['label'] as String,
              'nombreImagen': item['nombreImagen'] as String,
            })
        .toList();
    if (todas.length >= 3) {
      todas.shuffle();
      tarjetas = todas.take(3).toList();
    } else {
      tarjetas = [
        {'label': 'perro', 'nombreImagen': 'lula.png'},
        {'label': 'gato', 'nombreImagen': 'lula.png'},
        {'label': 'araña', 'nombreImagen': 'lula.png'},
      ];
    }
    orden = List.generate(tarjetas.length, (i) => i);
    orden.shuffle();
    palabrasSoltadas = List<String?>.filled(tarjetas.length, null);
    zonaCorrecta = Random().nextInt(tarjetas.length);
    visibleDraggable = true;
    _iniciarSesionSiNoExiste();

    // Cargar imagen desde el directorio
    final docDir = await getApplicationDocumentsDirectory();
    imageProviders = tarjetas.map((tarjeta) {
      final nombreImagen = tarjeta['nombreImagen'] ?? '';
      if (nombreImagen.isNotEmpty) {
        return FileImage(File('${docDir.path}/vocabulario/$nombreImagen'));
      }
      return null;
    }).toList();

    setState(() {});
  }

  int errores = 0; // Contador de errores

  void _handleAccept(int indexEnFila, String palabra) async {
    setState(() {
      palabrasSoltadas = [null, null, null];
      palabrasSoltadas[indexEnFila] = palabra;
      visibleDraggable = false;
    });

    final labelTarget = tarjetas[orden[indexEnFila]]['label'] ?? '';

    if (orden[indexEnFila] == zonaCorrecta) {
      await _incrementarAcierto(labelTarget);
      aciertos++;
      errores = 0;
      await refuerzo.reproducirAplauso();
      if (aciertos >= maxAciertos) {
        await _finalizarActividad();
      } else {
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            setState(() {
              _mezclarTarjetas();
            });
          }
        });
      }
    } else {
      await _incrementarError(labelTarget);
      errores++;
      erroresTotales++;
      await refuerzo.reproducirError();

      // Espera a que la palabra vuelva a su sitio antes de difuminar
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            palabrasSoltadas[indexEnFila] = null;
            visibleDraggable = true;
          });

          // Ahora sí, si es el tercer error, difumina las tarjetas erróneas
          if (errores == 3) {
            setState(() {}); // Forzar rebuild para aplicar Opacity
          }
        }
      });

      // Segundo error: destaca la tarjeta correcta
      if (errores == 2) {
        setState(() {}); // Forzar rebuild para destacar
      }
      // Cuarto error: lleva la palabra a la zona correcta
      if (errores >= 4) {
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            setState(() {
              palabrasSoltadas = [null, null, null];
              palabrasSoltadas[orden.indexOf(zonaCorrecta)] = tarjetas[zonaCorrecta]['label'];
              visibleDraggable = false;
              errores = 0;
            });
            Future.delayed(const Duration(seconds: 2), () {
              if (mounted) {
                setState(() {
                  aciertos++;
                });
                if (aciertos >= maxAciertos) {
                  _finalizarActividad();
                } else {
                  _mezclarTarjetas();
                }
              }
            });
          }
        });
      }
    }
  }

  void _mezclarTarjetas() {
    if (aciertos >= maxAciertos) return;
    setState(() {
      orden.shuffle(Random());
      palabrasSoltadas = List<String?>.filled(tarjetas.length, null);
      visibleDraggable = true;
      zonaCorrecta = Random().nextInt(tarjetas.length);
    });
  }

  Future<void> _incrementarAcierto(String label) async {
    final db = await DBHelper.database;
    await db.rawUpdate(
      'UPDATE vocabulario SET acierto = acierto + 1 WHERE label = ?',
      [label],
    );
  }

  Future<void> _incrementarError(String label) async {
    final db = await DBHelper.database;
    await db.rawUpdate(
      'UPDATE vocabulario SET errores = errores + 1 WHERE label = ?',
      [label],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.home, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'DISCRIMINACIÓN',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color.fromRGBO(63, 46, 31, 1),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: AvatarUsuario(), // O AvatarUsuario(userId: tuId)
          ),
        ],
      ),
      body: BackgroundContainer(
        child: Stack(
          children: [
            Align(
              alignment: Alignment.topCenter,
              child: mostrarConfettiFinal
                  ? ConfettiWidget(
                      confettiController: _confettiController,
                      blastDirectionality: BlastDirectionality.explosive,
                      shouldLoop: false,
                      numberOfParticles: 80,
                      emissionFrequency: 0.1,
                      gravity: 0.5,
                      colors: const [Colors.green, Colors.blue, Colors.pink, Colors.orange],
                    )
                  : const SizedBox(),
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  BarraProgreso(aciertos: aciertos, maxAciertos: maxAciertos),
                  FutureBuilder<Directory>(
                    future: getApplicationDocumentsDirectory(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const SizedBox();
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(tarjetas.length, (i) {
                          final idx = orden[i];
                          final nombreImagen = tarjetas[idx]['nombreImagen'] ?? '';
                          final label = tarjetas[idx]['label'] ?? '';
                          Color? borderColor;
                          if (errores > 1 && idx == zonaCorrecta) {
                            borderColor = Colors.green;
                          }

                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: AnimatedOpacity(
                              opacity: (errores >= 3 && idx != zonaCorrecta && palabrasSoltadas[i] == null) ? 0.15 : 1.0,
                              duration: const Duration(milliseconds: 900),
                              child: TargetCard(
                                imageAsset: nombreImagen,
                                imageProvider: imageProviders[idx],
                                label: label,
                                borderColor: borderColor,
                                droppedChild: palabrasSoltadas.length > i && palabrasSoltadas[i] != null
                                    ? WordWidget(word: palabrasSoltadas[i]!)
                                    : null,
                                onAccept: (String palabra) {
                                  _handleAccept(i, palabra);
                                },
                              ),
                            ),
                          );
                        }),
                      );
                    },
                  ),
                  const SizedBox(height: 40),
                  AnimatedOpacity(
                    opacity: visibleDraggable ? 1.0 : 1.0,
                    duration: const Duration(milliseconds: 12000),
                    child: visibleDraggable && tarjetas.isNotEmpty
                        ? Draggable<String>(
                            data: tarjetas[zonaCorrecta]['label']!,
                            feedback: Material(
                              color: Colors.transparent,
                              child: WordWidget(word: tarjetas[zonaCorrecta]['label']!),
                            ),
                            childWhenDragging: const Opacity(
                              opacity: 1,
                              child: WordWidget(word: '...'),
                            ),
                            child: WordWidget(word: tarjetas[zonaCorrecta]['label']!),
                          )
                        : const SizedBox(height: 60),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _cargarRepeticiones() async {
    final rep = await DBHelper.obtenerNumeroRepeticiones();
    setState(() {
      maxAciertos = rep;
    });
  }

  Future<void> _iniciarSesionSiNoExiste() async {
    if (_sesionId != null) return;
    _userId ??= await _resolverUserId();
    if (_userId == null) return;
    final palabras = tarjetas.map((e) => e['label'] ?? '').where((e) => e.isNotEmpty).take(3).toList();
    _sesionId = await DBHelper.crearSesionActividad(
      userId: _userId!,
      actividad: 'discriminacion',
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
    setState(() {
      mostrarConfettiFinal = true;
    });
    await _cerrarSesion(resultado: 'completada');
    if (!mounted) return;
    refuerzo.lanzarConfetti();
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
}
