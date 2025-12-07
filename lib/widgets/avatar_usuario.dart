import 'dart:io';
import 'package:flutter/material.dart';
import 'package:leoconlula/helpers/db_helper.dart';
import 'package:path_provider/path_provider.dart';

class AvatarUsuario extends StatelessWidget {
  final int? userId; // Si quieres filtrar por usuario concreto, si no, déjalo null

  const AvatarUsuario({super.key, this.userId});

  Future<String?> _getFotoPath() async {
    final db = await DBHelper.database;
    Map<String, dynamic>? usuario;
    if (userId != null) {
      final resultado = await db.query('usuarios', where: 'id = ?', whereArgs: [userId], limit: 1);
      if (resultado.isNotEmpty) usuario = resultado.first;
    } else {
      final resultado = await db.query('usuarios', limit: 1);
      if (resultado.isNotEmpty) usuario = resultado.first;
    }
    if (usuario != null && usuario['foto'] != null) {
      final foto = usuario['foto'] as String;
      final dir = await getApplicationDocumentsDirectory();
      final fotoPath = '${dir.path}/$foto';
      if (File(fotoPath).existsSync()) {
        return fotoPath;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _getFotoPath(),
      builder: (context, snapshot) {
        final fotoPath = snapshot.data;
        return CircleAvatar(
          radius: 20,
          backgroundColor: Colors.white,
          child: CircleAvatar(
            radius: 18,
            backgroundImage: (fotoPath != null)
                ? FileImage(File(fotoPath))
                : const AssetImage('assets/images/lula.png') as ImageProvider,
          ),
        );
      },
    );
  }
}