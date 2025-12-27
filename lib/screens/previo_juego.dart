import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:leoconlula/services/data_service.dart';
import 'package:flutter/material.dart';
import 'package:leoconlula/widgets/fondo.dart';
import 'discriminacion.dart';
import 'package:leoconlula/screens/configuracion_usuario.dart';
import 'discriminacion_inversa.dart';
import 'silabas.dart';
import 'aprendizaje.dart';
import '../screens/imagenes_arrastre.dart';
import '../screens/dos_imagenes_arrastre.dart' as doble_arrastre;
import '../screens/silabas_orden.dart';
import '../screens/silabas_orden_distraccion.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:leoconlula/helpers/db_helper.dart';

class PrevioJuegoPage extends StatefulWidget {
  final int userId;
  final String userName;

  const PrevioJuegoPage({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  State<PrevioJuegoPage> createState() => _PrevioJuegoPageState();
}

class _PrevioJuegoPageState extends State<PrevioJuegoPage> {
  String? fotoPath;
  List<List<Map<String, dynamic>>> tarjetasVocabulario = [];
  int tarjetaActual = 0;
  Map<String, bool> actividadesCompletadas = {};
  bool bloqueAnteriorCompletado = true;
  List<String> ordenActividades = [];
  List<String> actividadesHabilitadas = [];
  bool bloqueoActividades = false; // Opción para habilitar/deshabilitar bloqueo
  final CarouselSliderController _carouselController = CarouselSliderController();

  @override
  void initState() {
    super.initState();
    _cargarFotoUsuario();
    _cargarVocabulario();
    _cargarConfiguracionActividades();
  }

  Future<void> _cargarFotoUsuario() async {
    try {
      final usuarios = await DataService.obtenerUsuarios();
      final usuario = usuarios.firstWhere(
        (u) => u['id'] == widget.userId,
        orElse: () => <String, dynamic>{},
      );

      if (usuario.isNotEmpty && usuario['foto'] != null) {
        final foto = usuario['foto'] as String;

        // Si es una URL, usarla directamente
        if (foto.startsWith('http://') || foto.startsWith('https://')) {
          setState(() {
            fotoPath = foto;
          });
        } else if (!DataService.useRemoteApi) {
          // Solo acceder a archivos locales en modo no-remoto
          final dir = await getApplicationDocumentsDirectory();
          setState(() {
            fotoPath = '${dir.path}/$foto';
          });
        }
      }
    } catch (e) {
      debugPrint('Error al cargar foto de usuario: $e');
    }
  }

  Future<void> _cargarVocabulario() async {
    try {
      // Usar DataService para que funcione tanto en local como en remoto
      debugPrint(
          '🔍 PREVIO_JUEGO: Cargando vocabulario para usuario ${widget.userId}...');
      debugPrint('🔍 PREVIO_JUEGO: userId type: ${widget.userId.runtimeType}');
      debugPrint('🔍 PREVIO_JUEGO: useRemoteApi: ${DataService.useRemoteApi}');
      final resultado =
          await DataService.obtenerVocabulario(userId: widget.userId);
      debugPrint('📚 Vocabulario obtenido: ${resultado.length} palabras');

      if (resultado.isEmpty) {
        debugPrint('⚠️ No hay vocabulario para este usuario');
      }

      // Agrupar palabras de 3 en 3
      List<List<Map<String, dynamic>>> grupos = [];
      for (int i = 0; i < resultado.length; i += 3) {
        final grupo = resultado.skip(i).take(3).toList();
        grupos.add(grupo);
      }

      debugPrint('📋 Grupos creados: ${grupos.length} tarjetas');
      setState(() {
        tarjetasVocabulario = grupos;
      });
    } catch (e) {
      debugPrint('❌ Error al cargar vocabulario: $e');
      setState(() {
        tarjetasVocabulario =
            []; // Asegurar que no se quede en loading infinito
      });
    }
  }

  Future<void> _cargarConfiguracionActividades() async {
    final orden = await DataService.obtenerOrdenActividades(widget.userId);
    final habilitadas =
        await DataService.obtenerActividadesHabilitadas(widget.userId);
    final bloqueo = await DataService.obtenerBloqueoActividades(userId: widget.userId);
    print('🔧 Orden cargado: $orden');
    print('🔧 Habilitadas cargadas: $habilitadas');
    print('🔒 Bloqueo de actividades: $bloqueo');
    setState(() {
      ordenActividades = orden;
      actividadesHabilitadas = habilitadas;
      bloqueoActividades = bloqueo;
    });
    _cargarProgresoActividades();
  }

  /// Verifica si el bloque actual tiene todas las actividades habilitadas completadas
  bool _bloqueActualCompleto() {
    if (!bloqueoActividades) return true; // Si no hay bloqueo, siempre está completo

    // Obtener actividades requeridas
    final actividadesRequeridas = actividadesHabilitadas.isNotEmpty
        ? actividadesHabilitadas
        : [
            'aprendizaje',
            'discriminacion',
            'discriminacion_inversa',
            'silabas',
            'arrastre',
            'doble',
            'silabas_orden',
            'silabas_distrac',
          ];

    // Verificar si todas están completadas
    return actividadesRequeridas.every((act) => actividadesCompletadas[act] == true);
  }

  Future<void> _cargarProgresoActividades() async {
    // En modo remoto, si el bloqueo está desactivado, permitir acceso a todo
    if (DataService.useRemoteApi) {
      if (!bloqueoActividades) {
        setState(() {
          actividadesCompletadas = {}; // Sin restricciones
          bloqueAnteriorCompletado = true;
        });
        return;
      }

      // Obtener las palabras del bloque actual
      final palabrasBloqueActual = tarjetaActual < tarjetasVocabulario.length
          ? tarjetasVocabulario[tarjetaActual]
              .map((p) => (p['label'] ?? '').toString())
              .toSet()
          : <String>{};

      debugPrint('🔍 BLOQUEO: Cargando sesiones para bloque $tarjetaActual');
      debugPrint('🔍 BLOQUEO: Palabras del bloque actual: $palabrasBloqueActual');

      // Obtener sesiones completadas desde la API
      final sesiones = await DataService.obtenerSesiones(userId: widget.userId);
      final sesionesCompletadas = sesiones.where((s) => s['resultado'] == 'completada').toList();

      debugPrint('🔍 BLOQUEO: Total sesiones: ${sesiones.length}, completadas: ${sesionesCompletadas.length}');

      final mapa = <String, bool>{};

      for (final sesion in sesionesCompletadas) {
        final act = (sesion['actividad'] ?? '').toString();
        if (act.isEmpty) continue;

        final p1 = (sesion['palabra1'] ?? '').toString();
        final p2 = (sesion['palabra2'] ?? '').toString();
        final p3 = (sesion['palabra3'] ?? '').toString();

        debugPrint('🔍 BLOQUEO: Sesión - actividad: $act, palabras: [$p1, $p2, $p3]');

        // Verificar si pertenece al bloque actual
        bool perteneceAlBloqueActual = false;
        if (p1.isNotEmpty && palabrasBloqueActual.contains(p1)) {
          perteneceAlBloqueActual = true;
          debugPrint('   ✓ Palabra1 "$p1" pertenece al bloque actual');
        }
        if (p2.isNotEmpty && palabrasBloqueActual.contains(p2)) {
          perteneceAlBloqueActual = true;
          debugPrint('   ✓ Palabra2 "$p2" pertenece al bloque actual');
        }
        if (p3.isNotEmpty && palabrasBloqueActual.contains(p3)) {
          perteneceAlBloqueActual = true;
          debugPrint('   ✓ Palabra3 "$p3" pertenece al bloque actual');
        }

        if (perteneceAlBloqueActual) {
          mapa[act] = true;
          debugPrint('   ✅ Actividad "$act" marcada como completada');
        } else {
          debugPrint('   ❌ Sesión no pertenece al bloque actual');
        }
      }

      debugPrint('🔍 BLOQUEO: ========================================');
      debugPrint('🔍 BLOQUEO: RESUMEN - Actividades completadas: $mapa');
      debugPrint('🔍 BLOQUEO: Actividades habilitadas: $actividadesHabilitadas');
      debugPrint('🔍 BLOQUEO: ========================================');

      setState(() {
        actividadesCompletadas = mapa;
        bloqueAnteriorCompletado = true;
      });
      return;
    }

    final db = await DBHelper.database;

    // Obtener las palabras del bloque actual (tarjeta actual)
    final palabrasBloqueActual = tarjetaActual < tarjetasVocabulario.length
        ? tarjetasVocabulario[tarjetaActual]
            .map((p) => (p['label'] ?? '').toString())
            .toSet()
        : <String>{};

    // Obtener las palabras del bloque anterior
    final palabrasBloqueAnterior = tarjetaActual > 0
        ? tarjetasVocabulario[tarjetaActual - 1]
            .map((p) => (p['label'] ?? '').toString())
            .toSet()
        : <String>{};

    // Obtener sesiones completadas del usuario
    final res = await db.query(
      'actividad_sesiones',
      columns: ['actividad', 'resultado', 'palabra1', 'palabra2', 'palabra3'],
      where: "user_id = ? AND resultado = 'completada'",
      whereArgs: [widget.userId],
    );

    final mapa = <String, bool>{};
    final actividadesBloqueAnterior = <String, bool>{};

    for (final fila in res) {
      final act = (fila['actividad'] ?? '').toString();
      if (act.isEmpty) continue;

      final p1 = (fila['palabra1'] ?? '').toString();
      final p2 = (fila['palabra2'] ?? '').toString();
      final p3 = (fila['palabra3'] ?? '').toString();

      // Verificar si pertenece al bloque actual
      bool perteneceAlBloqueActual = false;
      if (p1.isNotEmpty && palabrasBloqueActual.contains(p1))
        perteneceAlBloqueActual = true;
      if (p2.isNotEmpty && palabrasBloqueActual.contains(p2))
        perteneceAlBloqueActual = true;
      if (p3.isNotEmpty && palabrasBloqueActual.contains(p3))
        perteneceAlBloqueActual = true;

      if (perteneceAlBloqueActual) {
        mapa[act] = true;
      }

      // Verificar si pertenece al bloque anterior
      if (tarjetaActual > 0) {
        bool perteneceAlBloqueAnterior = false;
        if (p1.isNotEmpty && palabrasBloqueAnterior.contains(p1))
          perteneceAlBloqueAnterior = true;
        if (p2.isNotEmpty && palabrasBloqueAnterior.contains(p2))
          perteneceAlBloqueAnterior = true;
        if (p3.isNotEmpty && palabrasBloqueAnterior.contains(p3))
          perteneceAlBloqueAnterior = true;

        if (perteneceAlBloqueAnterior) {
          actividadesBloqueAnterior[act] = true;
        }
      }
    }

    // Verificar si todas las actividades habilitadas del bloque anterior están completadas
    // Si no hay actividades habilitadas aún, usar todas por defecto
    final actividadesRequeridas = actividadesHabilitadas.isNotEmpty
        ? actividadesHabilitadas
        : [
            'aprendizaje',
            'discriminacion',
            'discriminacion_inversa',
            'silabas',
            'arrastre',
            'doble',
            'silabas_orden',
            'silabas_distrac',
          ];

    bool bloqueAnteriorCompleto = tarjetaActual == 0;
    if (tarjetaActual > 0) {
      bloqueAnteriorCompleto = actividadesRequeridas
          .every((act) => actividadesBloqueAnterior[act] == true);
      print(
          '🔒 Bloque $tarjetaActual - Actividades requeridas: $actividadesRequeridas');
      print('🔒 Completadas en bloque anterior: $actividadesBloqueAnterior');
      print('🔒 ¿Bloque anterior completo?: $bloqueAnteriorCompleto');
    }

    setState(() {
      actividadesCompletadas = mapa;
      bloqueAnteriorCompletado = bloqueAnteriorCompleto;
    });
  }

  @override
  Widget build(BuildContext context) {
    final double anchoPantalla = MediaQuery.of(context).size.width;
    final double altoPantalla = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.home, color: Colors.white, size: 32),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          widget.userName.toUpperCase(),
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color.fromRGBO(63, 46, 31, 1),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: CircleAvatar(
              radius: 20,
              backgroundColor: Colors.white,
              child: CircleAvatar(
                radius: 18,
                backgroundImage:
                    (fotoPath != null && File(fotoPath!).existsSync())
                        ? FileImage(File(fotoPath!))
                        : const AssetImage('assets/images/lula.png')
                            as ImageProvider,
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Transform.translate(
        offset: const Offset(20, 20),
        child: FloatingActionButton(
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    ConfiguracionUsuarioPage(userId: widget.userId),
              ),
            );
            // Recargar configuración después de volver de configuración
            _cargarConfiguracionActividades();
          },
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: const Icon(
            Icons.settings,
            color: Color.fromRGBO(63, 46, 31, 1),
            size: 62,
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: BackgroundContainer(
        child: tarjetasVocabulario.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.library_books,
                        size: 80, color: Color.fromRGBO(63, 46, 31, 0.5)),
                    const SizedBox(height: 20),
                    Text(
                      'No hay vocabulario para este usuario',
                      style: TextStyle(
                        fontSize: 20,
                        color: const Color.fromRGBO(63, 46, 31, 1),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Agrega palabras en la sección de Vocabulario',
                      style: TextStyle(
                        fontSize: 16,
                        color: const Color.fromRGBO(63, 46, 31, 0.7),
                      ),
                    ),
                  ],
                ),
              )
            : Column(
                children: [
                  const SizedBox(height: 20),
                  // Carrusel de tarjetas
                  Expanded(
                    child: CarouselSlider.builder(
                      carouselController: _carouselController,
                      itemCount: tarjetasVocabulario.length,
                      itemBuilder: (context, index, realIndex) {
                        return _buildTarjetaVocabulario(
                          tarjetasVocabulario[index],
                          anchoPantalla,
                          altoPantalla,
                          index,
                        );
                      },
                      options: CarouselOptions(
                        height: altoPantalla * 0.85,
                        viewportFraction: 0.6,
                        enlargeCenterPage: true,
                        enableInfiniteScroll: false,
                        onPageChanged: (index, reason) async {
                          // Si el bloqueo está activado y intentan avanzar sin completar
                          if (bloqueoActividades &&
                              reason == CarouselPageChangedReason.manual &&
                              index > tarjetaActual &&
                              !_bloqueActualCompleto()) {
                            // Mostrar mensaje de advertencia
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Row(
                                  children: [
                                    Icon(Icons.lock, color: Colors.white),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Completa todas las actividades de este bloque primero',
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                                backgroundColor: Colors.orange[700],
                                duration: const Duration(seconds: 2),
                              ),
                            );
                            // Volver a la tarjeta actual
                            await Future.delayed(const Duration(milliseconds: 100));
                            _carouselController.animateToPage(
                              tarjetaActual,
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                            return;
                          }

                          setState(() {
                            tarjetaActual = index;
                          });
                          _cargarProgresoActividades();
                        },
                      ),
                    ),
                  ),
                  // Indicador de página
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        tarjetasVocabulario.length,
                        (index) {
                          // Determinar si este bloque está bloqueado
                          final bloqueEstaBloqueado = bloqueoActividades &&
                              index > tarjetaActual &&
                              !_bloqueActualCompleto();

                          return Container(
                            width: tarjetaActual == index ? 12 : 8,
                            height: tarjetaActual == index ? 12 : 8,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: tarjetaActual == index
                                  ? const Color.fromRGBO(63, 46, 31, 1)
                                  : bloqueEstaBloqueado
                                      ? Colors.grey[300]
                                      : Colors.grey[400],
                              border: bloqueEstaBloqueado
                                  ? Border.all(
                                      color: Colors.grey[400]!,
                                      width: 1,
                                    )
                                  : null,
                            ),
                            child: bloqueEstaBloqueado
                                ? const Center(
                                    child: Icon(
                                      Icons.lock,
                                      size: 6,
                                      color: Colors.grey,
                                    ),
                                  )
                                : null,
                          );
                        },
                      ),
                    ),
                  ),
                  // Mensaje de advertencia si el bloque anterior no está completo
                  if (!bloqueAnteriorCompletado && tarjetaActual > 0)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange[100],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange, width: 2),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.lock,
                                color: Colors.orange[700], size: 20),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                'Completa todas las actividades del bloque anterior para desbloquear este bloque',
                                style: TextStyle(
                                  color: Colors.orange[900],
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
      ),
    );
  }

  Widget _buildTarjetaVocabulario(
    List<Map<String, dynamic>> palabras,
    double anchoPantalla,
    double altoPantalla,
    int indiceTarjeta,
  ) {
    // Solo mostrar botones activos si es la tarjeta actual
    final bool esTarjetaActual = indiceTarjeta == tarjetaActual;

    // Determinar si esta tarjeta está bloqueada (tarjetas futuras cuando bloqueo activado)
    final bool bloqueEstaBloqueado = bloqueoActividades &&
        indiceTarjeta > tarjetaActual &&
        !_bloqueActualCompleto();

    return Stack(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color.fromRGBO(63, 46, 31, 1),
              width: 10,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            children: [
              // Sección de palabras (3 palabras)
              Expanded(
                flex: 1,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  child: _buildPalabrasRow(palabras),
                ),
              ),
              // Divisor
              Divider(color: Colors.grey[300], thickness: 2, height: 2),
              // Sección de actividades
              Expanded(
                flex: 4,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  child: GridView.count(
                    crossAxisCount: 3,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.2,
                    children: _buildActividades(context, esTarjetaActual),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Overlay de bloqueo para bloques futuros no completados
        if (bloqueEstaBloqueado)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.lock,
                    size: 80,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      'Completa el bloque anterior',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildActividadButton(
    String titulo,
    IconData icono,
    Color color,
    VoidCallback? onTap, {
    double iconSize = 36,
    double textSize = 11,
    bool habilitado = true,
  }) {
    final Color fillColor = habilitado ? color : Colors.grey[600]!;
    return Material(
      color: fillColor,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: habilitado ? onTap : null,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icono, color: Colors.white, size: iconSize),
            const SizedBox(height: 4),
            Text(
              titulo,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: textSize,
              ),
              textAlign: TextAlign.center,
            ),
            if (!habilitado)
              const Padding(
                padding: EdgeInsets.only(top: 2),
                child: Text(
                  'Completa la anterior',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildActividades(BuildContext context, bool esTarjetaActual) {
    const marron = Color.fromRGBO(63, 46, 31, 1);

    // Definir todas las actividades posibles
    final todasActividades = {
      'aprendizaje': (
        titulo: 'APRENDIZAJE',
        icono: Icons.school,
        builder: () => AprendizajePage(userId: widget.userId),
      ),
      'discriminacion': (
        titulo: 'DISCRIMINACIÓN',
        icono: Icons.compare_arrows,
        builder: () => DemoDragTarget(key: UniqueKey(), userId: widget.userId),
      ),
      'discriminacion_inversa': (
        titulo: 'DISC. INVERSA',
        icono: Icons.swap_horiz,
        builder: () => DiscriminacionInversa(key: UniqueKey(), userId: widget.userId),
      ),
      'silabas': (
        titulo: 'SÍLABAS',
        icono: Icons.text_fields,
        builder: () => SilabasPage(key: UniqueKey(), userId: widget.userId),
      ),
      'arrastre': (
        titulo: 'ARRASTRE',
        icono: Icons.touch_app,
        builder: () => ImagenArrastrePage(key: UniqueKey(), userId: widget.userId),
      ),
      'doble': (
        titulo: 'DOBLE',
        icono: Icons.format_list_bulleted,
        builder: () => doble_arrastre.DobleArrastrePage(key: UniqueKey(), userId: widget.userId),
      ),
      'silabas_orden': (
        titulo: 'S. ORDEN',
        icono: Icons.sort,
        builder: () => SilabasOrdenPage(key: UniqueKey(), userId: widget.userId),
      ),
      'silabas_distrac': (
        titulo: 'S. DISTRAC.',
        icono: Icons.psychology,
        builder: () => SilabasOrdenDistraccionPage(key: UniqueKey(), userId: widget.userId),
      ),
    };

    // Usar el orden configurado, o el orden por defecto si no está cargado
    final ordenAUsar = ordenActividades.isNotEmpty
        ? ordenActividades
        : todasActividades.keys.toList();

    // Filtrar solo las actividades habilitadas
    final actividadesAMostrar = ordenAUsar
        .where((clave) =>
            actividadesHabilitadas.isEmpty ||
            actividadesHabilitadas.contains(clave))
        .toList();

    debugPrint('🎮 ======================================== ');
    debugPrint('🎮 EVALUANDO ACTIVIDADES');
    debugPrint('🎮 Total actividades configuradas: ${ordenAUsar.length}');
    debugPrint('🎮 Actividades a mostrar (filtradas): ${actividadesAMostrar.length}');
    debugPrint('🎮 Lista de actividades a mostrar: $actividadesAMostrar');
    debugPrint('🎮 Actividades completadas MAP: $actividadesCompletadas');
    debugPrint('🎮 Es tarjeta actual: $esTarjetaActual');
    debugPrint('🎮 Bloqueo activado: $bloqueoActividades');
    debugPrint('🎮 ======================================== ');

    final List<Widget> botones = [];
    for (var i = 0; i < actividadesAMostrar.length; i++) {
      final clave = actividadesAMostrar[i];
      final actividad = todasActividades[clave];

      if (actividad == null) continue;

      final actividadPrevia = i > 0 ? actividadesAMostrar[i - 1] : null;
      final previaCompletada = i == 0
          ? true
          : (actividadesCompletadas[actividadPrevia] ?? false);

      // Determinar si la actividad está habilitada basado en la configuración
      final estaHabilitado = !bloqueoActividades || // Si el bloqueo está deshabilitado, todas están abiertas
          !esTarjetaActual || // Si no es la tarjeta actual, no aplicar restricciones
          i == 0 || // Primera actividad siempre está disponible
          previaCompletada; // O si la anterior está completada

      debugPrint('');
      debugPrint('🔍 Evaluando actividad $i: "$clave"');
      debugPrint('   - Actividad previa: ${actividadPrevia ?? "N/A"}');
      debugPrint('   - ¿Previa completada?: $previaCompletada');
      if (actividadPrevia != null) {
        debugPrint('   - Estado en mapa de previa "$actividadPrevia": ${actividadesCompletadas[actividadPrevia]}');
      }
      debugPrint('   - ¿Bloqueo activado?: $bloqueoActividades');
      debugPrint('   - ¿Es tarjeta actual?: $esTarjetaActual');
      debugPrint('   - ¿Es primera (i==0)?: ${i == 0}');
      debugPrint('   - RESULTADO FINAL - ¿HABILITADO?: $estaHabilitado');

      botones.add(
        _buildActividadButton(
          actividad.titulo,
          actividad.icono,
          marron,
          estaHabilitado
              ? () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => actividad.builder()),
                  ).then((_) => _cargarProgresoActividades())
              : null,
          iconSize: 84,
          textSize: 24,
          habilitado: estaHabilitado,
        ),
      );
    }
    return botones;
  }

  /// Construye la fila de 3 palabras de vocabulario
  Widget _buildPalabrasRow(List<Map<String, dynamic>> palabras) {
    const navColor = Color.fromRGBO(63, 46, 31, 1);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        if (index < palabras.length) {
          final palabra = palabras[index];
          final nombreImagen = palabra['nombreImagen'] ?? '';
          debugPrint(
              '🎯 Construyendo tarjeta ${index + 1}: "${palabra['label']}" con imagen "$nombreImagen"');

          return Container(
            width: 95,
            margin: const EdgeInsets.symmetric(horizontal: 6),
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: navColor, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (nombreImagen.isNotEmpty)
                  SizedBox(
                    height: 70,
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: _buildVocabularioImageSmart(nombreImagen),
                    ),
                  ),
                const SizedBox(height: 6),
                Text(
                  (palabra['label'] ?? '').toString().toUpperCase(),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: navColor,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          );
        } else {
          return const SizedBox(width: 95);
        }
      }),
    );
  }

  /// Construye el widget de imagen - detecta automáticamente si es URL o archivo local
  Widget _buildVocabularioImageSmart(String nombreImagen) {
    debugPrint(
        '🖼️ _buildVocabularioImageSmart llamado: nombreImagen="$nombreImagen"');

    // Si nombreImagen es una URL (modo remoto), usar Image.network directamente
    if (nombreImagen.startsWith('http://') ||
        nombreImagen.startsWith('https://')) {
      debugPrint('🖼️ Usando Image.network para: $nombreImagen');
      return Image.network(
        nombreImagen,
        fit: BoxFit.contain,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) {
            debugPrint('✅ Imagen cargada: $nombreImagen');
            return child;
          }
          debugPrint(
              '⏳ Cargando imagen: ${loadingProgress.cumulativeBytesLoaded}/${loadingProgress.expectedTotalBytes ?? "?"}');
          return const Center(
            child: SizedBox(
              width: 30,
              height: 30,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          debugPrint('❌ Error cargando imagen $nombreImagen: $error');
          return const Icon(Icons.broken_image, size: 50, color: Colors.red);
        },
      );
    } else {
      // En web con API remota, no tenemos acceso a archivos locales
      if (kIsWeb && DataService.useRemoteApi) {
        debugPrint('⚠️ Web + API remota: no se puede cargar imagen local');
        return const Icon(Icons.image_not_supported, size: 50, color: Colors.grey);
      }

      // Si es modo local no-web, necesitamos usar FutureBuilder para obtener la ruta
      if (!kIsWeb) {
        debugPrint('🖼️ Modo local - usando FutureBuilder para obtener ruta');
        return FutureBuilder<Directory>(
          future: getApplicationDocumentsDirectory(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              debugPrint('❌ Error obteniendo directorio: ${snapshot.error}');
              return const Icon(Icons.error, size: 50, color: Colors.orange);
            }
            if (!snapshot.hasData) {
              return const Center(
                child: SizedBox(
                  width: 30,
                  height: 30,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              );
            }
            final filePath = '${snapshot.data!.path}/vocabulario/$nombreImagen';
            debugPrint('🖼️ Cargando imagen local desde: $filePath');
            return Image.file(
              File(filePath),
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                debugPrint('❌ Error cargando archivo $filePath: $error');
                return const Icon(Icons.broken_image,
                    size: 50, color: Colors.red);
              },
            );
          },
        );
      }

      // Fallback
      return const Icon(Icons.image, size: 50, color: Colors.grey);
    }
  }
}
