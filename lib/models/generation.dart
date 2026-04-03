class Generation {
  const Generation({
    required this.id,
    this.userId,
    required this.originalImageUrl,
    required this.variantCount,
    required this.status,
    this.analysis,
    required this.createdAt,
  });

  final String id;
  final String? userId;
  final String originalImageUrl;
  final int variantCount;
  final String status;
  final Map<String, dynamic>? analysis;
  final DateTime createdAt;

  factory Generation.fromJson(Map<String, dynamic> json) {
    return Generation(
      id: json['id'] as String,
      userId: json['user_id'] as String?,
      originalImageUrl: json['original_image_url'] as String,
      variantCount: (json['variant_count'] as num).toInt(),
      status: json['status'] as String,
      analysis: json['analysis'] != null
          ? Map<String, dynamic>.from(json['analysis'] as Map)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'user_id': userId,
      'original_image_url': originalImageUrl,
      'variant_count': variantCount,
      'status': status,
      'analysis': analysis,
    };
  }

  Generation copyWith({
    String? id,
    String? userId,
    String? originalImageUrl,
    int? variantCount,
    String? status,
    Map<String, dynamic>? analysis,
    DateTime? createdAt,
  }) {
    return Generation(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      originalImageUrl: originalImageUrl ?? this.originalImageUrl,
      variantCount: variantCount ?? this.variantCount,
      status: status ?? this.status,
      analysis: analysis ?? this.analysis,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
