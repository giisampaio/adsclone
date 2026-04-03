import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:adscloneia/models/generation.dart';
import 'package:adscloneia/models/variant.dart';
import 'package:adscloneia/utils/generation_error_message.dart';
import 'package:adscloneia/screens/generation_detail_screen.dart';
import 'package:adscloneia/services/generation_service.dart';
import 'package:adscloneia/theme/app_palette.dart';
import 'package:adscloneia/widgets/constrained_page.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Três estados: upload + quantidade → gerando (Realtime) → concluído.
enum _CreatePhase {
  config,
  generating,
  complete,
}

const _quantityChoices = [1, 2, 3, 4, 5, 6, 8, 10, 15, 20];

class CreateScreen extends StatefulWidget {
  const CreateScreen({super.key, required this.service});

  final GenerationService? service;

  @override
  State<CreateScreen> createState() => _CreateScreenState();
}

class _CreateScreenState extends State<CreateScreen>
    with TickerProviderStateMixin {
  static const _earlyPhaseSeconds = 5;
  static const _midPhaseSeconds = 5;
  static const _secondsPerVariantEstimate = 15;

  XFile? _file;
  Uint8List? _previewBytes;
  String? _error;

  _CreatePhase _phase = _CreatePhase.config;
  Generation? _gen;
  final List<Variant> _variants = [];
  RealtimeChannel? _realtimeChannel;

  int _quantity = 5;

  Timer? _genProgressTimer;
  DateTime? _generatingSince;
  DateTime? _allVariantsReadyAt;

  late final AnimationController _floatCtrl;
  late final AnimationController _shimmerCtrl;
  late final AnimationController _introCtrl;
  late final AnimationController _iconPulseCtrl;
  late final AnimationController _checkCtrl;
  late final AnimationController _confettiCtrl;

  int get _targetCount => _quantity;

  double get _readyCount =>
      _variants.where((v) => v.imageUrl.isNotEmpty).length.toDouble();

  int get _readyInt => _readyCount.toInt();

  double get _elapsedGeneratingSec {
    final s = _generatingSince;
    if (s == null) return 0;
    return DateTime.now().difference(s).inMilliseconds / 1000.0;
  }

  /// 0–15% (~0–5s), 15–30% (~5–10s); depois 30–90% pelas variações; 90–100% finalização.
  double get _displayGeneratingProgress {
    final t = _targetCount;
    if (t <= 0) return 0.02;
    final ready = _readyInt;
    final e = _elapsedGeneratingSec;

    double early;
    if (e < _earlyPhaseSeconds) {
      early = (e / _earlyPhaseSeconds) * 0.15;
    } else if (e < _earlyPhaseSeconds + _midPhaseSeconds) {
      final u = (e - _earlyPhaseSeconds) / _midPhaseSeconds;
      early = 0.15 + u * 0.15;
    } else {
      early = 0.30;
    }

    final mid = 0.30 + (ready / t) * 0.60;

    if (ready < t) {
      if (e < _earlyPhaseSeconds + _midPhaseSeconds) {
        return early.clamp(0.02, 1.0);
      }
      return mid.clamp(0.02, 0.90);
    }

    final mark = _allVariantsReadyAt;
    if (mark != null) {
      const finMs = 700.0;
      final u = (DateTime.now().difference(mark).inMilliseconds / finMs)
          .clamp(0.0, 1.0);
      return (0.90 + 0.10 * u).clamp(0.02, 1.0);
    }
    return mid.clamp(0.02, 0.90);
  }

  @override
  void initState() {
    super.initState();
    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);

    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat();

    _introCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _iconPulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _checkCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _confettiCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _introCtrl.forward();
    });
  }

  @override
  void dispose() {
    _stopGenerationProgress();
    _floatCtrl.dispose();
    _shimmerCtrl.dispose();
    _introCtrl.dispose();
    _iconPulseCtrl.dispose();
    _checkCtrl.dispose();
    _confettiCtrl.dispose();
    unawaited(_detachRealtime());
    super.dispose();
  }

  Future<void> _detachRealtime() async {
    final ch = _realtimeChannel;
    _realtimeChannel = null;
    if (ch != null && widget.service != null) {
      await widget.service!.removeChannel(ch);
    }
  }

  void _startGenerationProgress() {
    _generatingSince = DateTime.now();
    _allVariantsReadyAt = null;
    _genProgressTimer?.cancel();
    _genProgressTimer = Timer.periodic(const Duration(milliseconds: 120), (_) {
      if (!mounted) return;
      final t = _targetCount;
      final ready = _readyInt;
      if (t > 0 && ready >= t && _allVariantsReadyAt == null) {
        _allVariantsReadyAt = DateTime.now();
      }
      setState(() {});
    });
  }

  void _stopGenerationProgress() {
    _genProgressTimer?.cancel();
    _genProgressTimer = null;
    _generatingSince = null;
    _allVariantsReadyAt = null;
  }

  void _upsertVariant(Variant v) {
    if (!mounted) return;
    setState(() {
      final i = _variants.indexWhere((e) => e.id == v.id);
      if (v.status == 'discarded') {
        if (i >= 0) _variants.removeAt(i);
        return;
      }
      if (i >= 0) {
        _variants[i] = v;
      } else {
        _variants.add(v);
      }
      _variants.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      if (_phase == _CreatePhase.generating && _targetCount > 0) {
        final readyNow =
            _variants.where((x) => x.imageUrl.isNotEmpty).length;
        if (readyNow >= _targetCount && _allVariantsReadyAt == null) {
          _allVariantsReadyAt = DateTime.now();
        }
      }
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: source,
      imageQuality: 88,
      maxWidth: 4096,
      maxHeight: 4096,
    );
    if (file == null || !mounted) return;
    final bytes = await file.readAsBytes();
    if (!mounted) return;
    setState(() {
      _file = file;
      _previewBytes = bytes;
      _error = null;
    });
  }

  void _showSourceSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: context.p.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final sheet = ctx.p;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading:
                      Icon(Icons.photo_library_outlined, color: sheet.accent),
                  title: Text(
                    'Galeria',
                    style: GoogleFonts.dmSans(color: sheet.text),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickImage(ImageSource.gallery);
                  },
                ),
                ListTile(
                  leading:
                      Icon(Icons.camera_alt_outlined, color: sheet.tertiary),
                  title: Text(
                    'Câmera',
                    style: GoogleFonts.dmSans(color: sheet.text),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickImage(ImageSource.camera);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _runGeneration() async {
    final svc = widget.service;
    if (svc == null) {
      setState(() => _error = 'Sessão inválida. Faça login novamente.');
      return;
    }
    final file = _file;
    if (file == null) {
      setState(() => _error = 'Selecione uma imagem.');
      return;
    }

    setState(() {
      _error = null;
      _phase = _CreatePhase.generating;
      _variants.clear();
    });
    _startGenerationProgress();

    try {
      final url = await svc.uploadXFile(file);
      final gen = await svc.createGeneration(
        originalImageUrl: url,
        variantCount: _quantity,
        status: 'pending',
      );
      if (!mounted) return;
      setState(() => _gen = gen);

      _realtimeChannel = svc.subscribeVariants(
        generationId: gen.id,
        onVariant: _upsertVariant,
      );

      final existing = await svc.fetchVariants(gen.id);
      if (mounted) {
        setState(() {
          _variants
            ..clear()
            ..addAll(existing);
        });
      }

      await svc.runFullGeneration(
        generationId: gen.id,
        variantCount: _quantity,
      );

      final finalList = await svc.fetchVariants(gen.id);
      if (!mounted) return;
      setState(() {
        _variants
          ..clear()
          ..addAll(finalList);
      });

      final updated = await svc.fetchGeneration(gen.id);
      if (mounted) setState(() => _gen = updated);

      _stopGenerationProgress();
      await _detachRealtime();

      if (!mounted) return;
      setState(() => _phase = _CreatePhase.complete);
      _checkCtrl.forward(from: 0);
    } catch (e) {
      _stopGenerationProgress();
      await _detachRealtime();
      if (mounted) {
        setState(() {
          _error = e is GenerationFailedException
              ? e.userMessage
              : e is StateError
                  ? e.message
                  : friendlyGenerationError(e);
          _phase = _CreatePhase.config;
          _gen = null;
        });
      }
    }
  }

  void _resetForMore() {
    unawaited(_detachRealtime());
    _stopGenerationProgress();
    _checkCtrl.reset();
    setState(() {
      _file = null;
      _previewBytes = null;
      _phase = _CreatePhase.config;
      _gen = null;
      _variants.clear();
      _error = null;
    });
    _introCtrl.forward(from: 0);
  }

  void _openGallery() {
    final gen = _gen;
    final svc = widget.service;
    if (gen == null || svc == null) return;
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => GenerationDetailScreen(
          service: svc,
          generation: gen,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    if (widget.service == null) {
      return ColoredBox(
        color: p.background,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Text(
              'Faça login para criar variações. Configure GEMINI_API_KEY nos Secrets da Edge Function.',
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                color: p.muted,
                height: 1.45,
                fontSize: 15,
              ),
            ),
          ),
        ),
      );
    }

    return ColoredBox(
      color: p.background,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          if (_phase == _CreatePhase.config)
            _FloatingOrbs(animation: _floatCtrl, palette: p),
          if (_phase == _CreatePhase.complete)
            _ConfettiLayer(ctrl: _confettiCtrl, palette: p),
          SafeArea(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 320),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              transitionBuilder: (child, anim) {
                return FadeTransition(opacity: anim, child: child);
              },
              child: switch (_phase) {
                _CreatePhase.config => KeyedSubtree(
                    key: const ValueKey('cfg'),
                    child: _buildConfig(),
                  ),
                _CreatePhase.generating => KeyedSubtree(
                    key: const ValueKey('gen'),
                    child: _buildGenerating(),
                  ),
                _CreatePhase.complete => KeyedSubtree(
                    key: const ValueKey('done'),
                    child: _buildComplete(),
                  ),
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfig() {
    final p = context.p;
    final hasImage = _previewBytes != null;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      child: MaxWidthBox(
        maxWidth: 560,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _staggered(
              index: 0,
              child: RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: GoogleFonts.dmSans(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: p.text,
                    height: 1.15,
                  ),
                  children: const [
                    TextSpan(text: 'Transforme seu criativo\n'),
                    TextSpan(text: 'campeão em '),
                  ],
                ),
              ),
            ),
            _staggered(
              index: 1,
              child: Center(
                child: _ShimmerGradientText(
                  text: 'variações',
                  controller: _shimmerCtrl,
                ),
              ),
            ),
            const SizedBox(height: 12),
            _staggered(
              index: 2,
              child: Text(
                'Envie o anúncio, escolha quantas versões quer e gere tudo de uma vez.',
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  height: 1.45,
                  color: p.muted,
                ),
              ),
            ),
            const SizedBox(height: 28),
            if (!hasImage)
              _staggered(index: 3, child: _uploadZone(p))
            else ...[
              _staggered(
                index: 3,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 240),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Center(
                          child: Image.memory(
                            _previewBytes!,
                            fit: BoxFit.contain,
                          ),
                        ),
                        Positioned(
                          top: 10,
                          right: 10,
                          child: Material(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(10),
                            child: InkWell(
                              onTap: _showSourceSheet,
                              borderRadius: BorderRadius.circular(10),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                child: Text(
                                  'Trocar',
                                  style: GoogleFonts.dmSans(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Quantidade de variações',
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: p.muted,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: _quantityChoices.map((q) {
                  final sel = _quantity == q;
                  return FilterChip(
                    label: Text(
                      '$q',
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        fontWeight: sel ? FontWeight.w800 : FontWeight.w500,
                      ),
                    ),
                    selected: sel,
                    onSelected: (_) => setState(() => _quantity = q),
                    selectedColor: p.accent.withValues(alpha: 0.28),
                    checkmarkColor: p.accent,
                  );
                }).toList(),
              ),
              const SizedBox(height: 28),
              Material(
                borderRadius: BorderRadius.circular(16),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: _runGeneration,
                  child: Ink(
                    height: 54,
                    decoration: BoxDecoration(gradient: p.heroGradient),
                    child: Center(
                      child: Text(
                        'Gerar $_quantity ${_quantity == 1 ? 'variação' : 'variações'}',
                        style: GoogleFonts.dmSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: p.onAccent,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSans(color: p.tertiary, fontSize: 13),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _uploadZone(AppPalette p) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _showSourceSheet,
        borderRadius: BorderRadius.circular(20),
        child: CustomPaint(
          painter: _DashedRoundedRectPainter(
            color: p.border.withValues(alpha: 0.45),
            strokeWidth: 2,
            radius: 20,
            dash: 8,
            gap: 6,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: p.surface,
              borderRadius: const BorderRadius.all(Radius.circular(20)),
            ),
            padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
            child: Column(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: p.accent.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: p.accent.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Icon(
                    Icons.cloud_upload_rounded,
                    size: 48,
                    color: p.accent,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Seu criativo campeão',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.dmSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: p.text,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Toque para enviar • PNG, JPG',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    color: p.muted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _staggered({required int index, required Widget child}) {
    return AnimatedBuilder(
      animation: _introCtrl,
      builder: (context, _) {
        final start = index * 0.12;
        final end = (start + 0.55).clamp(0.0, 1.0);
        final t = Curves.easeOutCubic.transform(
          (((_introCtrl.value - start) / (end - start)).clamp(0.0, 1.0)),
        );
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - t)),
            child: child,
          ),
        );
      },
    );
  }

  String _generatingPhaseMessage() {
    final t = _targetCount;
    final ready = _readyInt;
    final e = _elapsedGeneratingSec;
    if (t <= 0) return '';

    if (ready >= t) {
      return 'Quase lá...';
    }
    if (e < _earlyPhaseSeconds) {
      return 'Analisando seu criativo...';
    }
    if (e < _earlyPhaseSeconds + _midPhaseSeconds) {
      return 'Planejando variações de cores...';
    }
    final x = (ready + 1).clamp(1, t);
    return 'Gerando variação $x de $t...';
  }

  String _generatingCounterLine() {
    final t = _targetCount;
    final ready = _readyInt;
    final e = _elapsedGeneratingSec;
    if (t <= 0) return '';

    if (e < _earlyPhaseSeconds) {
      return 'Analisando...';
    }
    if (e < _earlyPhaseSeconds + _midPhaseSeconds) {
      return 'Planejando variações...';
    }
    return '$ready de $t prontas';
  }

  Widget _buildGenerating() {
    final p = context.p;
    final t = _targetCount;
    final phaseMsg = _generatingPhaseMessage();
    final counterLine = _generatingCounterLine();
    final estSec = t * _secondsPerVariantEstimate;
    final thumbs = _variants
        .where((v) => v.imageUrl.isNotEmpty)
        .map((v) => v.imageUrl)
        .toList();
    final bytes = _previewBytes;
    final progress = _displayGeneratingProgress;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
      child: MaxWidthBox(
        maxWidth: 560,
        child: Column(
          children: [
            if (bytes != null)
              AnimatedBuilder(
                animation: _iconPulseCtrl,
                builder: (context, _) {
                  final glow = 0.5 + 0.5 * _iconPulseCtrl.value;
                  return Container(
                    width: 88,
                    height: 88,
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: p.accent.withValues(alpha: 0.35 * glow),
                          blurRadius: 16,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(13),
                      child: Image.memory(bytes, fit: BoxFit.cover),
                    ),
                  );
                },
              ),
            const SizedBox(height: 24),
            ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: [p.accent, p.secondary],
              ).createShader(bounds),
              child: const Icon(
                Icons.auto_awesome_rounded,
                size: 40,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Gerando variações...',
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: p.text,
              ),
            ),
            const SizedBox(height: 8),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 320),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              child: Text(
                phaseMsg,
                key: ValueKey(phaseMsg),
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  height: 1.4,
                  color: p.muted,
                ),
              ),
            ),
            const SizedBox(height: 24),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: SizedBox(
                height: 4,
                child: Stack(
                  children: [
                    Container(color: p.border.withValues(alpha: 0.5)),
                    FractionallySizedBox(
                      widthFactor: progress.clamp(0.02, 1.0),
                      child: Container(
                        decoration: BoxDecoration(gradient: p.heroGradient),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (thumbs.isNotEmpty) ...[
              const SizedBox(height: 16),
              SizedBox(
                height: 80,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (var i = 0; i < thumbs.length; i++) ...[
                        if (i > 0) const SizedBox(width: 10),
                        _AnimatedVariantThumb(
                          key: ValueKey(thumbs[i]),
                          imageUrl: thumbs[i],
                          palette: p,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Text(
              '${(progress * 100).round().clamp(0, 100)}%',
              style: p.mono(fontSize: 12, color: p.muted),
            ),
            const SizedBox(height: 6),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 280),
              child: Text(
                counterLine,
                key: ValueKey(counterLine),
                textAlign: TextAlign.center,
                style: p.mono(
                  fontSize: 12,
                  color: const Color(0xFF00E676),
                  weight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Tempo estimado: ~$estSec segundos',
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                fontSize: 12,
                height: 1.35,
                color: p.muted.withValues(alpha: 0.85),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComplete() {
    final p = context.p;
    final urls = _variants
        .where((v) => v.imageUrl.isNotEmpty)
        .map((v) => v.imageUrl)
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 32, 20, 40),
      child: MaxWidthBox(
        maxWidth: 560,
        child: Column(
          children: [
            ScaleTransition(
              scale: CurvedAnimation(
                parent: _checkCtrl,
                curve: const Interval(0, 0.65, curve: Curves.elasticOut),
              ),
              child: Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      p.accent.withValues(alpha: 0.3),
                      p.secondary.withValues(alpha: 0.25),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: p.accent.withValues(alpha: 0.35),
                      blurRadius: 24,
                    ),
                  ],
                ),
                child: Icon(Icons.check_rounded, size: 52, color: p.text),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Variações prontas!',
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: p.text,
              ),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: urls.map((u) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: u,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    errorWidget: (context, url, error) => ColoredBox(
                      color: p.surface,
                      child: Icon(Icons.broken_image_outlined, color: p.dim),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: _openGallery,
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                'Ver galeria completa',
                style: GoogleFonts.dmSans(fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: _resetForMore,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                'Gerar mais',
                style: GoogleFonts.dmSans(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnimatedVariantThumb extends StatelessWidget {
  const _AnimatedVariantThumb({
    super.key,
    required this.imageUrl,
    required this.palette,
  });

  final String imageUrl;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    final p = palette;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 480),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) {
        return Opacity(
          opacity: t,
          child: Transform.scale(
            scale: 0.82 + 0.18 * t,
            alignment: Alignment.center,
            child: child,
          ),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          width: 80,
          height: 80,
          fit: BoxFit.cover,
          errorWidget: (context, url, error) => ColoredBox(
            color: p.surface,
            child: Icon(Icons.broken_image_outlined, color: p.dim),
          ),
        ),
      ),
    );
  }
}

class _FloatingOrbs extends StatelessWidget {
  const _FloatingOrbs({required this.animation, required this.palette});

  final Animation<double> animation;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, _) {
          final t = animation.value;
          final dy1 = math.sin(t * math.pi) * 18;
          final dy2 = math.sin((t + 0.35) * math.pi) * 22;
          final dy3 = math.sin((t + 0.7) * math.pi) * 14;
          final p = palette;
          return Stack(
            children: [
              Positioned(top: 80 + dy1, right: -40, child: _orb(160, p.accent)),
              Positioned(top: 220 + dy2, left: -50, child: _orb(140, p.secondary)),
              Positioned(bottom: 120 + dy3, right: 20, child: _orb(120, p.tertiary)),
            ],
          );
        },
      ),
    );
  }

  Widget _orb(double size, Color c) {
    return Opacity(
      opacity: 0.12,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [c, c.withValues(alpha: 0)],
          ),
        ),
      ),
    );
  }
}

class _ShimmerGradientText extends StatelessWidget {
  const _ShimmerGradientText({
    required this.text,
    required this.controller,
  });

  final String text;
  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final shift = controller.value * 2 - 1;
        return ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) {
            return LinearGradient(
              colors: const [
                Color(0xFF6C5CE7),
                Color(0xFF00CEFF),
                Color(0xFFFF6B9D),
                Color(0xFF6C5CE7),
              ],
              stops: const [0, 0.35, 0.65, 1],
              transform: GradientTranslation(shift * 0.5, 0),
            ).createShader(bounds);
          },
          child: Text(
            text,
            style: GoogleFonts.dmSans(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        );
      },
    );
  }
}

class GradientTranslation extends GradientTransform {
  const GradientTranslation(this.dx, this.dy);
  final double dx;
  final double dy;

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(dx * bounds.width, dy * bounds.height, 0);
  }
}

class _DashedRoundedRectPainter extends CustomPainter {
  _DashedRoundedRectPainter({
    required this.color,
    required this.strokeWidth,
    required this.radius,
    required this.dash,
    required this.gap,
  });

  final Color color;
  final double strokeWidth;
  final double radius;
  final double dash;
  final double gap;

  @override
  void paint(Canvas canvas, Size size) {
    final r = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        strokeWidth / 2,
        strokeWidth / 2,
        size.width - strokeWidth,
        size.height - strokeWidth,
      ),
      Radius.circular(radius),
    );
    final path = Path()..addRRect(r);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final metrics = path.computeMetrics();
    for (final m in metrics) {
      double d = 0;
      while (d < m.length) {
        final double next = (d + dash).clamp(0.0, m.length);
        final extract = m.extractPath(d, next);
        canvas.drawPath(extract, paint);
        d += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRoundedRectPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.radius != radius;
  }
}

class _ConfettiLayer extends StatelessWidget {
  const _ConfettiLayer({required this.ctrl, required this.palette});

  final AnimationController ctrl;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    final p = palette;
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: ctrl,
        builder: (context, _) {
          final rnd = math.Random(42);
          return Stack(
            children: List.generate(18, (i) {
              rnd.nextDouble();
              final x = rnd.nextDouble();
              final y = rnd.nextDouble();
              final phase = rnd.nextDouble();
              final o = 0.15 +
                  0.2 *
                      math.sin(
                        (ctrl.value * math.pi * 2) + phase * math.pi * 2,
                      );
              return Positioned(
                left: x * MediaQuery.sizeOf(context).width,
                top: y * MediaQuery.sizeOf(context).height * 0.65,
                child: Opacity(
                  opacity: o.clamp(0.0, 0.45),
                  child: Text(
                    i.isEven ? '✦' : '·',
                    style: TextStyle(
                      fontSize: i.isEven ? 14 : 8,
                      color: i.isEven ? p.accent : p.secondary,
                    ),
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}
