import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:leoconlula/widgets/target_silabas.dart';
import 'package:flutter/foundation.dart';
import 'package:leoconlula/services/data_service.dart';
import '../widgets/fondo.dart'; // Importa tu fondo personalizado
import 'package:leoconlula/widgets/barra_progreso.dart';
import 'package:leoconlula/widgets/avatar_usuario.dart';
import 'package:leoconlula/widgets/refuerzo.dart';
import 'package:leoconlula/helpers/db_helper.dart';

class SilabasPage extends StatefulWidget {
  const SilabasPage({super.key});

  @override
  State<SilabasPage> createState() => _SilabasPageState();
}

class _SilabasPageState extends State<SilabasPage> {
  Map<String, dynamic>? palabra;
  List<String> silabas = [];
  List<String?> huecos = [];
  List<String> silabasDisponibles = [];

  int aciertos = 0;
  int maxAciertos = 5;
  int erroresTotales = 0;
  bool _finalizado = false;
  int? _sesionId;
  int? _userId;

  late RefuerzoController refuerzo;
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
    refuerzo = RefuerzoController(confettiController: _confettiController);
    _cargarRepeticiones();
    _cargarPalabra();
  }

  @override
  void dispose() {
    _cerrarSesion(resultado: 'salida');
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _cargarRepeticiones() async {
    final rep = await DataService.obtenerNumeroRepeticiones();
    setState(() {
      maxAciertos = rep;
    });
  }

  Future<void> _cargarPalabra() async {
    final db = await DBHelper.database;
    final resultado = await db.query('vocabulario', limit: 1);
    if (resultado.isNotEmpty) {
      final item = resultado.first;
      final sils = (item['silabas'] as String).split('*');
      await _iniciarSesionSiNoExiste(palabras: [(item['label'] ?? '').toString()]);
      setState(() {
        palabra = item;
        silabas = sils;
        huecos = List<String?>.filled(sils.length > 3 ? 3 : sils.length, null);
        silabasDisponibles = List<String>.from(sils);
        silabasDisponibles.shuffle();
      });
    }
  }

  void _onAccept(int index, String silaba) async {
    setState(() {
      huecos[index] = silaba;
      silabasDisponibles.remove(silaba);
    });

    if (!huecos.contains(null)) {
      final correcto = List.generate(silabas.length > 3 ? 3 : silabas.length, (i) => silabas[i]);
      final usuario = List.generate(huecos.length, (i) => huecos[i]);
      if (listEquals(correcto, usuario)) {
        await refuerzo.reproducirAplauso();
        setState(() {
          aciertos++;
        });
        if (aciertos >= maxAciertos) {
          await _finalizarActividad();
        } else {
          Future.delayed(const Duration(milliseconds: 900), () {
            if (mounted) {
              _cargarPalabra();
            }
          });
        }
      } else {
        await refuerzo.reproducirError();
        erroresTotales++;
        Future.delayed(const Duration(seconds: 1), () {
          setState(() {
            silabasDisponibles = List<String>.from(silabas);
            silabasDisponibles.shuffle();
            huecos = List<String?>.filled(silabas.length > 3 ? 3 : silabas.length, null);
          });
        });
      }
    }
  }

  void mostrarDialogoVictoria() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('¡Victoria!'),
          content: const Text('Has completado todos los aciertos.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  aciertos = 0;
                });
                _cargarPalabra();
              },
              child: const Text('Aceptar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> reproducirSonido(String asset) async {
    // Implementa la reproducción de sonido aquí si es necesario
  }

  @override
  Widget build(BuildContext context) {
    if (palabra == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    final nombreImagen = palabra!['nombreImagen'] ?? '';
    final label = palabra!['label'] ?? '';

    // Define alturaDraggable at the top of the build method
    const double alturaDraggable = 80; // Ajusta según tu Card

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.home, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text('Actividad: Sílabas'),
        backgroundColor: const Color.fromRGBO(63, 46, 31, 1),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: AvatarUsuario(), // O AvatarUsuario(userId: tuId)
          ),
        ],
      ),
      body: BackgroundContainer(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Stack(
            alignment: Alignment.topCenter,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  BarraProgreso(aciertos: aciertos, maxAciertos: maxAciertos),
                  TargetSilabas(
                    imageAsset: nombreImagen,
                    palabra: label,
                    huecos: huecos,
                    onAccept: _onAccept,
                  ),
                  const SizedBox(height: 32),
                  silabasDisponibles.isEmpty
                      ? SizedBox(height: alturaDraggable)
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: silabasDisponibles
                              .map((s) => Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 8),
                                    child: Draggable<String>(
                                      data: s,
                                      feedback: Material(
                                        color: Colors.transparent,
                                        child: Card(
                                          color: Colors.white,
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                                            child: Text(
                                              s,
                                              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                        ),
                                      ),
                                      childWhenDragging: Opacity(
                                        opacity: 0.3,
                                        child: Card(
                                          color: Colors.white,
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                                            child: Text(
                                              s,
                                              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                        ),
                                      ),
                                      child: Card(
                                        color: Colors.white,
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                                          child: Text(
                                            s,
                                            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ))
                              .toList(),
                        ),
                ],
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
      ),
    );
  }

  Future<void> _iniciarSesionSiNoExiste({List<String>? palabras}) async {
    if (_sesionId != null) return;
    _userId ??= await _resolverUserId();
    if (_userId == null) return;
    _sesionId = await DataService.crearSesionActividad(
      userId: _userId!,
      actividad: 'silabas',
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
