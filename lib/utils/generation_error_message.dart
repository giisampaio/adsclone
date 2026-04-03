/// Erro de geração já mapeado para exibição ao utilizador.
class GenerationFailedException implements Exception {
  GenerationFailedException(this.userMessage);

  final String userMessage;

  @override
  String toString() => userMessage;
}

/// Converte erros técnicos de geração / Edge Function em texto para o utilizador.
String friendlyGenerationError(
  Object error, {
  int? httpStatus,
}) {
  final raw = error.toString();
  final lower = raw.toLowerCase();

  if (lower.contains('worker_limit') ||
      lower.contains('worker limit') ||
      lower.contains('cpu time') ||
      lower.contains('function_invocation_timeout')) {
    return 'Tempo esgotado. Tente com menos variações.';
  }

  if (httpStatus == 401 ||
      httpStatus == 403 ||
      lower.contains(' 401') ||
      lower.contains(' 403') ||
      lower.contains('invalid_api_key') ||
      lower.contains('unauthorized') ||
      lower.contains('forbidden')) {
    return 'Chave de API inválida. Verifique nas configurações.';
  }

  if (httpStatus == 429 ||
      lower.contains(' 429') ||
      lower.contains('rate_limit') ||
      lower.contains('rate limit') ||
      lower.contains('too many requests')) {
    return 'Limite de uso atingido. Aguarde alguns minutos.';
  }

  return 'Erro ao gerar. Tente novamente.';
}
