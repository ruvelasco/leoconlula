import 'dart:async';
import 'dart:convert';
import '../models/pictograma_models.dart';
import 'package:http/http.dart' as http;
import 'dart:developer' as developer;

class ArasaacProvider {
  List<dynamic> opciones = [];

  /// Método para obtener JSON sin procesar desde la API
 Future<List<Map<String, dynamic>>> getJSONData(String palabra) async {
  try {
    final Uri url = Uri.parse('https://api.arasaac.org/api/pictograms/es/bestsearch/$palabra');
    final response = await http.get(url, headers: {"Accept": "application/json"});

    if (response.statusCode == 200) {
      final List<dynamic> dataConvertedToJSON = json.decode(response.body);

      // Convertimos `List<dynamic>` a `List<Map<String, dynamic>>`
      return dataConvertedToJSON.cast<Map<String, dynamic>>();
    }

    return []; // Retorna lista vacía si la respuesta no es válida
  } catch (e) {
    developer.log("Error en getJSONData para palabra '$palabra': $e", name: 'ArasaacProvider');
    return [];
  }
}

  /// Método para obtener pictogramas como objetos `Pictograma`
  Future<List<Pictograma>> getPalabras(String palabra) async {
    try {
      final Uri url = Uri.parse('https://api.arasaac.org/api/pictograms/es/bestsearch/$palabra');
      final response = await http.get(url, headers: {"Accept": "application/json"});

      if (response.statusCode == 200) {
        final decodedData = json.decode(response.body);
        if (decodedData is List) {
          final pictogramas = Pictogramas.fromJsonList(decodedData);
          return pictogramas.items;
        }
      }

      return []; // Retornar lista vacía en caso de error
    } catch (e) {
      developer.log("Error en getPalabras para palabra '$palabra': $e", name: 'ArasaacProvider');
      return [];
    }
  }
}

// Instancia global del provider
final arasaacProvider = ArasaacProvider();