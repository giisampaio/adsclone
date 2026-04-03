/// Resultado estruturado da análise de criativo (Edge `mode: analyze`).
class CreativeAnalysis {
  const CreativeAnalysis({
    required this.product,
    required this.valueProposition,
    required this.cta,
    required this.colors,
    required this.layout,
    required this.tone,
    required this.whatWorks,
  });

  final String product;
  final String valueProposition;
  final String cta;
  final List<String> colors;
  final String layout;
  final String tone;
  final String whatWorks;

  factory CreativeAnalysis.fromJson(Map<String, dynamic> m) {
    List<String> parseColors(dynamic v) {
      if (v is! List) return [];
      return v.map((e) => e.toString().trim()).where((s) => s.isNotEmpty).toList();
    }

    final colors = parseColors(m['colors']);
    final coresHex = parseColors(m['cores_hex']);

    return CreativeAnalysis(
      product: m['product']?.toString() ?? m['produto']?.toString() ?? '',
      valueProposition: (m['value_proposition'] ?? m['valueProposition'])
              ?.toString() ??
          m['proposta_valor']?.toString() ??
          '',
      cta: m['cta']?.toString() ?? '',
      colors: colors.isNotEmpty ? colors : coresHex,
      layout: m['layout']?.toString() ?? '',
      tone: m['tone']?.toString() ?? m['tom']?.toString() ?? '',
      whatWorks: (m['what_works'] ?? m['whatWorks'])?.toString() ??
          m['o_que_funciona']?.toString() ??
          '',
    );
  }

  Map<String, dynamic> toJson() => {
        'product': product,
        'value_proposition': valueProposition,
        'cta': cta,
        'colors': colors,
        'layout': layout,
        'tone': tone,
        'what_works': whatWorks,
      };
}
