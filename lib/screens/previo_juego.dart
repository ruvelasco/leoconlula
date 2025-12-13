import 'dart:io';
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

  @override
  void initState() {
    super.initState();
    _cargarFotoUsuario();
    _cargarVocabulario();
    _cargarConfiguracionActividades();
  }

  Future<void> _cargarFotoUsuario() async {
    final db = await DBHelper.database;
    final resultado = await db.query(
      'usuarios',
      where: 'id = ?',
      whereArgs: [widget.userId],
    );
    if (resultado.isNotEmpty && resultado.first['foto'] != null) {
      final foto = resultado.first['foto'] as String;
      final dir = await getApplicationDocumentsDirectory();
      setState(() {
        fotoPath = '${dir.path}/$foto';
      });
    }
  }

  Future<void> _cargarVocabulario() async {
    try {
      // Usar DataService para que funcione tanto en local como en remoto
      debugPrint('🔍 PREVIO_JUEGO: Cargando vocabulario para usuario ${widget.userId}...');
      debugPrint('🔍 PREVIO_JUEGO: userId type: ${widget.userId.runtimeType}');
      debugPrint('🔍 PREVIO_JUEGO: useRemoteApi: ${DataService.useRemoteApi}');
      final resultado = await DataService.obtenerVocabulario(userId: widget.userId);
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
        tarjetasVocabulario = []; // Asegurar que no se quede en loading infinito
      });
    }
  }

  Future<void> _cargarConfiguracionActividades() async {
    final orden = await DataService.obtenerOrdenActividades(widget.userId);
    final habilitadas = await DataService.obtenerActividadesHabilitadas(widget.userId);
    print('🔧 Orden cargado: $orden');
    print('🔧 Habilitadas cargadas: $habilitadas');
    setState(() {
      ordenActividades = orden;
      actividadesHabilitadas = habilitadas;
    });
    _cargarProgresoActividades();
  }

  Future<void> _cargarProgresoActividades() async {
    final db = await DBHelper.database;

    // Obtener las palabras del bloque actual (tarjeta actual)
    final palabrasBloqueActual = tarjetaActual < tarjetasVocabulario.length
        ? tarjetasVocabulario[tarjetaActual].map((p) => (p['label'] ?? '').toString()).toSet()
        : <String>{};

    // Obtener las palabras del bloque anterior
    final palabrasBloqueAnterior = tarjetaActual > 0
        ? tarjetasVocabulario[tarjetaActual - 1].map((p) => (p['label'] ?? '').toString()).toSet()
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
      if (p1.isNotEmpty && palabrasBloqueActual.contains(p1)) perteneceAlBloqueActual = true;
      if (p2.isNotEmpty && palabrasBloqueActual.contains(p2)) perteneceAlBloqueActual = true;
      if (p3.isNotEmpty && palabrasBloqueActual.contains(p3)) perteneceAlBloqueActual = true;

      if (perteneceAlBloqueActual) {
        mapa[act] = true;
      }

      // Verificar si pertenece al bloque anterior
      if (tarjetaActual > 0) {
        bool perteneceAlBloqueAnterior = false;
        if (p1.isNotEmpty && palabrasBloqueAnterior.contains(p1)) perteneceAlBloqueAnterior = true;
        if (p2.isNotEmpty && palabrasBloqueAnterior.contains(p2)) perteneceAlBloqueAnterior = true;
        if (p3.isNotEmpty && palabrasBloqueAnterior.contains(p3)) perteneceAlBloqueAnterior = true;

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
      bloqueAnteriorCompleto = actividadesRequeridas.every(
        (act) => actividadesBloqueAnterior[act] == true
      );
      print('🔒 Bloque $tarjetaActual - Actividades requeridas: $actividadesRequeridas');
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
                builder: (context) => ConfiguracionUsuarioPage(userId: widget.userId),
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
                    const Icon(Icons.library_books, size: 80, color: Color.fromRGBO(63, 46, 31, 0.5)),
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
                          onPageChanged: (index, reason) {
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
                          (index) => Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color:
                                  tarjetaActual == index
                                      ? const Color.fromRGBO(63, 46, 31, 1)
                                      : Colors.grey[400],
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Mensaje de advertencia si el bloque anterior no está completo
                    if (!bloqueAnteriorCompletado && tarjetaActual > 0)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
                              Icon(Icons.lock, color: Colors.orange[700], size: 20),
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
    return Container(
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
              child: FutureBuilder<Directory>(
                future: getApplicationDocumentsDirectory(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  const navColor = Color.fromRGBO(63, 46, 31, 1);
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (index) {
                      if (index < palabras.length) {
                        final palabra = palabras[index];
                        final nombreImagen = palabra['nombreImagen'] ?? '';
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
                                    child: _buildVocabularioImage(nombreImagen, snapshot.data!.path),
                                  ),
                                ),
                              const SizedBox(height: 6),
                              Text(
                                (palabra['label'] ?? '')
                                    .toString()
                                    .toUpperCase(),
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: navColor,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        );
                      } else {
                        return const SizedBox(width: 95);
                      }
                    }),
                  );
                },
              ),
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
        builder: () => const DemoDragTarget(),
      ),
      'discriminacion_inversa': (
        titulo: 'DISC. INVERSA',
        icono: Icons.swap_horiz,
        builder: () => const DiscriminacionInversa(),
      ),
      'silabas': (
        titulo: 'SÍLABAS',
        icono: Icons.text_fields,
        builder: () => const SilabasPage(),
      ),
      'arrastre': (
        titulo: 'ARRASTRE',
        icono: Icons.touch_app,
        builder: () => const ImagenArrastrePage(),
      ),
      'doble': (
        titulo: 'DOBLE',
        icono: Icons.format_list_bulleted,
        builder: () => const doble_arrastre.DobleArrastrePage(),
      ),
      'silabas_orden': (
        titulo: 'S. ORDEN',
        icono: Icons.sort,
        builder: () => const SilabasOrdenPage(),
      ),
      'silabas_distrac': (
        titulo: 'S. DISTRAC.',
        icono: Icons.psychology,
        builder: () => const SilabasOrdenDistraccionPage(),
      ),
    };

    // Usar el orden configurado, o el orden por defecto si no está cargado
    final ordenAUsar = ordenActividades.isNotEmpty
        ? ordenActividades
        : todasActividades.keys.toList();

    // Filtrar solo las actividades habilitadas
    final actividadesAMostrar = ordenAUsar
        .where((clave) => actividadesHabilitadas.isEmpty || actividadesHabilitadas.contains(clave))
        .toList();

    print('🎮 Total actividades configuradas: ${ordenAUsar.length}');
    print('🎮 Actividades a mostrar (filtradas): ${actividadesAMostrar.length}');
    print('🎮 Lista de actividades a mostrar: $actividadesAMostrar');

    final List<Widget> botones = [];
    for (var i = 0; i < actividadesAMostrar.length; i++) {
      final clave = actividadesAMostrar[i];
      final actividad = todasActividades[clave];

      if (actividad == null) continue;

      final previaCompletada =
          i == 0 ? true : (actividadesCompletadas[actividadesAMostrar[i - 1]] ?? false);

      // Solo habilitar si:
      // 1. Es la tarjeta actual
      // 2. El bloque anterior está completo
      // 3. La actividad previa está completa
      final estaHabilitado = esTarjetaActual && bloqueAnteriorCompletado && previaCompletada;

      print('🔍 Actividad $i: $clave');
      print('   - Es tarjeta actual: $esTarjetaActual');
      print('   - Bloque anterior completo: $bloqueAnteriorCompletado');
      print('   - Previa completada (${i > 0 ? actividadesAMostrar[i - 1] : 'primera'}): $previaCompletada');
      print('   - HABILITADO: $estaHabilitado');
      print('   - Actividades completadas bloque actual: $actividadesCompletadas');

      botones.add(
        _buildActividadButton(
          actividad.titulo,
          actividad.icono,
          marron,
          estaHabilitado
              ? () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => actividad.builder()),
                  ).then((_) => _cargarProgresoActividades())
              : null,
          iconSize: 84,
          textSize: 26,
          habilitado: estaHabilitado,
        ),
      );
    }
    return botones;
  }

  /// Construye el widget de imagen según el tipo (URL o archivo local)
  Widget _buildVocabularioImage(String nombreImagen, String appDocPath) {
    // Si nombreImagen es una URL (modo remoto), usar Image.network
    if (nombreImagen.startsWith('http://') || nombreImagen.startsWith('https://')) {
      return Image.network(
        nombreImagen,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return const Icon(Icons.broken_image, size: 50);
        },
      );
    } else {
      // Si es modo local, usar Image.file
      return Image.file(
        File('$appDocPath/vocabulario/$nombreImagen'),
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return const Icon(Icons.broken_image, size: 50);
        },
      );
    }
  }
}
