/// Perfil de marca/produto persistido em `brand_profiles`.
class BrandProfile {
  const BrandProfile({
    required this.id,
    required this.name,
    required this.description,
    required this.targetAudience,
    required this.tone,
    required this.keywords,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String description;
  final String targetAudience;
  final String tone;
  final List<String> keywords;
  final DateTime createdAt;

  factory BrandProfile.fromJson(Map<String, dynamic> json) {
    final kw = json['keywords'];
    List<String> keys = [];
    if (kw is List) {
      keys = kw.map((e) => e.toString()).toList();
    }
    return BrandProfile(
      id: json['id'].toString(),
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      targetAudience: json['target_audience']?.toString() ?? '',
      tone: json['tone']?.toString() ?? '',
      keywords: keys,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  /// `user_id` é preenchido pelo serviço com o utilizador autenticado.
  Map<String, dynamic> toInsertJson() {
    return {
      'name': name,
      'description': description,
      'target_audience': targetAudience,
      'tone': tone,
      'keywords': keywords,
    };
  }

  Map<String, dynamic> toUpdateJson() {
    return {
      'name': name,
      'description': description,
      'target_audience': targetAudience,
      'tone': tone,
      'keywords': keywords,
    };
  }
}
