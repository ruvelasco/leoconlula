import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:leoconlula/widgets/fondo.dart';
import 'package:leoconlula/widgets/target_silabas.dart';
import 'package:leoconlula/services/data_service.dart';
import 'package:leoconlula/widgets/barra_progreso.dart';
import 'package:leoconlula/widgets/avatar_usuario.dart';
import 'package:leoconlula/widgets/refuerzo.dart';
import 'package:leoconlula/helpers/db_helper.dart';

class SilabasOrdenDistraccionPage extends StatefulWidget {
  final int? userId;

  const SilabasOrdenDistraccionPage({super.key, this.userId});

  @override
  State<SilabasOrdenDistraccionPage> createState() => _SilabasOrdenDistraccionPageState();
}

class _SilabasOrdenDistraccionPageState extends State<SilabasOrdenDistraccionPage> {
  Map<String, dynamic>? palabra;
  List<String> silabas = [];
  List<String?> huecos = [];
  List<String> silabasDisponibles = [];
  List<Map<String, dynamic>> palabrasDisponibles = [];

  int aciertos = 0;
  int maxAciertos = 5;
  int erroresTotales = 0;
  bool _finalizado = false;
  int? _sesionId;
  int? _userId;

  late RefuerzoController refuerzo;
  late ConfettiController _confettiController;

  // Sílabas comunes en español para usar como distracción
  final List<String> silabasDistraccion = [
    'ma', 'me', 'mi', 'mo', 'mu',
    'pa', 'pe', 'pi', 'po', 'pu',
    'sa', 'se', 'si', 'so', 'su',
    'ta', 'te', 'ti', 'to', 'tu',
    'la', 'le', 'li', 'lo', 'lu',
    'ra', 're', 'ri', 'ro', 'ru',
    'ca', 'co', 'cu', 'que', 'qui',
    'ga', 'go', 'gu', 'gue', 'gui',
    'na', 'ne', 'ni', 'no', 'nu',
    'da', 'de', 'di', 'do', 'du',
    'ba', 'be', 'bi', 'bo', 'bu',
    'cha', 'che', 'chi', 'cho', 'chu',
    'ja', 'je', 'ji', 'jo', 'ju',
    'ña', 'ñe', 'ñi', 'ño', 'ñu',
    'va', 've', 'vi', 'vo', 'vu',
    'za', 'ce', 'ci', 'zo', 'zu',
    'fa', 'fe', 'fi', 'fo', 'fu',
    'lla', 'lle', 'lli', 'llo', 'llu',
  ];

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
    _userId ??= widget.userId ?? await _resolverUserId();
    debugPrint('🔍 SILABAS_ORDEN_DISTRACCION: Cargando vocabulario para usuario $_userId');

    // Si no hay palabras disponibles, cargar todas
    if (palabrasDisponibles.isEmpty) {
      final resultado = await DataService.obtenerVocabulario(userId: _userId);
      debugPrint('📚 SILABAS_ORDEN_DISTRACCION: ${resultado.length} palabras cargadas desde API/DB');

      // Filtrar solo palabras que tengan sílabas definidas
      palabrasDisponibles = resultado.where((item) {
        final silabas = item['silabas'];
        return silabas != null && silabas.toString().isNotEmpty;
      }).toList();

      debugPrint('📚 SILABAS_ORDEN_DISTRACCION: ${palabrasDisponibles.length} palabras con sílabas disponibles');
      palabrasDisponibles.shuffle();
    }

    if (palabrasDisponibles.isEmpty) {
      debugPrint('❌ SILABAS_ORDEN_DISTRACCION: No hay palabras con sílabas disponibles');
      return;
    }

    // Tomar la primera palabra disponible y removerla
    final item = palabrasDisponibles.removeAt(0);
    debugPrint('✅ SILABAS_ORDEN_DISTRACCION: Cargando palabra: ${item['label']}, silabas="${item['silabas']}"');

    final silabasString = item['silabas']?.toString() ?? '';
    final sils = silabasString.split('*').where((s) => s.isNotEmpty).toList();

    if (sils.isEmpty) {
      debugPrint('⚠️ SILABAS_ORDEN_DISTRACCION: La palabra ${item['label']} no tiene sílabas válidas, saltando...');
      _cargarPalabra(); // Intentar con la siguiente palabra
      return;
    }

    await _iniciarSesionSiNoExiste(palabras: [(item['label'] ?? '').toString()]);

    // Obtener 3 sílabas de distracción que NO estén en la palabra
    final silabasExtra = _obtenerSilabasDistraccion(sils, 3);

    setState(() {
      palabra = item;
      silabas = sils;
      huecos = List<String?>.filled(sils.length > 3 ? 3 : sils.length, null);

      // Combinar sílabas correctas con las de distracción
      silabasDisponibles = [...sils, ...silabasExtra];
      silabasDisponibles.shuffle();
    });
  }

  /// Obtiene [cantidad] sílabas de distracción que NO estén en [silabasCorrectas]
  List<String> _obtenerSilabasDistraccion(List<String> silabasCorrectas, int cantidad) {
    final disponibles = silabasDistraccion.where((s) => !silabasCorrectas.contains(s)).toList();
    disponibles.shuffle();
    return disponibles.take(cantidad).toList();
  }

  // Solo permite colocar la sílaba correcta en el hueco correspondiente y en orden
  void _onAccept(int index, String silaba) async {
    // Solo permite colocar si todos los huecos anteriores están completos y correctos
    bool puedeColocar = true;
    for (int i = 0; i < index; i++) {
      if (huecos[i] != silabas[i]) {
        puedeColocar = false;
        break;
      }
    }
    if (!puedeColocar || silaba != silabas[index]) {
      await refuerzo.reproducirError();
      erroresTotales++;
      return;
    }

    setState(() {
      huecos[index] = silaba;
      silabasDisponibles.remove(silaba);
    });

    if (!huecos.contains(null)) {
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
    }
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
    const double alturaDraggable = 80;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.home, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text('Sílabas en orden (con distracción)'),
        backgroundColor: const Color.fromRGBO(63, 46, 31, 1),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: AvatarUsuario(),
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
                  // TargetSilabas con huecoBuilder para mostrar en gris los huecos no activos
                  TargetSilabas(
                    imageAsset: nombreImagen,
                    palabra: label,
                    huecos: huecos,
                    onAccept: _onAccept,
                    huecoBuilder: (context, index, child) {
                      // Si el hueco anterior no está bien o ya está relleno, lo ponemos gris
                      bool esActivo = true;
                      for (int i = 0; i < index; i++) {
                        if (huecos[i] != silabas[i]) {
                          esActivo = false;
                          break;
                        }
                      }
                      bool yaRelleno = huecos[index] != null;
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: (!esActivo || yaRelleno) ? Colors.grey[300] : Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        width: 62,
                        height: 60,
                        child: Center(child: child),
                      );
                    },
                  ),
                  const SizedBox(height: 32),
                  silabasDisponibles.isEmpty
                      ? SizedBox(height: alturaDraggable)
                      : Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 8,
                          runSpacing: 8,
                          children: silabasDisponibles.map((s) => Draggable<String>(
                            data: s,
                            feedback: Material(
                              color: Colors.transparent,
                              child: Card(
                                color: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
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
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                                child: Text(
                                  s,
                                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          )).toList(),
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
    _userId ??= widget.userId ?? await _resolverUserId();
    if (_userId == null) return;
    _sesionId = await DataService.crearSesionActividad(
      userId: _userId!,
      actividad: 'silabas_distrac',
      inicio: DateTime.now(),
      palabras: palabras,
    );
  }

  Future<int?> _resolverUserId() async {
    // En modo remoto, requiere userId como parámetro
    if (DataService.useRemoteApi) return null;

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
