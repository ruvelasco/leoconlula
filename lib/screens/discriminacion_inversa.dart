import 'dart:io';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:leoconlula/widgets/fondo.dart';
import 'package:path_provider/path_provider.dart';
import 'package:leoconlula/widgets/target_card.dart';
import 'package:leoconlula/widgets/word_widget.dart';
import 'package:leoconlula/services/data_service.dart';
import 'package:leoconlula/widgets/barra_progreso.dart';
import 'package:leoconlula/widgets/avatar_usuario.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:leoconlula/widgets/refuerzo.dart';
import 'package:leoconlula/helpers/db_helper.dart';

class DiscriminacionInversa extends StatefulWidget {
  const DiscriminacionInversa({super.key});

  @override
  State<DiscriminacionInversa> createState() => _DiscriminacionInversaState();
}

class _DiscriminacionInversaState extends State<DiscriminacionInversa> {
  String palabraCorrecta = '';
  String palabraIncorrecta = '';
  String nombreImagen = '';
  bool acierto = false;
  bool error = false;
  bool sinPalabras = false;
  int aciertos = 0;
  int maxAciertos = 5;
  int erroresTotales = 0;
  bool _finalizado = false;
  int? _sesionId;
  int? _userId;

  int errores = 0;
  String? palabraSoltada;
  final AudioPlayer _audioPlayer = AudioPlayer();

  List<String> opciones = [];
  List<Map<String, String>> tarjetas = []; // label y nombreImagen

  late RefuerzoController refuerzo;
  late ConfettiController _confettiController;
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

  Future<void> _cargarRepeticiones() async {
    final rep = await DataService.obtenerNumeroRepeticiones();
    setState(() {
      maxAciertos = rep;
    });
  }

  Future<void> _cargarPalabras() async {
    _userId ??= await _resolverUserId();
    debugPrint('🔍 DISCRIMINACION_INVERSA: Cargando vocabulario para usuario $_userId');

    final vocabularioRaw = await DataService.obtenerVocabulario(userId: _userId);
    debugPrint('📚 DISCRIMINACION_INVERSA: ${vocabularioRaw.length} palabras cargadas');

    final vocabulario = vocabularioRaw.map((e) => Map<String, dynamic>.from(e)).toList();

    if (vocabulario.length < 2) {
      setState(() {
        palabraCorrecta = 'gato';
        palabraIncorrecta = 'perro';
        nombreImagen = 'gato.png';
        acierto = false;
        error = false;
        sinPalabras = true;
        errores = 0;
        palabraSoltada = null;
      });
      return;
    }

    vocabulario.shuffle();
    final correcta = vocabulario[0];
    final incorrecta = vocabulario[1];
    await _iniciarSesionSiNoExiste(palabras: [
      (correcta['label'] ?? '').toString(),
      (incorrecta['label'] ?? '').toString(),
    ]);

    // Cargar imagen usando DataService helper
    final nombreImagenCorrecta = correcta['nombreImagen'] as String? ?? '';
    if (nombreImagenCorrecta.isNotEmpty) {
      try {
        String? localPath;
        if (!DataService.useRemoteApi) {
          final docDir = await getApplicationDocumentsDirectory();
          localPath = docDir.path;
        }
        final imageProvider = await DataService.obtenerImageProvider(nombreImagenCorrecta, localPath: localPath);
        imageProviders = [imageProvider];
      } catch (e) {
        debugPrint('❌ DISCRIMINACION_INVERSA: Error cargando imagen: $e');
        imageProviders = [null];
      }
    }

    setState(() {
      palabraCorrecta = correcta['label'] as String? ?? '';
      palabraIncorrecta = incorrecta['label'] as String? ?? '';
      nombreImagen = nombreImagenCorrecta;
      acierto = false;
      error = false;
      sinPalabras = false;
      errores = 0;
      palabraSoltada = null;
      opciones = [palabraCorrecta, palabraIncorrecta];
      opciones.shuffle();
    });
  }

  Future<void> reproducirSonido(String asset) async {
    await _audioPlayer.stop();
    await _audioPlayer.play(AssetSource(asset));
  }

  void _handleAccept(String palabra) async {
    setState(() {
      palabraSoltada = palabra;
    });

    if (palabra == palabraCorrecta) {
      await refuerzo.reproducirAplauso();
      setState(() {
        acierto = true;
        error = false;
        aciertos++;
        errores = 0;
      });
      if (aciertos >= maxAciertos) {
        await _finalizarActividad();
      } else {
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted && aciertos < maxAciertos) {
            _cargarPalabras(); // aquí sí se limpia palabraSoltada
          }
        });
      }
    } else {
      await refuerzo.reproducirError();
      setState(() {
        acierto = false;
        error = true;
        errores++;
        erroresTotales++;
        // NO limpies palabraSoltada aquí
      });

      // Segundo error: ilumina la palabra correcta
      if (errores == 2) setState(() {});
      // Tercer error: difumina la incorrecta
      if (errores == 3) setState(() {});
      // Cuarto error: coloca la palabra correcta automáticamente
      if (errores >= 4) {
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            setState(() {
              palabraSoltada = palabraCorrecta;
              acierto = true;
              error = false;
              errores = 0;
              aciertos++;
            });
            if (aciertos >= maxAciertos) {
              _finalizarActividad();
            } else {
              Future.delayed(const Duration(seconds: 1), () {
                if (mounted && aciertos < maxAciertos) _cargarPalabras();
              });
            }
          }
        });
      }
      // Ya no limpies palabraSoltada tras error normal
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.home, color: Colors.white), // Icono casa blanca
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text('Discriminación Inversa'),
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
          alignment: Alignment.center,
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  BarraProgreso(aciertos: aciertos, maxAciertos: maxAciertos),
                  TargetCard(
                    imageAsset: nombreImagen,
                    imageProvider: imageProviders.isNotEmpty ? imageProviders[0] : null,
                    label: palabraCorrecta,
                    onAccept: (palabra) => _handleAccept(palabra),
                    droppedChild:
                        palabraSoltada != null ? WordWidget(word: palabraSoltada!) : null,
                  ),
                  const SizedBox(height: 40),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: opciones
                        .asMap()
                        .entries
                        .map((entry) {
                          final i = entry.key;
                          final opcion = entry.value;
                          double opacity = 1.0;
                          if (errores == 3 && opcion == palabraIncorrecta) {
                            opacity = 0.15;
                          }
                          return Row(
                            children: [
                              if (i != 0) const SizedBox(width: 40),
                              Opacity(
                                opacity: opacity,
                                child: Draggable<String>(
                                  data: opcion,
                                  feedback: Material(
                                    color: Colors.transparent,
                                    child: WordWidget(word: opcion),
                                  ),
                                  childWhenDragging: Opacity(
                                    opacity: 0.3,
                                    child: WordWidget(word: opcion),
                                  ),
                                  child: WordWidget(word: opcion),
                                ),
                              ),
                            ],
                          );
                        })
                        .toList(),
                  ),
                ],
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
      ),
    );
  }

  Future<void> _iniciarSesionSiNoExiste({List<String>? palabras}) async {
    if (_sesionId != null) return;
    _userId ??= await _resolverUserId();
    if (_userId == null) return;
    _sesionId = await DataService.crearSesionActividad(
      userId: _userId!,
      actividad: 'discriminacion_inversa',
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
    await DataService.finalizarSesionActividad(
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
}
