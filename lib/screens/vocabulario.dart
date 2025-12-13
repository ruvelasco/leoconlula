import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart' as p;
import 'package:leoconlula/widgets/avatar_usuario.dart';
import '../providers/arasaac_provider.dart';
import '../widgets/target_card2.dart';
import 'package:leoconlula/services/data_service.dart';
import '../widgets/fondo_inicio.dart';

class VocabularioPage extends StatefulWidget {
  final int userId;
  const VocabularioPage({super.key, required this.userId});

  @override
  State<VocabularioPage> createState() => _VocabularioPageState();
}

class _VocabularioPageState extends State<VocabularioPage> {
  final TextEditingController _controller = TextEditingController();
  List<Map<String, dynamic>> resultados = [];
  bool buscando = false;

  Future<void> _buscar() async {
    setState(() {
      buscando = true;
      resultados = [];
    });
    final res = await arasaacProvider.getJSONData(_controller.text.trim());
    setState(() {
      resultados = res;
      buscando = false;
    });
  }

  Future<void> guardarImagenEnDocumentos(String url, String nombreArchivo, String label) async {
    try {
      // 1. Consultar las sílabas antes de guardar
      final silabas = await obtenerSilabas(label);

      // 2. Si estamos en modo API remoto, guardar la URL directamente
      if (DataService.useRemoteApi) {
        debugPrint('📤 Modo remoto: Guardando URL de imagen directamente');
        await DataService.insertarVocabulario(url, label, widget.userId, silabas: silabas);
        setState(() {});
        return;
      }

      // 3. Si estamos en modo local, descargar la imagen
      debugPrint('📥 Modo local: Descargando imagen...');
      final dir = await getApplicationDocumentsDirectory();
      final vocabularioDir = Directory(p.join(dir.path, 'vocabulario'));
      if (!await vocabularioDir.exists()) {
        await vocabularioDir.create(recursive: true);
      }
      final path = p.join(vocabularioDir.path, nombreArchivo);
      await Dio().download(url, path);

      // 4. Guardar en la base de datos local
      await DataService.insertarVocabulario(nombreArchivo, label, widget.userId, silabas: silabas);

      setState(() {}); // Esto recarga el FutureBuilder y actualiza el listado
    } catch (e) {
      debugPrint('Error al guardar imagen de vocabulario: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> _cargarVocabularioGuardado() async {
    // Usar DataService para que funcione tanto en local como en remoto
    return await DataService.obtenerVocabulario(userId: widget.userId);
  }

  Future<String> obtenerSilabas(String palabra) async {
    final url = Uri.parse('http://www.aulatea.com/silabas/website/silabas/index.php?json=1&word=${Uri.encodeComponent(palabra)}');
    try {
      final response = await Dio().getUri(url,
        options: Options(responseType: ResponseType.bytes),
      );
      if (response.statusCode == 200 && response.data != null) {
        final decoded = latin1.decode(response.data);
        final data = json.decode(decoded);
        if (data['syllables'] != null && data['syllables'] is List) {
          // Reemplaza los signos de interrogación por la vocal acentuada si la palabra original la tiene
          List<String> syllables = (data['syllables'] as List)
              .map((s) => s is String ? s : s.toString())
              .toList();

          // Si la palabra original tiene una vocal acentuada, intenta corregir la sílaba
          for (int i = 0; i < syllables.length; i++) {
            if (syllables[i].contains('?')) {
              // Busca la sílaba correcta en la palabra original
              for (int j = 0; j < palabra.length; j++) {
                if ('áéíóúÁÉÍÓÚ'.contains(palabra[j])) {
                  syllables[i] = syllables[i].replaceAll('?', palabra[j]);
                  break;
                }
              }
            }
          }
          return syllables.join('*');
        }
      }
    } catch (e) {
      debugPrint('Error obteniendo sílabas de "$palabra": $e');
    }
    return '';
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
        title: const Text('Vocabulario ARASAAC', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color.fromRGBO(63, 46, 31, 1),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: AvatarUsuario(userId: widget.userId),
          ),
        ],
      ),
      body: BackgroundContainerInicio(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: const InputDecoration(
                        labelText: 'Buscar palabra',
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: (_) => _buscar(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _buscar,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromRGBO(63, 46, 31, 1),
                      foregroundColor: Colors.white,
                    ),
                    child: const Icon(Icons.search),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (buscando)
                const CircularProgressIndicator()
              else if (resultados.isEmpty)
                const Text('No hay resultados', style: TextStyle(color: Colors.grey)),
              if (resultados.isNotEmpty)
                SizedBox(
                  height: 305,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: resultados.length,
                    itemBuilder: (context, index) {
                      final item = resultados[index];
                      final String palabra = (item['keywords']?[0]?['keyword'] ?? '').toString();
                      final String id = item['_id'].toString();
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: GestureDetector(
                          onTap: () async {
                            final nombreArchivo = '$id.png';
                            final url = 'https://static.arasaac.org/pictograms/$id/${id}_300.png';
                            try {
                              await guardarImagenEnDocumentos(url, nombreArchivo, palabra);
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Imagen guardada y vocabulario añadido')),
                              );
                            } catch (e) {
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('No se pudo guardar la imagen')),
                              );
                            }
                          },
                          child: TargetCard2(
                            imageAsset: 'https://static.arasaac.org/pictograms/$id/${id}_300.png',
                            label: palabra,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 24),
              // ListView de palabras guardadas de la BD, debajo del anterior
              FutureBuilder<List<Map<String, dynamic>>>(
                future: _cargarVocabularioGuardado(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const SizedBox();
                  }
                  final vocabularioGuardado = snapshot.data!;
                  if (vocabularioGuardado.isEmpty) {
                    return const SizedBox();
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Mi vocabulario:',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 300,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: vocabularioGuardado.length + (vocabularioGuardado.length ~/ 3),
                          itemBuilder: (context, index) {
                            // Calcula el índice real de la tarjeta
                            final extraSpaces = index ~/ 4;
                            if ((index + 1) % 4 == 0) {
                              // Cada tres tarjetas, añade un espacio extra
                              return const SizedBox(width: 52);
                            }
                            final realIndex = index - extraSpaces;
                            final item = vocabularioGuardado[realIndex];
                            final String label = item['label'] ?? '';
                            final String nombreImagen = item['nombreImagen'] ?? '';

                            // Si nombreImagen es una URL (modo remoto), usarla directamente
                            // Si no, construir la URL desde el ID (modo local)
                            String imageUrl;
                            if (nombreImagen.startsWith('http://') || nombreImagen.startsWith('https://')) {
                              imageUrl = nombreImagen;
                            } else {
                              final String id = nombreImagen.split('.').first;
                              imageUrl = 'https://static.arasaac.org/pictograms/$id/${id}_300.png';
                            }

                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: Stack(
                                children: [
                                  TargetCard2(
                                    imageAsset: imageUrl,
                                    label: label,
                                  ),
                                  Positioned(
                                    top: 4,
                                    right: 4,
                                    child: IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red, size: 28),
                                      onPressed: () async {
                                        final vocabId = item['id'];
                                        if (vocabId != null) {
                                          await DataService.eliminarVocabulario(vocabId);

                                          // Si es modo local, eliminar también el archivo
                                          if (!DataService.useRemoteApi) {
                                            try {
                                              final dir = await getApplicationDocumentsDirectory();
                                              final file = File('${dir.path}/vocabulario/$nombreImagen');
                                              if (await file.exists()) {
                                                await file.delete();
                                              }
                                            } catch (e) {
                                              debugPrint('Error al eliminar archivo: $e');
                                            }
                                          }
                                          setState(() {});
                                        }
                                      },
                                      tooltip: 'Eliminar',
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
