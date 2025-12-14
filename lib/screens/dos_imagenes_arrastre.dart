import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:leoconlula/services/data_service.dart';
import 'package:leoconlula/widgets/fondo.dart';
import 'package:leoconlula/widgets/barra_progreso.dart';
import 'package:leoconlula/widgets/avatar_usuario.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:leoconlula/widgets/target_vacia.dart'; // O TargetCardSinImagen
import 'package:confetti/confetti.dart';
import 'package:leoconlula/helpers/db_helper.dart';

class DobleArrastrePage extends StatefulWidget {
  const DobleArrastrePage({super.key});

  @override
  State<DobleArrastrePage> createState() => _DobleArrastrePageState();
}

class _DobleArrastrePageState extends State<DobleArrastrePage> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  int aciertos = 0;
  int maxAciertos = 5;
  int erroresTotales = 0;
  bool _finalizado = false;
  int? _sesionId;
  int? _userId;
  late ConfettiController _confettiController;

  List<Map<String, dynamic>> palabras = [];
  List<Map<String, dynamic>> imagenes = [];
  List<String?> imagenesAcertadas = [null, null];
  List<bool> aciertosZona = [false, false];

  // 1. Añade este estado:
  List<bool> imagenColocada = [false, false];

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

  Future<void> _cargarRepeticiones() async {
    final rep = await DataService.obtenerNumeroRepeticiones();
    setState(() {
      maxAciertos = rep;
    });
  }

  Future<void> _cargarPalabras() async {
    _userId ??= await _resolverUserId();
    debugPrint('🔍 DOBLE_ARRASTRE: Cargando vocabulario para usuario $_userId');

    final resultado = await DataService.obtenerVocabulario(userId: _userId);
    debugPrint('📚 DOBLE_ARRASTRE: ${resultado.length} palabras cargadas');

    final listaMutable = List<Map<String, dynamic>>.from(resultado);
    listaMutable.shuffle();
    await _iniciarSesionSiNoExiste(
      palabras: [
        (listaMutable[0]['label'] ?? '').toString(),
        (listaMutable[1]['label'] ?? '').toString(),
      ],
    );
    setState(() {
      palabras = [listaMutable[0], listaMutable[1]];
      imagenes = [listaMutable[0], listaMutable[1]];
      imagenes.shuffle();
      imagenesAcertadas = [null, null];
      aciertosZona = [false, false];
    });
  }

  Future<void> reproducirSonido(String asset) async {
    await _audioPlayer.stop();
    await _audioPlayer.play(AssetSource(asset));
  }

  // 2. Modifica _onAccept:
  void _onAccept(int zona, String nombreImagen) async {
    setState(() {
      imagenesAcertadas[zona] = nombreImagen;
      aciertosZona[zona] = nombreImagen == palabras[zona]['nombreImagen'];
      // Marca la imagen como colocada
      final idx = imagenes.indexWhere((img) => img['nombreImagen'] == nombreImagen);
      if (idx != -1) imagenColocada[idx] = true;
    });

    if (aciertosZona[zona]) {
      await reproducirSonido('sonidos/applause.mp3');
    } else {
      await reproducirSonido('sonidos/error.mp3');
      erroresTotales++;
    }

    // Si ambas zonas están correctas, suma acierto y pasa a la siguiente
    if (aciertosZona.every((a) => a)) {
      setState(() {
        aciertos++;
      });
      Future.delayed(const Duration(milliseconds: 900), () {
        if (!mounted) return;
        if (aciertos >= maxAciertos) {
          _finalizarActividad();
        } else {
          _cargarPalabras();
        }
      });
    } else {
      // Si solo una está mal, deja la imagen un rato y luego limpia solo esa zona
      if (!aciertosZona[zona]) {
        Future.delayed(const Duration(milliseconds: 900), () {
          if (!mounted) return;
          setState(() {
            imagenesAcertadas[zona] = null;
            // Libera la imagen para que vuelva a estar opaca
            final idx = imagenes.indexWhere((img) => img['nombreImagen'] == nombreImagen);
            if (idx != -1) imagenColocada[idx] = false;
          });
        });
      }
    }
  }

  Widget _buildImageSmart(String nombreImagen, {double width = 150, double height = 150}) {
    // Si nombreImagen es una URL, usar Image.network directamente
    if (nombreImagen.startsWith('http://') || nombreImagen.startsWith('https://')) {
      return Image.network(
        nombreImagen,
        width: width,
        height: height,
        fit: BoxFit.contain,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return const CircularProgressIndicator();
        },
      );
    } else {
      // Para modo local, usar FutureBuilder solo para esta imagen
      return FutureBuilder<Directory>(
        future: getApplicationDocumentsDirectory(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Icon(Icons.error);
          if (!snapshot.hasData) return const CircularProgressIndicator();
          return Image.file(
            File('${snapshot.data!.path}/vocabulario/$nombreImagen'),
            width: width,
            height: height,
            fit: BoxFit.contain,
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (palabras.length < 2) {
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
        title: const Text('Arrastra cada imagen a su palabra', style: TextStyle(color: Colors.white)),
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
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  BarraProgreso(aciertos: aciertos, maxAciertos: maxAciertos),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(2, (i) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: TargetCardSinImagen(
                          label: palabras[i]['label'] ?? '',
                          acierto: aciertosZona[i],
                          droppedChild: imagenesAcertadas[i] != null
                              ? _buildImageSmart(imagenesAcertadas[i]!, width: 140, height: 140)
                              : null,
                          onAccept: (data) => _onAccept(i, data),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 40),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: imagenes.map((palabra) {
                      final nombreImagen = palabra['nombreImagen'];
                      if (imagenAcertada(nombreImagen)) {
                        return const SizedBox(width: 150, height: 150);
                      }
                      final estaColocada = imagenesAcertadas.contains(nombreImagen);
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Draggable<String>(
                          data: nombreImagen,
                          feedback: Material(
                            color: Colors.transparent,
                            child: Container(
                              width: 150,
                              height: 150,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color.fromRGBO(63, 46, 31, 1), width: 3),
                              ),
                              child: _buildImageSmart(nombreImagen),
                            ),
                          ),
                          childWhenDragging: Opacity(
                            opacity: 0.3,
                            child: Container(
                              width: 150,
                              height: 150,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color.fromRGBO(63, 46, 31, 1), width: 3),
                              ),
                              child: _buildImageSmart(nombreImagen),
                            ),
                          ),
                          child: Opacity(
                            opacity: estaColocada ? 0.3 : 1.0,
                            child: Container(
                              width: 150,
                              height: 150,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color.fromRGBO(63, 46, 31, 1), width: 3),
                              ),
                              child: _buildImageSmart(nombreImagen),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
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

  // 1. Función auxiliar para saber si la imagen está colocada correctamente
  bool imagenAcertada(String nombreImagen) {
    for (int i = 0; i < imagenesAcertadas.length; i++) {
      if (imagenesAcertadas[i] == nombreImagen && aciertosZona[i]) {
        return true;
      }
    }
    return false;
  }

  Future<void> _iniciarSesionSiNoExiste({List<String>? palabras}) async {
    if (_sesionId != null) return;
    _userId ??= await _resolverUserId();
    if (_userId == null) return;
    _sesionId = await DataService.crearSesionActividad(
      userId: _userId!,
      actividad: 'doble',
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
