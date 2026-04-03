class Variant {
  const Variant({
    required this.id,
    required this.generationId,
    required this.imageUrl,
    this.promptUsed,
    this.direction,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String generationId;
  final String imageUrl;
  final String? promptUsed;
  final String? direction;
  final String status;
  final DateTime createdAt;

  factory Variant.fromJson(Map<String, dynamic> json) {
    return Variant(
      id: json['id'] as String,
      generationId: json['generation_id'] as String,
      imageUrl: json['image_url'] as String,
      promptUsed: json['prompt_used'] as String?,
      direction: json['direction'] as String?,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  /// Accepts maps from REST or Realtime payloads (values may be dynamic).
  factory Variant.fromMap(Map<String, dynamic> map) {
    dynamic v(String key) => map[key];

    return Variant(
      id: v('id').toString(),
      generationId: v('generation_id').toString(),
      imageUrl: v('image_url').toString(),
      promptUsed: v('prompt_used')?.toString(),
      direction: v('direction')?.toString(),
      status: v('status')?.toString() ?? 'unknown',
      createdAt: DateTime.tryParse(v('created_at')?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}
