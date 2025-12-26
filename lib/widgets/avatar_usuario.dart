import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:leoconlula/services/data_service.dart';
import 'package:leoconlula/services/api_service.dart';

class AvatarUsuario extends StatelessWidget {
  final int? userId; // Si quieres filtrar por usuario concreto, si no, déjalo null

  const AvatarUsuario({super.key, this.userId});

  Future<String?> _getFotoPath() async {
    try {
      final usuarios = await DataService.obtenerUsuarios();
      Map<String, dynamic>? usuario;

      if (userId != null) {
        usuario = usuarios.firstWhere(
          (u) => u['id'] == userId,
          orElse: () => <String, dynamic>{},
        );
      } else if (usuarios.isNotEmpty) {
        usuario = usuarios.first;
      }

      if (usuario != null && usuario['foto'] != null) {
        final foto = usuario['foto'] as String;

        // Si es una URL completa, retornarla directamente
        if (foto.startsWith('http://') || foto.startsWith('https://')) {
          return foto;
        }

        // En modo remoto web, construir URL hacia el backend
        if (kIsWeb && DataService.useRemoteApi) {
          final imageUrl = '${ApiService.baseUrl}/uploads/avatars/$foto';
          debugPrint('🖼️ Avatar desde: $imageUrl');
          return imageUrl;
        }

        // En modo local, usar archivo local
        if (!kIsWeb) {
          final dir = await getApplicationDocumentsDirectory();
          final fotoPath = '${dir.path}/$foto';
          if (File(fotoPath).existsSync()) {
            return fotoPath;
          }
        }
      }
    } catch (e) {
      debugPrint('Error al obtener foto de usuario: $e');
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _getFotoPath(),
      builder: (context, snapshot) {
        final fotoPath = snapshot.data;

        ImageProvider imageProvider;
        if (fotoPath != null) {
          // Si es una URL, usar NetworkImage
          if (fotoPath.startsWith('http://') || fotoPath.startsWith('https://')) {
            imageProvider = NetworkImage(fotoPath);
          } else {
            // Si es un archivo local, usar FileImage
            imageProvider = FileImage(File(fotoPath));
          }
        } else {
          // Imagen por defecto
          imageProvider = const AssetImage('assets/images/lula.png');
        }

        return CircleAvatar(
          radius: 20,
          backgroundColor: Colors.white,
          child: CircleAvatar(
            radius: 18,
            backgroundImage: imageProvider,
          ),
        );
      },
    );
  }
}
