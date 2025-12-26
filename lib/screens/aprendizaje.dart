import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:leoconlula/widgets/target_card.dart';
import 'package:leoconlula/widgets/word_widget.dart';
import 'package:leoconlula/widgets/barra_progreso.dart';
import 'package:leoconlula/widgets/avatar_usuario.dart';
import 'package:leoconlula/widgets/fondo.dart';
import 'package:path_provider/path_provider.dart';
import 'package:leoconlula/services/data_service.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:confetti/confetti.dart';
import 'package:leoconlula/helpers/db_helper.dart';

class AprendizajePage extends StatefulWidget {
  final int? userId;
  const AprendizajePage({super.key, this.userId});

  @override
  State<AprendizajePage> createState() => _AprendizajePageState();
}

class _AprendizajePageState extends State<AprendizajePage> with SingleTickerProviderStateMixin {
  int aciertos = 0;
  int maxAciertos = 5;
  int errores = 0;
  int erroresTotales = 0;
  int _palabrasPresentadas = 0;
  int _bloqueActual = 0;
  int? _userId;
  final Random _random = Random();

  Map<String, dynamic>? palabraData;
  ImageProvider? imageProvider;
  DateTime? _inicioSesion;
  int? _sesionId;
  DateTime? _inicioPalabra;
  List<Map<String, dynamic>> _vocabularioCache = [];

  bool palabraColocada = false;
  int? indicePalabraColocada;
  bool animandoAutocompletar = false;
  int posicionCorrecta = 1; // 0, 1 o 2 - posición aleatoria de la tarjeta correcta
  bool _finalizado = false;

  final AudioPlayer _audioPlayer = AudioPlayer();
  late AnimationController _animationController;
  late Animation<Offset> _offsetAnimation;
  final GlobalKey _targetKey = GlobalKey();
  final GlobalKey _wordKey = GlobalKey();
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
    // Inicializar con una animación por defecto
    _offsetAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: Offset.zero,
    ).animate(_animationController);
    _iniciarSesion();
    _cargarPalabra();
  }

  void _calcularYAnimarHaciaTarget() {
    // Obtener las posiciones de los widgets
    final RenderBox? targetBox = _targetKey.currentContext?.findRenderObject() as RenderBox?;
    final RenderBox? wordBox = _wordKey.currentContext?.findRenderObject() as RenderBox?;

    if (targetBox != null && wordBox != null) {
      // Calcular el centro de cada widget
      final targetCenter = targetBox.localToGlobal(
        Offset(targetBox.size.width / 2, targetBox.size.height / 2),
      );
      final wordCenter = wordBox.localToGlobal(
        Offset(wordBox.size.width / 2, wordBox.size.height / 2),
      );

      // Calcular la diferencia en posición desde centro a centro
      final dx = (targetCenter.dx - wordCenter.dx) / wordBox.size.width;
      final dy = (targetCenter.dy - wordCenter.dy) / wordBox.size.height;

      // Crear la animación con el offset calculado
      _offsetAnimation = Tween<Offset>(
        begin: Offset.zero,
        end: Offset(dx, dy),
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ));

      // Iniciar la animación
      _animationController.forward().then((_) {
        if (mounted) {
          // Marcar como colocada (sin resetear errores todavía)
          setState(() {
            palabraColocada = true;
            indicePalabraColocada = posicionCorrecta;
            animandoAutocompletar = false;
            aciertos++;
          });
          _registrarEventoPalabra(acierto: true);
          if (aciertos >= maxAciertos) {
            _finalizarActividad();
          }

          // Esperar 1 segundo antes de recuperar opacidad
          Future.delayed(const Duration(seconds: 1), () {
            if (mounted) {
              setState(() {
                errores = 0; // Las tarjetas recuperan opacidad después de 1 segundo
              });
              // Esperar 1 segundo más antes de cargar nueva palabra
              Future.delayed(const Duration(seconds: 1), () {
                if (mounted && aciertos < maxAciertos) _cargarPalabra();
              });
            }
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _cerrarSesion(resultado: 'salida');
    _audioPlayer.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<int?> _resolverUserId() async {
    if (_userId != null) return _userId;
    if (widget.userId != null) {
      _userId = widget.userId;
      return _userId;
    }
    // En modo remoto, requiere userId como parámetro
    if (DataService.useRemoteApi) return null;

    final db = await DBHelper.database;
    final res = await db.query('usuarios', limit: 1);
    if (res.isNotEmpty) _userId = res.first['id'] as int;
    return _userId;
  }

  Future<void> _iniciarSesion() async {
    final uid = await _resolverUserId();
    if (uid == null) return;
    _inicioSesion = DateTime.now();
    final repeticiones = await DataService.obtenerNumeroRepeticiones(userId: uid);
    setState(() {
      maxAciertos = repeticiones;
    });
    final palabrasSesion = await _obtenerPalabrasSesion(uid);
    final id = await DataService.crearSesionActividad(
      userId: uid,
      actividad: 'aprendizaje',
      inicio: _inicioSesion,
      palabras: palabrasSesion,
    );
    setState(() {
      _sesionId = id;
    });
  }

  Future<List<String>> _obtenerPalabrasSesion(int uid) async {
    final vocabulario = await DataService.obtenerVocabulario(userId: uid);
    return vocabulario
        .take(3)
        .map((e) => (e['label'] ?? '').toString())
        .where((e) => e.isNotEmpty)
        .toList();
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

  int _calcularEstrellas() {
    if (aciertos >= maxAciertos && erroresTotales == 0) return 4;
    if (erroresTotales <= 1) return 3;
    if (erroresTotales <= 3) return 2;
    return 1;
  }

  Future<void> _mostrarModalFinal() async {
    final estrellas = _calcularEstrellas();
    if (!mounted) return;
    return showDialog(
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
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(estrellas, (index) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(Icons.star, color: Colors.amber, size: 36),
                  );
                }),
              ),
              const SizedBox(height: 16),
              Text(
                'Aciertos: $aciertos   Errores: $erroresTotales',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // cierra el modal
                Navigator.of(context).maybePop(); // vuelve al menú previo
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

  Future<void> _registrarEventoPalabra({required bool acierto}) async {
    if (_sesionId == null) return;
    final vocabId = palabraData?['id'] as int?;
    final tiempoMs =
        _inicioPalabra != null ? DateTime.now().difference(_inicioPalabra!).inMilliseconds : null;
    await DataService.registrarDetalleVocabulario(
      sesionId: _sesionId!,
      vocabularioId: vocabId,
      mostrada: true,
      acierto: acierto,
      tiempoMs: tiempoMs,
    );
  }

  List<Map<String, dynamic>> _chunk(int bloque) {
    final start = bloque * 3;
    if (start >= _vocabularioCache.length) return [];
    final end = min(start + 3, _vocabularioCache.length);
    return _vocabularioCache.sublist(start, end);
  }

  Map<String, dynamic>? _pickWeighted(List<Map<String, dynamic>> lista) {
    if (lista.isEmpty) return null;
    final pesos = lista
        .map((e) => ((e['errores'] ?? 0) as int? ?? 0) + 1)
        .toList();
    final total = pesos.reduce((a, b) => a + b);
    var r = _random.nextInt(total);
    for (int i = 0; i < lista.length; i++) {
      r -= pesos[i];
      if (r < 0) return lista[i];
    }
    return lista.last;
  }

  Map<String, dynamic>? _seleccionarPalabra() {
    if (_vocabularioCache.isEmpty) return null;
    final totalBloques = (_vocabularioCache.length / 3).ceil();
    _bloqueActual = min(_bloqueActual, totalBloques - 1);

    final bloqueActual = _chunk(_bloqueActual);
    if (bloqueActual.isEmpty) return null;

    if (_bloqueActual == 0) {
      return _pickWeighted(bloqueActual);
    }

    final bloqueAnterior = _chunk(_bloqueActual - 1);
    final usarActual = _random.nextDouble() < 0.7 || bloqueAnterior.isEmpty;
    if (usarActual) {
      return _pickWeighted(bloqueActual);
    } else {
      final ordenadoPorErrores = [...bloqueAnterior]
        ..sort((a, b) => ((b['errores'] ?? 0) as int).compareTo((a['errores'] ?? 0) as int));
      return _pickWeighted(ordenadoPorErrores);
    }
  }

  Future<void> _cargarPalabra() async {
    _userId ??= await _resolverUserId();

    // Usar DataService en lugar de acceso directo a la BD
    debugPrint('🔍 APRENDIZAJE: Cargando vocabulario para usuario $_userId');
    final resultado = await DataService.obtenerVocabulario(userId: _userId);
    debugPrint('📚 APRENDIZAJE: ${resultado.length} palabras cargadas');

    if (resultado.isEmpty) {
      debugPrint('⚠️ APRENDIZAJE: No hay vocabulario disponible');
      return;
    }
    _vocabularioCache = resultado;

    final seleccion = _seleccionarPalabra();
    if (seleccion == null) return;

    final nombreImagen = (seleccion['nombreImagen'] ?? '') as String;
    ImageProvider? nuevaImagen;
    if (nombreImagen.isNotEmpty) {
      try {
        String? localPath;
        if (!DataService.useRemoteApi) {
          final docDir = await getApplicationDocumentsDirectory();
          localPath = docDir.path;
        }
        nuevaImagen = await DataService.obtenerImageProvider(nombreImagen, localPath: localPath);
      } catch (e) {
        debugPrint('❌ APRENDIZAJE: Error obteniendo ImageProvider: $e');
      }
    }
    setState(() {
      palabraData = seleccion;
      palabraColocada = false;
      indicePalabraColocada = null;
      imageProvider = nuevaImagen;
      errores = 0;
      animandoAutocompletar = false;
      final posiciones = [0, 1, 2];
      posiciones.shuffle();
      posicionCorrecta = posiciones.first;
      _inicioPalabra = DateTime.now();
      _palabrasPresentadas++;
      _bloqueActual = _palabrasPresentadas ~/ 3;
    });
    _animationController.reset();
  }

  Future<void> reproducirSonido(String asset) async {
    await _audioPlayer.stop();
    await _audioPlayer.play(AssetSource(asset));
  }

  void _onAccept(int index, String palabra) async {
    setState(() {
      palabraColocada = true;
      indicePalabraColocada = index;
    });

    if (index == posicionCorrecta) {
      await reproducirSonido('sonidos/applause.mp3');
      setState(() {
        aciertos++;
        errores = 0;
      });
      await _registrarEventoPalabra(acierto: true);
      if (aciertos >= maxAciertos) {
        await _finalizarActividad();
      }
      Future.delayed(const Duration(milliseconds: 1200), () {
        if (mounted && aciertos < maxAciertos) {
          _cargarPalabra();
        }
      });
    } else {
      await reproducirSonido('sonidos/error.mp3');
      setState(() {
        errores++;
        erroresTotales++;
      });
      await _registrarEventoPalabra(acierto: false);

      // Segundo error: ilumina la palabra correcta
      if (errores == 2) setState(() {});
      // Tercer error: difumina las incorrectas
      if (errores == 3) setState(() {});
      // Cuarto error: vuelve la palabra a inicio y anima hacia la tarjeta correcta
      if (errores >= 4) {
        // Primero devuelve la palabra a su posición inicial
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            setState(() {
              palabraColocada = false;
              indicePalabraColocada = null;
              animandoAutocompletar = true;
            });
            // Esperar un frame para que se rendericen los widgets y luego calcular posiciones
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _calcularYAnimarHaciaTarget();
            });
          }
        });
      } else {
        // Espera 1 segundo antes de devolver la palabra a su sitio
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            setState(() {
              palabraColocada = false;
              indicePalabraColocada = null;
            });
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const double alturaPalabra = 60; // Ajusta si tu WordWidget es más alto o bajo

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.home, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'APRENDIZAJE',
          style: TextStyle(color: Colors.white),
        ),
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
            child: palabraData == null
              ? const Center(child: CircularProgressIndicator())
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final nombreImagen = palabraData!['nombreImagen'] ?? '';
                    final palabra = palabraData!['label'] ?? '';
                    final Color bordeTransparente = Colors.transparent;

                    return SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minHeight: constraints.maxHeight),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              BarraProgreso(aciertos: aciertos, maxAciertos: maxAciertos),
                              const SizedBox(height: 32),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(3, (index) {
                                  final esCorrecta = index == posicionCorrecta;
                                  final widget = esCorrecta
                                      ? (errores >= 2
                                          ? DottedBorder(
                                              color: Colors.green,
                                              strokeWidth: 6,
                                              dashPattern: const [10, 5],
                                              borderType: BorderType.RRect,
                                              radius: const Radius.circular(12),
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  borderRadius: BorderRadius.circular(12),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.green.withValues(alpha: 0.5),
                                                      blurRadius: 25,
                                                      spreadRadius: 5,
                                                    ),
                                                  ],
                                                ),
                                                child: TargetCard(
                                                  imageAsset: nombreImagen,
                                                  imageProvider: imageProvider,
                                                  label: palabra,
                                                  borderColor: Colors.transparent,
                                                  droppedChild: (palabraColocada && indicePalabraColocada == index) ? WordWidget(word: palabra) : null,
                                                  onAccept: (_) => _onAccept(index, palabra),
                                                  dropZoneKey: _targetKey,
                                                ),
                                              ),
                                            )
                                          : TargetCard(
                                              imageAsset: nombreImagen,
                                              imageProvider: imageProvider,
                                              label: palabra,
                                              borderColor: Colors.transparent,
                                              droppedChild: (palabraColocada && indicePalabraColocada == index) ? WordWidget(word: palabra) : null,
                                              onAccept: (_) => _onAccept(index, palabra),
                                              dropZoneKey: _targetKey,
                                            ))
                                      : Opacity(
                                          opacity: errores >= 3 ? 0.15 : 1.0,
                                          child: TargetCard(
                                            imageAsset: '',
                                            label: '',
                                            borderColor: bordeTransparente,
                                            droppedChild: (palabraColocada && indicePalabraColocada == index) ? WordWidget(word: palabra) : null,
                                            onAccept: (_) => _onAccept(index, palabra),
                                          ),
                                        );
                                  return Padding(
                                    padding: EdgeInsets.only(right: index < 2 ? 24 : 0),
                                    child: widget,
                                  );
                                }),
                              ),
                              const SizedBox(height: 32),
                              // Palabra draggable debajo (solo si no está colocada)
                              palabraColocada
                                ? const SizedBox(height: alturaPalabra)
                                : animandoAutocompletar
                                    ? SlideTransition(
                                        key: _wordKey,
                                        position: _offsetAnimation,
                                        child: WordWidget(word: palabra),
                                      )
                                    : Draggable<String>(
                                        key: _wordKey,
                                        data: palabra,
                                        feedback: Material(
                                          color: Colors.transparent,
                                          child: WordWidget(word: palabra),
                                        ),
                                        childWhenDragging: Opacity(
                                          opacity: 0.3,
                                          child: WordWidget(word: palabra),
                                        ),
                                        child: WordWidget(word: palabra),
                                      ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
          ),
          ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
            numberOfParticles: 30,
            gravity: 0.5,
          ),
        ],
      ),
    );
  }
}
