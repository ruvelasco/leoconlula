class Pictogramas {
  List<Pictograma> items = [];

  Pictogramas();

  Pictogramas.fromJsonList(List<dynamic>? jsonList) {
    if (jsonList == null) return;

    for (var item in jsonList) {
      var it = item as Map<String, dynamic>;
      final pictograma = Pictograma.fromJsonMap(it);
      items.add(pictograma);
    }
  }
}

class Pictograma {
  int id;
  bool available;
  bool violence;
  String created;
  int downloads;
  List<String> tags;
  dynamic synsets;
  bool sex;
  int idPictogram;
  String lastUpdated;
  bool schematic;
  bool published;
  List<String> keywords;
  bool validated;
  List<String> categories;
  String desc;

  Pictograma({
    required this.id,
    required this.available,
    required this.violence,
    required this.created,
    required this.downloads,
    required this.tags,
    required this.synsets,
    required this.sex,
    required this.idPictogram,
    required this.lastUpdated,
    required this.schematic,
    required this.published,
    required this.keywords,
    required this.validated,
    required this.categories,
    required this.desc,
  });

  factory Pictograma.fromJsonMap(Map<String, dynamic> json) {
    return Pictograma(
      id: json['_id'] as int? ?? 0,
      available: json['available'] as bool? ?? false,
      violence: json['violence'] as bool? ?? false,
      created: json['created'] as String? ?? "",
      downloads: json['downloads'] as int? ?? 0,
      tags: List<String>.from(json['tags'] ?? []),
      synsets: json['synsets'],
      sex: json['sex'] as bool? ?? false,
      idPictogram: json['idPictogram'] as int? ?? 0,
      lastUpdated: json['lastUpdated'] as String? ?? "",
      schematic: json['schematic'] as bool? ?? false,
      published: json['published'] as bool? ?? false,
      keywords: List<String>.from(json['keywords'] ?? []),
      validated: json['validated'] as bool? ?? false,
      categories: List<String>.from(json['categories'] ?? []),
      desc: json['desc'] as String? ?? "",
    );
  }

  String getImg() {
    return 'https://api.arasaac.org/api/pictograms/$id';
  }
}

class Keyword {
  String idLocution;
  String keyword;
  int type;
  String meaning;
  String plural;
  int idKeyword;
  int idLse;

  Keyword({
    required this.idLocution,
    required this.keyword,
    required this.type,
    required this.meaning,
    required this.plural,
    required this.idKeyword,
    required this.idLse,
  });
}