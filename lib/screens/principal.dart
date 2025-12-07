import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:leoconlula/widgets/fondo_principal.dart';
import 'package:leoconlula/helpers/db_helper.dart';
import 'package:leoconlula/screens/previo_juego.dart';

class PrincipalPage extends StatefulWidget {
  const PrincipalPage({super.key});

  @override
  State<PrincipalPage> createState() => _PrincipalPageState();
}

class _PrincipalPageState extends State<PrincipalPage> {
  List<Map<String, dynamic>> _users = [];

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    final users = await DBHelper.obtenerUsuarios();
    setState(() {
      _users = users;
    });
  }

  Future<void> _addUser(String name, String photo) async {
    await DBHelper.insertarUsuario(name, photo);
    _loadUsers();
  }

  void _showAddUserModal() {
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Añadir Usuario'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Nombre'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                final name = nameController.text;
                if (name.isNotEmpty) {
                  _addUser(name, "lula.png");
                  Navigator.pop(context);
                }
              },
              child: const Text('Añadir'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BackgroundContainerPrincipal(
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 40), // Espaciado superior
                SizedBox(
                  height: 150, // Altura ajustada del scroll horizontal
                  child: Row(
                    children: [
                      const SizedBox(width: 40),
                      GestureDetector(
                        onTap: _showAddUserModal,
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: const Color.fromRGBO(63, 46, 31, 1),
                            shape: BoxShape.circle, // Cambiado a forma circular
                          ),
                          child: const Icon(
                            Icons.add,
                            color: Colors.white,
                            size: 40,
                          ),
                        ),
                      ),

                      Expanded(
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          children: [
                            ..._users.map(
                              (user) => Row(
                                children: [
                                  _buildUserCard(
                                    user['nombre'],
                                    user['foto'],
                                    user['id'],
                                  ),
                                  const SizedBox(
                                    width: 20,
                                  ), // Espaciado entre avatares
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 40),
                    ],
                  ),
                ),
              ],
            ),
            Positioned(
              bottom: 200, // Ajusta la posición vertical para no tapar a Lula
              right: 20, // Ajusta la posición horizontal
              child: Column(
                children: [
                  const SizedBox(height: 50),
                  Container(
                    width:
                        MediaQuery.of(context).size.width *
                        0.5, // 50% del ancho de la pantalla
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color.fromRGBO(
                        63,
                        46,
                        31,
                        1,
                      ), // Color del fondo
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Text(
                      'BIENVENIDO Y BIENVENIDA A LEO CON LULA',
                      style: TextStyle(
                        fontSize: 24, // Tamaño de fuente más pequeño
                        color: Colors.white, // Color del texto
                        height: 1.5, // Espaciado entre líneas
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 40),
                  Container(
                    width:
                        MediaQuery.of(context).size.width *
                        0.5, // 50% del ancho de la pantalla
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color.fromRGBO(
                        63,
                        46,
                        31,
                        1,
                      ), // Color del fondo
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Text(
                      'Un proyecto sencillo pensado para trabajar la Lectura Global con personas con autismo. Una aplicación intuitiva que podrás personalizar, eligiendo las palabras a trabajar, el tipo de letra, los apoyos visuales, etc. Contiene distintas fases que permitirá que la persona aprenda a leer a través de un entrenamiento adecuado y un aprendizaje progresivo.',
                      style: TextStyle(
                        fontSize: 24, // Tamaño de fuente más pequeño
                        color: Colors.white, // Color del texto
                        height: 1.5, // Espaciado entre líneas
                      ),
                      textAlign: TextAlign.justify,
                    ),
                  ),
                  const SizedBox(height: 40),
                  Container(
                    width:
                        MediaQuery.of(context).size.width *
                        0.5, // 50% del ancho de la pantalla
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color.fromRGBO(
                        63,
                        46,
                        31,
                        1,
                      ), // Color del fondo
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Text(
                      "Selecciona un usuario para iniciar el juego",
                      style: TextStyle(
                        fontSize: 24, // Tamaño de fuente más pequeño
                        color: Colors.white, // Color del texto
                        height: 1.5, // Espaciado entre líneas
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserCard(String name, String imagePath, int userId) {
    return FutureBuilder<Widget>(
      future: _buildUserAvatar(imagePath),
      builder: (context, snapshot) {
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) =>
                        PrevioJuegoPage(userId: userId, userName: name),
              ),
            );
          },
          child: Column(
            children: [
              snapshot.data ?? const CircleAvatar(radius: 59),
              const SizedBox(height: 8),
              Text(
                name.toUpperCase(),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color.fromRGBO(63, 46, 31, 1),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<Widget> _buildUserAvatar(String imagePath) async {
    if (imagePath.isNotEmpty && !imagePath.endsWith('.png')) {
      // Si es una imagen de assets antigua
      return CircleAvatar(
        radius: 59,
        backgroundColor: const Color.fromRGBO(63, 46, 31, 1),
        child: CircleAvatar(
          radius: 55,
          backgroundImage: AssetImage("assets/images/$imagePath"),
        ),
      );
    }
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$imagePath');
      if (await file.exists()) {
        return CircleAvatar(
          radius: 59,
          backgroundColor: const Color.fromRGBO(63, 46, 31, 1),
          child: CircleAvatar(radius: 55, backgroundImage: FileImage(file)),
        );
      }
    } catch (e) {
      debugPrint('Error al cargar imagen de usuario: $e');
    }
    // Si no existe la imagen en documentos, usa la de assets por defecto
    return CircleAvatar(
      radius: 59,
      backgroundColor: const Color.fromRGBO(63, 46, 31, 1),
      child: CircleAvatar(
        radius: 55,
        backgroundImage: const AssetImage("assets/images/lula.png"),
      ),
    );
  }
}
