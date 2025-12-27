import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../widgets/fondo_inicio.dart';
import 'package:leoconlula/services/data_service.dart';
import 'vocabulario.dart';

class ConfiguracionUsuarioPage extends StatefulWidget {
  final int userId;

  const ConfiguracionUsuarioPage({super.key, required this.userId});

  @override
  State<ConfiguracionUsuarioPage> createState() =>
      _ConfiguracionUsuarioPageState();
}

class _ConfiguracionUsuarioPageState extends State<ConfiguracionUsuarioPage> {
  late int userId;
  String fuenteSeleccionada = 'ARIAL'; // <--- Añade esto
  String vozSeleccionada = 'MONICA'; // Valor por defecto
  String? fotoUsuario;
  String? codigoUnico; // Código único del estudiante
  int numeroRepeticiones = 5;
  Map<String, bool> config = {
    'leer_palabras': true,
    'refuerzo_acierto': true,
    'refuerzo_error': true,
    'ayudas_visuales': false,
    'modo_infantil': false,
    'tipo': true, // <--- Añade este campo
    'bloqueo_actividades': false, // Bloquear actividades hasta completar la anterior
  };

  // Actividades disponibles y su orden
  List<String> ordenActividades = [
    'aprendizaje',
    'discriminacion',
    'discriminacion_inversa',
    'silabas',
    'arrastre',
    'doble',
    'silabas_orden',
    'silabas_distrac',
  ];

  Map<String, bool> actividadesHabilitadas = {
    'aprendizaje': true,
    'discriminacion': true,
    'discriminacion_inversa': true,
    'silabas': true,
    'arrastre': true,
    'doble': true,
    'silabas_orden': true,
    'silabas_distrac': true,
  };

  @override
  void initState() {
    super.initState();
    userId = widget.userId;
    _cargarConfiguracionUsuario();
  }

  Future<void> _cargarConfiguracionUsuario() async {
    // Obtener el usuario específico por su ID
    final usuarios = await DataService.obtenerUsuarios();
    if (usuarios.isNotEmpty) {
      // Buscar el usuario con el userId correcto
      final usuario = usuarios.firstWhere(
        (u) => u['id'] == userId,
        orElse: () => usuarios.first,
      );

      // Cargar orden y actividades habilitadas para este usuario
      final orden = await DataService.obtenerOrdenActividades(userId);
      final habilitadas = await DataService.obtenerActividadesHabilitadas(userId);

      setState(() {
        // NO sobrescribir userId - ya está configurado en initState
        fuenteSeleccionada =
            usuario['fuente'] ?? 'ARIAL'; // <--- Carga la fuente
        vozSeleccionada = usuario['voz'] ?? 'MONICA'; // <--- Añade esto
        fotoUsuario = usuario['foto']; // <-- Añade esto
        codigoUnico = usuario['codigoUnico']; // Cargar código único
        numeroRepeticiones = (usuario['numero_repeticiones'] ?? 5) as int;
        config = {
          'leer_palabras': (usuario['leer_palabras'] ?? 1) == 1,
          'refuerzo_acierto': (usuario['refuerzo_acierto'] ?? 1) == 1,
          'refuerzo_error': (usuario['refuerzo_error'] ?? 1) == 1,
          'ayudas_visuales': (usuario['ayudas_visuales'] ?? 0) == 1,
          'modo_infantil': (usuario['modo_infantil'] ?? 0) == 1,
          'tipo': (usuario['tipo'] ?? 1) == 1,
          'bloqueo_actividades': (usuario['bloqueo_actividades'] ?? 0) == 1,
        };
        ordenActividades = orden;
        // Actualizar mapa de habilitadas
        for (var key in actividadesHabilitadas.keys) {
          actividadesHabilitadas[key] = habilitadas.contains(key);
        }
      });
    }
  }

  Future<void> _toggleConfig(String key) async {
    setState(() {
      config[key] = !(config[key] ?? false);
    });
    await DataService.actualizarCampoUsuarioBool(userId, key, config[key]!);
  }

  Future<void> _mostrarSelectorFuente() async {
    final fuentes = ['ARIAL', 'HELVÉTICA'];
    final seleccionada = await showDialog<String>(
      context: context,
      builder:
          (context) => SimpleDialog(
            title: const Text('Elige el tipo de letra'),
            children:
                fuentes.map((fuente) {
                  return SimpleDialogOption(
                    onPressed: () => Navigator.pop(context, fuente),
                    child: Text(fuente),
                  );
                }).toList(),
          ),
    );
    if (seleccionada != null) {
      await DataService.actualizarCampoUsuarioString(userId, 'fuente', seleccionada);
      setState(() {
        fuenteSeleccionada = seleccionada; // <--- Actualiza la fuente
      });
    }
  }

  Future<void> _mostrarSelectorVoz() async {
    final voces = ['MONICA', 'ALEX'];
    final seleccionada = await showDialog<String>(
      context: context,
      builder:
          (context) => SimpleDialog(
            title: const Text('Elige la voz'),
            children:
                voces.map((voz) {
                  return SimpleDialogOption(
                    onPressed: () => Navigator.pop(context, voz),
                    child: Text(voz),
                  );
                }).toList(),
          ),
    );
    if (seleccionada != null) {
      await DataService.actualizarCampoUsuarioString(userId, 'voz', seleccionada);
      setState(() {
        vozSeleccionada = seleccionada; // <--- Actualiza la voz
      });
    }
  }

  Future<void> _cambiarFotoUsuario() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      if (DataService.useRemoteApi) {
        // En modo remoto, subir la imagen al servidor
        try {
          final archivo = File(pickedFile.path);
          final url = await DataService.subirImagen(archivo, tipo: 'avatar');

          if (url != null) {
            await DataService.actualizarCampoUsuarioString(userId, 'foto', url);
            setState(() {
              fotoUsuario = url;
            });
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error al subir imagen: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } else {
        // En modo local, guardar el archivo localmente
        final directory = await getApplicationDocumentsDirectory();
        final fileName = 'avatar_usuario_$userId.png';
        final newPath = '${directory.path}/$fileName';
        await File(pickedFile.path).copy(newPath);

        await DataService.actualizarCampoUsuarioString(userId, 'foto', fileName);
        setState(() {
          fotoUsuario = fileName;
        });
      }
    }
  }

  Future<void> _mostrarSelectorActividades() async {
    // Mapa de nombres de actividades
    final nombresActividades = {
      'aprendizaje': 'Aprendizaje',
      'discriminacion': 'Discriminación',
      'discriminacion_inversa': 'Discriminación Inversa',
      'silabas': 'Sílabas',
      'arrastre': 'Arrastre',
      'doble': 'Doble',
      'silabas_orden': 'Sílabas Orden',
      'silabas_distrac': 'Sílabas Distracción',
    };

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text(
                'Configurar Actividades',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Arrastra para ordenar y marca/desmarca para habilitar:',
                      style: TextStyle(fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Flexible(
                      child: ReorderableListView(
                        shrinkWrap: true,
                        onReorder: (oldIndex, newIndex) {
                          setStateDialog(() {
                            if (newIndex > oldIndex) newIndex--;
                            final item = ordenActividades.removeAt(oldIndex);
                            ordenActividades.insert(newIndex, item);
                          });
                          setState(() {
                            if (newIndex > oldIndex) newIndex--;
                            final item = ordenActividades.removeAt(oldIndex);
                            ordenActividades.insert(newIndex, item);
                          });
                        },
                        children: ordenActividades.map((key) {
                          return CheckboxListTile(
                            key: ValueKey(key),
                            title: Row(
                              children: [
                                const Icon(Icons.drag_handle, size: 20),
                                const SizedBox(width: 8),
                                Text(nombresActividades[key] ?? key),
                              ],
                            ),
                            value: actividadesHabilitadas[key] ?? true,
                            activeColor: const Color.fromRGBO(63, 46, 31, 1),
                            onChanged: (value) {
                              setStateDialog(() {
                                actividadesHabilitadas[key] = value ?? true;
                              });
                              setState(() {
                                actividadesHabilitadas[key] = value ?? true;
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () async {
                    // Guardar orden y actividades habilitadas
                    await DataService.guardarOrdenActividades(userId, ordenActividades);
                    final habilitadas = actividadesHabilitadas.entries
                        .where((e) => e.value)
                        .map((e) => e.key)
                        .toList();
                    await DataService.guardarActividadesHabilitadas(userId, habilitadas);
                    if (!context.mounted) return;
                    Navigator.of(context).pop();
                  },
                  child: const Text(
                    'Guardar',
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
      },
    );
  }

  Future<void> _mostrarSelectorRepeticiones() async {
    int temp = numeroRepeticiones;
    final seleccionado = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: StatefulBuilder(
            builder: (context, setModalState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Número de repeticiones',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Slider(
                    value: temp.toDouble(),
                    min: 5,
                    max: 20,
                    divisions: 15,
                    label: '$temp',
                    activeColor: const Color.fromRGBO(63, 46, 31, 1),
                    onChanged: (v) {
                      setModalState(() {
                        temp = v.round();
                      });
                    },
                  ),
                  Text('Repeticiones: $temp'),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromRGBO(63, 46, 31, 1),
                    ),
                    onPressed: () => Navigator.pop(context, temp),
                    child: const Text('Guardar'),
                  ),
                ],
              );
            },
          ),
        );
      },
    );

    if (seleccionado != null) {
      await DataService.actualizarCampoUsuarioInt(userId, 'numero_repeticiones', seleccionado);
      setState(() {
        numeroRepeticiones = seleccionado;
      });
    }
  }

  void _mostrarCodigoEstudiante() {
    if (codigoUnico == null || codigoUnico!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Este estudiante no tiene código asignado'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Código del Estudiante',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Comparte este código con otro usuario para que pueda acceder a este estudiante:',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color.fromRGBO(63, 46, 31, 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color.fromRGBO(63, 46, 31, 1),
                    width: 2,
                  ),
                ),
                child: SelectableText(
                  codigoUnico!,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                    color: Color.fromRGBO(63, 46, 31, 1),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                // Copiar al portapapeles
                final data = ClipboardData(text: codigoUnico!);
                Clipboard.setData(data);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Código copiado al portapapeles'),
                    backgroundColor: Colors.green,
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              child: const Text('Copiar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final double anchoPantalla = MediaQuery.of(context).size.width;
    final double altoPantalla = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.home, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Configuración de Usuario',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color.fromRGBO(63, 46, 31, 1),
      ),
      body: Stack(
        children: [
          BackgroundContainerInicio(child: const SizedBox.shrink()),
          Align(
            alignment: Alignment.topRight,
            child: Container(
              margin: const EdgeInsets.only(
                right: 40,
              ),
              width: anchoPantalla * (2 / 3),
              height: altoPantalla * (2 / 3),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(
                        right: 1,
                      ), // <-- Añade margen derecho aquí

                      width: anchoPantalla * (2 / 3) * 0.75,
                      height: altoPantalla * (2 / 3) * 0.75,
                      child: GridView.count(
                        crossAxisCount: 5,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 0.95,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          _ConfigButton(
                            icon: Icons.record_voice_over,
                            title: 'VOZ: $vozSeleccionada',
                            value: false, // No se usa el value aquí
                            onTap: _mostrarSelectorVoz,
                          ),
                          _ConfigButton(
                            icon: Icons.thumb_up_alt,
                            title: 'REFUERZO ACIERTO',
                            value: config['refuerzo_acierto'] ?? false,
                            onTap: () => _toggleConfig('refuerzo_acierto'),
                          ),
                          _ConfigButton(
                            icon: Icons.thumb_down_alt,
                            title: 'REFUERZO ERROR',
                            value: config['refuerzo_error'] ?? false,
                            onTap: () => _toggleConfig('refuerzo_error'),
                          ),
                          _ConfigButton(
                            icon: Icons.lightbulb_outline,
                            title: 'AYUDAS VISUALES',
                            value: config['ayudas_visuales'] ?? false,
                            onTap: () => _toggleConfig('ayudas_visuales'),
                          ),
                          _ConfigButton(
                            icon: Icons.child_care,
                            title: 'MODO INFANTIL',
                            value: config['modo_infantil'] ?? false,
                            onTap: () => _toggleConfig('modo_infantil'),
                          ),
                          _ConfigButton(
                            icon: Icons.font_download,
                            title: 'TIPO DE LETRA: $fuenteSeleccionada',
                            value: false, // No se usa el valor aquí
                            onTap: _mostrarSelectorFuente,
                          ),
                          _ConfigButton(
                            icon: Icons.text_fields,
                            title: 'FUENTE EN MAYÚSCULAS',
                            value: config['tipo'] ?? true,
                            onTap: () => _toggleConfig('tipo'),
                          ),
                          _ConfigButton(
                            icon: Icons.lock,
                            title: 'BLOQUEAR ACTIVIDADES',
                            value: config['bloqueo_actividades'] ?? false,
                            onTap: () => _toggleConfig('bloqueo_actividades'),
                          ),
                          _ConfigButton(
                            icon: Icons.volume_up,
                            title: 'LEER PALABRAS',
                            value: config['leer_palabras'] ?? true,
                            onTap: () => _toggleConfig('leer_palabras'),
                          ),
                          _ConfigButton(
                            icon: Icons.cleaning_services,
                            title: 'BORRAR SESIONES',
                            value: false,
                            color: Colors.orange[700],
                            onTap: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder:
                                    (context) => AlertDialog(
                                      title: const Text('¿Borrar todas las sesiones?'),
                                      content: const Text(
                                        'Se borrarán todas las sesiones de actividades de este usuario. Las actividades volverán a estar bloqueadas hasta que las completes de nuevo.',
                                      ),
                                      actions: [
                                        TextButton(
                                          child: const Text('Cancelar'),
                                          onPressed:
                                              () => Navigator.of(
                                                context,
                                              ).pop(false),
                                        ),
                                        TextButton(
                                          child: const Text(
                                            'Borrar',
                                            style: TextStyle(color: Colors.orange),
                                          ),
                                          onPressed:
                                              () => Navigator.of(
                                                context,
                                              ).pop(true),
                                        ),
                                      ],
                                    ),
                              );
                              if (confirm == true) {
                                await DataService.borrarSesionesUsuario(userId);
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Sesiones borradas correctamente'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                            },
                          ),
                          _ConfigButton(
                            icon: Icons.delete,
                            title: 'ELIMINAR USUARIO',
                            value: false,
                            color: Colors.red[700],
                            onTap: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder:
                                    (context) => AlertDialog(
                                      title: const Text('¿Eliminar usuario?'),
                                      content: const Text(
                                        '¿Estás seguro de que quieres eliminar este usuario? Esta acción no se puede deshacer.',
                                      ),
                                      actions: [
                                        TextButton(
                                          child: const Text('Cancelar'),
                                          onPressed:
                                              () => Navigator.of(
                                                context,
                                              ).pop(false),
                                        ),
                                        TextButton(
                                          child: const Text(
                                            'Eliminar',
                                            style: TextStyle(color: Colors.red),
                                          ),
                                          onPressed:
                                              () => Navigator.of(
                                                context,
                                              ).pop(true),
                                        ),
                                      ],
                                    ),
                              );
                              if (confirm == true) {
                                await DataService.eliminarUsuario(userId);
                                if (!context.mounted) return;
                                Navigator.of(context).pushNamedAndRemoveUntil(
                                  '/splash',
                                  (route) => false,
                                );
                              }
                            },
                          ),
                          _ConfigButton(
                            icon: Icons.picture_as_pdf,
                            title: 'CREAR PDF',
                            value: false,
                            onTap: () {
                              // Aquí irá la navegación a la página PDF
                              // Navigator.push(context, MaterialPageRoute(builder: (_) => PdfPage()));
                            },
                          ),
                          _ConfigButton(
                            icon: Icons.share,
                            title: 'CÓDIGO COMPARTIR',
                            value: false,
                            color: Colors.blue[700],
                            onTap: _mostrarCodigoEstudiante,
                          ),
                          _ConfigButton(
                            icon: Icons.repeat,
                            title: 'Nº REPETICIONES: $numeroRepeticiones',
                            value: false,
                            onTap: _mostrarSelectorRepeticiones,
                          ),
                          _ConfigButton(
                            icon: Icons.checklist,
                            title: 'ACTIVIDADES',
                            value: false,
                            onTap: _mostrarSelectorActividades,
                          ),
                          _ConfigButton(
                            icon: Icons.book,
                            title: 'VOCABULARIO',
                            value: false,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) =>
                                          VocabularioPage(userId: userId),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Imagen de Lula en la esquina inferior izquierda
          Positioned(
            left: 0,
            bottom: 0,
            width: anchoPantalla * 0.4,
            child: Image.asset('assets/images/lula.png', fit: BoxFit.contain),
          ),
          // Avatar en la esquina superior izquierda
          Positioned(
            top: 24,
            left: 84,
            child: GestureDetector(
              onTap: _cambiarFotoUsuario,
              child: FutureBuilder<Directory>(
                future: getApplicationDocumentsDirectory(),
                builder: (context, snapshot) {
                  ImageProvider imageProvider;
                  if (fotoUsuario != null &&
                      fotoUsuario!.isNotEmpty &&
                      snapshot.hasData) {
                    imageProvider = FileImage(
                      File('${snapshot.data!.path}/$fotoUsuario'),
                    );
                  } else {
                    imageProvider = const AssetImage('assets/images/lula.png');
                  }
                  return Column(
                    children: [
                      // Círculo con borde marrón
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color.fromRGBO(63, 46, 31, 1),
                            width: 6,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 120, // Más grande
                          backgroundColor: Colors.white,
                          backgroundImage: imageProvider,
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Nombre de usuario debajo del avatar
                      FutureBuilder<List<Map<String, dynamic>>>(
                        future: DataService.obtenerUsuarios(),
                        builder: (context, snapshot) {
                          String nombre = '';
                          if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                            nombre = snapshot.data!.first['nombre'] ?? '';
                          }
                          return Text(
                            nombre.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color.fromRGBO(63, 46, 31, 1),
                            ),
                          );
                        },
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfigButton extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool value;
  final VoidCallback onTap;
  final Color? color;

  const _ConfigButton({
    required this.icon,
    required this.title,
    required this.value,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final bool esFuente = title.startsWith('TIPO DE LETRA');
    final bool esVoz = title.startsWith('VOZ:');
    final bool esPdf = title.startsWith('CREAR PDF');
    final bool esEstadisticas = title.startsWith('ESTADÍSTICAS');
    final bool esRepeticiones = title.startsWith('Nº REPETICIONES');
    final bool esCopia = title.startsWith('CARGAR COPIA');
    final bool esVocabulario = title.startsWith('VOCABULARIO');
    final bool esActividades = title.startsWith('ACTIVIDADES');
    final bool siempreActivo =
        esFuente ||
        esVoz ||
        esPdf ||
        esEstadisticas ||
        esCopia ||
        esVocabulario ||
        esActividades ||
        esRepeticiones;

    return Material(
      color:
          color ??
          (siempreActivo
              ? const Color(0xFF3F2E1F)
              : (value ? const Color(0xFF3F2E1F) : Colors.grey[600])),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 32),
              const SizedBox(height: 4),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),
              if (!siempreActivo && title != 'ELIMINAR USUARIO')
                Text(
                  value ? 'Sí' : 'NO',
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
