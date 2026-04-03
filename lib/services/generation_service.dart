import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:adscloneia/config/supabase_config.dart';
import 'package:http/http.dart' as http;
import 'package:adscloneia/models/brand_profile.dart';
import 'package:adscloneia/models/creative_analysis.dart';
import 'package:adscloneia/models/creative_briefing.dart';
import 'package:adscloneia/models/creative_direction_item.dart';
import 'package:adscloneia/models/generation.dart';
import 'package:adscloneia/models/variant.dart';
import 'package:adscloneia/utils/generation_error_message.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:supabase_flutter/supabase_flutter.dart';

/// Uploads creatives, manages [generations] / [variants], invokes Edge Functions, Realtime.
class GenerationService {
  GenerationService({SupabaseClient? client}) : _clientOverride = client;

  final SupabaseClient? _clientOverride;

  SupabaseClient get _client =>
      _clientOverride ?? Supabase.instance.client;

  String get _userId {
    final id = _client.auth.currentUser?.id;
    if (id == null || id.isEmpty) {
      throw StateError('Sessão expirada. Faça login novamente.');
    }
    return id;
  }

  /// Web-safe unique prefix (evita `1 << 32` em JS, onde vira 0 e quebra `Random.nextInt`).
  String _uniqueFolder() =>
      DateTime.now().microsecondsSinceEpoch.toString();

  /// Nome no storage: sempre `timestamp.jpg` (web-safe; MIME real em [contentType]).
  String _jpegFilenameForUpload() =>
      '${DateTime.now().millisecondsSinceEpoch}.jpg';

  String _contentTypeForPath(String filePath) {
    final ext = p.extension(filePath).toLowerCase();
    switch (ext) {
      case '.png':
        return 'image/png';
      case '.webp':
        return 'image/webp';
      case '.gif':
        return 'image/gif';
      default:
        return 'image/jpeg';
    }
  }

  /// Uploads raw bytes to bucket [SupabaseConfig.creativesBucket]. Returns public URL.
  /// Path: `{user_id}/{folder}/{file}` (RLS no storage).
  Future<String> uploadImageBytes({
    required List<int> bytes,
    required String filename,
    String? contentType,
  }) async {
    final uid = _userId;
    final objectPath =
        '$uid/${_uniqueFolder()}/${p.basename(filename)}'.replaceAll(' ', '_');
    final ct = contentType ?? _contentTypeForPath(filename);

    await _client.storage.from(SupabaseConfig.creativesBucket).uploadBinary(
          objectPath,
          Uint8List.fromList(bytes),
          fileOptions: FileOptions(contentType: ct, upsert: true),
        );

    return _client.storage
        .from(SupabaseConfig.creativesBucket)
        .getPublicUrl(objectPath);
  }

  /// Upload from a picked gallery/camera file (mobile/desktop/web).
  Future<String> uploadXFile(XFile file) async {
    final bytes = await file.readAsBytes();
    if (bytes.isEmpty) {
      throw StateError(
        'Não foi possível ler a imagem (0 bytes). Tente escolher o arquivo de novo.',
      );
    }
    final filename = _jpegFilenameForUpload();
    return uploadImageBytes(
      bytes: bytes,
      filename: filename,
      contentType: file.mimeType,
    );
  }

  /// Upload from a local [File] path.
  Future<String> uploadFile(File file) async {
    final bytes = await file.readAsBytes();
    return uploadImageBytes(
      bytes: bytes,
      filename: file.path,
    );
  }

  /// Creates a generation row com [user_id] do utilizador autenticado.
  Future<Generation> createGeneration({
    required String originalImageUrl,
    required int variantCount,
    String status = 'pending',
  }) async {
    final row = await _client
        .from('generations')
        .insert({
          'user_id': _userId,
          'original_image_url': originalImageUrl,
          'variant_count': variantCount,
          'status': status,
        })
        .select()
        .single();

    return Generation.fromJson(Map<String, dynamic>.from(row));
  }

  Future<void> updateGenerationStatus(String id, String status) async {
    await _client.from('generations').update({'status': status}).eq('id', id);
  }

  Future<Generation> fetchGeneration(String id) async {
    final row = await _client
        .from('generations')
        .select()
        .eq('id', id)
        .single();
    return Generation.fromJson(Map<String, dynamic>.from(row));
  }

  Future<List<BrandProfile>> fetchBrandProfiles() async {
    final rows = await _client
        .from('brand_profiles')
        .select()
        .order('created_at', ascending: false);
    final list = rows as List<dynamic>;
    return list
        .map((e) => BrandProfile.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<BrandProfile> insertBrandProfile(BrandProfile profile) async {
    final row = await _client
        .from('brand_profiles')
        .insert({
          ...profile.toInsertJson(),
          'user_id': _userId,
        })
        .select()
        .single();
    return BrandProfile.fromJson(Map<String, dynamic>.from(row));
  }

  Future<void> updateBrandProfile(BrandProfile profile) async {
    await _client
        .from('brand_profiles')
        .update(profile.toUpdateJson())
        .eq('id', profile.id);
  }

  Future<void> deleteBrandProfile(String id) async {
    await _client.from('brand_profiles').delete().eq('id', id);
  }

  /// `mode: analyze` — retorna análise estruturada (e persiste em `generations.analysis` se existir coluna).
  Future<CreativeAnalysis> analyzeCreative({
    required String generationId,
    required CreativeBriefing briefing,
  }) async {
    final map = await _postGenerateVariants({
      'mode': 'analyze',
      'generation_id': generationId,
      'briefing': briefing.toJson(),
    });
    final raw = map['analysis'];
    if (raw is! Map) {
      throw StateError('Resposta sem analysis: $map');
    }
    return CreativeAnalysis.fromJson(Map<String, dynamic>.from(raw));
  }

  /// `mode: directions` — gera lista de direções criativas.
  Future<List<CreativeDirectionItem>> generateDirections({
    required String generationId,
    required CreativeAnalysis analysis,
    required CreativeBriefing briefing,
  }) async {
    final map = await _postGenerateVariants({
      'mode': 'directions',
      'generation_id': generationId,
      'analysis': analysis.toJson(),
      'briefing': briefing.toJson(),
    });
    final raw = map['directions'];
    if (raw is! List) {
      throw StateError('Resposta sem directions: $map');
    }
    return raw.map((e) {
      final m = Map<String, dynamic>.from(e as Map);
      final dir = m['direction']?.toString().trim();
      final title = m['title']?.toString().trim();
      final ch = m['changes']?.toString().trim();
      final desc = m['description']?.toString().trim();
      return CreativeDirectionItem.generated(
        direction: (dir != null && dir.isNotEmpty) ? dir : (title ?? ''),
        changes: (ch != null && ch.isNotEmpty) ? ch : (desc ?? ''),
        prompt: m['prompt']?.toString() ?? '',
      );
    }).toList();
  }

  /// `mode: generate` — só direções ativas com prompt; apaga variants anteriores e gera imagens.
  Future<void> generateVariants({
    required String generationId,
    required CreativeAnalysis analysis,
    required CreativeBriefing briefing,
    required List<CreativeDirectionItem> directions,
  }) async {
    await _postGenerateVariants({
      'mode': 'generate',
      'generation_id': generationId,
      'analysis': analysis.toJson(),
      'briefing': briefing.toJson(),
      'directions': directions.map((e) => e.toWireJson()).toList(),
    });
  }

  /// `mode: full` (ou default sem `directions`) — analisa, gera N direções e imagens numa única chamada.
  Future<void> runFullGeneration({
    required String generationId,
    int? variantCount,
  }) async {
    await _postGenerateVariants({
      'mode': 'full',
      'generation_id': generationId,
      'variant_count': ?variantCount,
    });
  }

  Future<Map<String, dynamic>> _postGenerateVariants(
    Map<String, dynamic> body,
  ) async {
    final session = _client.auth.currentSession;
    if (session == null) {
      throw GenerationFailedException(
        friendlyGenerationError('Sessão expirada', httpStatus: 401),
      );
    }

    final merged = Map<String, dynamic>.from(body);

    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${session.accessToken}',
      'apikey': SupabaseConfig.anonKey,
    };

    final url =
        '${SupabaseConfig.url}/functions/v1/${SupabaseConfig.generateVariantsFunction}';
    final response = await http.post(
      Uri.parse(url),
      headers: headers,
      body: jsonEncode(merged),
    );

    Map<String, dynamic> map;
    try {
      map = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw GenerationFailedException(
        friendlyGenerationError(
          response.body.isNotEmpty ? response.body : 'HTTP ${response.statusCode}',
          httpStatus: response.statusCode,
        ),
      );
    }

    if (response.statusCode != 200) {
      final err = map['error']?.toString() ?? response.body;
      throw GenerationFailedException(
        friendlyGenerationError(err, httpStatus: response.statusCode),
      );
    }
    if (map['success'] == false && map['error'] != null) {
      throw GenerationFailedException(
        friendlyGenerationError(
          map['error'],
          httpStatus: response.statusCode,
        ),
      );
    }
    if (map['error'] != null) {
      throw GenerationFailedException(
        friendlyGenerationError(
          map['error'],
          httpStatus: response.statusCode,
        ),
      );
    }
    return map;
  }

  Future<List<Variant>> fetchVariants(String generationId) async {
    final rows = await _client
        .from('variants')
        .select()
        .eq('generation_id', generationId)
        .order('created_at', ascending: true);

    final list = rows as List<dynamic>;
    return list
        .map((e) => Variant.fromJson(Map<String, dynamic>.from(e as Map)))
        .where((v) => v.status != 'discarded')
        .toList();
  }

  Future<List<Generation>> fetchGenerations({int limit = 50}) async {
    final rows = await _client
        .from('generations')
        .select()
        .order('created_at', ascending: false)
        .limit(limit);

    final list = rows as List<dynamic>;
    return list
        .map((e) => Generation.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  /// Up to [limitPerGen] non-empty image URLs per generation (non-discarded).
  Future<Map<String, List<String>>> fetchPreviewImageUrlsByGenerationIds(
    Iterable<String> generationIds, {
    int limitPerGen = 6,
  }) async {
    final ids = generationIds.toList();
    if (ids.isEmpty) return {};

    final rows = await _client
        .from('variants')
        .select('generation_id, image_url, status, created_at')
        .inFilter('generation_id', ids);

    final list = rows as List<dynamic>;
    final grouped = <String, List<({DateTime t, String url})>>{};
    for (final raw in list) {
      final m = Map<String, dynamic>.from(raw as Map);
      if ((m['status'] as String?) == 'discarded') continue;
      final url = m['image_url']?.toString() ?? '';
      if (url.isEmpty) continue;
      final gid = m['generation_id']?.toString() ?? '';
      if (gid.isEmpty) continue;
      final t = DateTime.tryParse(m['created_at']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0);
      grouped.putIfAbsent(gid, () => []).add((t: t, url: url));
    }

    final out = <String, List<String>>{};
    for (final e in grouped.entries) {
      e.value.sort((a, b) => a.t.compareTo(b.t));
      out[e.key] = e.value
          .take(limitPerGen)
          .map((x) => x.url)
          .toList(growable: false);
    }
    return out;
  }

  /// Public storage object path from a bucket public URL, or null.
  static String? storagePathFromPublicUrl(String url, String bucket) {
    if (url.isEmpty) return null;
    final marker = '/object/public/$bucket/';
    final i = url.indexOf(marker);
    if (i < 0) return null;
    final rest = url.substring(i + marker.length).split('?').first;
    return Uri.decodeComponent(rest);
  }

  /// Deletes the generation row (cascade variants if configured), removes related
  /// objects from [creativesBucket] (original + variant files + folder listing).
  Future<void> deleteGeneration(String generationId) async {
    final bucket = SupabaseConfig.creativesBucket;
    final paths = <String>{};

    final gen = await _client
        .from('generations')
        .select('original_image_url')
        .eq('id', generationId)
        .maybeSingle();

    if (gen == null) return;

    final orig = gen['original_image_url']?.toString() ?? '';
    final origPath = storagePathFromPublicUrl(orig, bucket);
    if (origPath != null) paths.add(origPath);

    final varRows = await _client
        .from('variants')
        .select('image_url')
        .eq('generation_id', generationId);
    for (final raw in varRows as List<dynamic>) {
      final m = Map<String, dynamic>.from(raw as Map);
      final u = m['image_url']?.toString() ?? '';
      final p = storagePathFromPublicUrl(u, bucket);
      if (p != null) paths.add(p);
    }

    try {
      final listed = await _client.storage.from(bucket).list(path: generationId);
      for (final f in listed) {
        if (f.name.isNotEmpty) {
          paths.add('$generationId/${f.name}');
        }
      }
    } catch (_) {
      // ignore list errors (e.g. empty prefix)
    }

    try {
      final prefix = 'variants/$generationId';
      final listedV = await _client.storage.from(bucket).list(path: prefix);
      for (final f in listedV) {
        if (f.name.isNotEmpty) {
          paths.add('$prefix/${f.name}');
        }
      }
    } catch (_) {
      // ignore
    }

    if (paths.isNotEmpty) {
      try {
        await _client.storage.from(bucket).remove(paths.toList());
      } catch (_) {
        // best-effort storage cleanup
      }
    }

    await _client.from('variants').delete().eq('generation_id', generationId);
    await _client.from('generations').delete().eq('id', generationId);
  }

  Future<void> discardVariant(String variantId) async {
    await _client
        .from('variants')
        .update({'status': 'discarded'}).eq('id', variantId);
  }

  /// Subscribes to inserts/updates on `variants` for [generationId].
  RealtimeChannel subscribeVariants({
    required String generationId,
    required void Function(Variant variant) onVariant,
  }) {
    final channel = _client.channel('variants_$generationId');

    void handlePayload(PostgresChangePayload payload) {
      final map = payload.newRecord.isNotEmpty
          ? payload.newRecord
          : payload.oldRecord;
      if (map.isEmpty) return;
      if (map['generation_id']?.toString() != generationId) return;

      try {
        final v = Variant.fromMap(Map<String, dynamic>.from(map));
        if (v.status == 'discarded') return;
        onVariant(v);
      } catch (_) {
        // ignore malformed realtime rows
      }
    }

    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'variants',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'generation_id',
            value: generationId,
          ),
          callback: handlePayload,
        )
        .subscribe();

    return channel;
  }

  Future<void> removeChannel(RealtimeChannel channel) async {
    await _client.removeChannel(channel);
  }
}
