/// Briefing da etapa 2 (enviado à Edge Function).
class CreativeBriefing {
  const CreativeBriefing({
    this.productDescription = '',
    this.targetAudience = '',
    this.tone = '',
    this.additionalInfo = '',
  });

  final String productDescription;
  final String targetAudience;
  final String tone;
  final String additionalInfo;

  Map<String, dynamic> toJson() => {
        'product_description': productDescription,
        'target_audience': targetAudience,
        'tone': tone,
        'additional_info': additionalInfo,
      };

  CreativeBriefing copyWith({
    String? productDescription,
    String? targetAudience,
    String? tone,
    String? additionalInfo,
  }) {
    return CreativeBriefing(
      productDescription: productDescription ?? this.productDescription,
      targetAudience: targetAudience ?? this.targetAudience,
      tone: tone ?? this.tone,
      additionalInfo: additionalInfo ?? this.additionalInfo,
    );
  }
}
