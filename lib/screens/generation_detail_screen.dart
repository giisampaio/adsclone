import 'package:adscloneia/models/generation.dart';
import 'package:adscloneia/models/variant.dart';
import 'package:adscloneia/services/generation_service.dart';
import 'package:adscloneia/theme/app_palette.dart';
import 'package:adscloneia/widgets/constrained_page.dart';
import 'package:adscloneia/widgets/status_badge.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

/// Detalhe web-first: header + grid de variações com thumbnails.
class GenerationDetailScreen extends StatefulWidget {
  const GenerationDetailScreen({
    super.key,
    required this.service,
    required this.generation,
  });

  final GenerationService service;
  final Generation generation;

  @override
  State<GenerationDetailScreen> createState() => _GenerationDetailScreenState();
}

class _GenerationDetailScreenState extends State<GenerationDetailScreen> {
  final List<Variant> _variants = [];
  bool _loading = true;
  RealtimeChannel? _channel;

  Generation get _g => widget.generation;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    try {
      final list = await widget.service.fetchVariants(_g.id);
      if (mounted) {
        setState(() {
          _variants
            ..clear()
            ..addAll(list);
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }

    _channel = widget.service.subscribeVariants(
      generationId: _g.id,
      onVariant: _upsertVariant,
    );
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
    });
  }

  Future<void> _discard(Variant v) async {
    try {
      await widget.service.discardVariant(v.id);
      if (mounted) {
        setState(() => _variants.removeWhere((e) => e.id == v.id));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível descartar.')),
        );
      }
    }
  }

  Future<void> _downloadVariant(Variant v) async {
    final uri = Uri.tryParse(v.imageUrl);
    if (uri == null) return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _downloadAllCompleted() async {
    final urls = _variants
        .where((v) =>
            v.imageUrl.isNotEmpty &&
            (v.status.toLowerCase() == 'complete' ||
                v.status.toLowerCase() == 'completed'))
        .map((v) => v.imageUrl)
        .toList();
    if (urls.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nenhuma imagem pronta para baixar.')),
        );
      }
      return;
    }
    for (final u in urls) {
      final uri = Uri.tryParse(u);
      if (uri != null && await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
    if (mounted && urls.length > 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${urls.length} imagens abertas no navegador para salvar.'),
        ),
      );
    }
  }

  Future<void> _confirmDeleteProject() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final d = ctx.p;
        return AlertDialog(
          backgroundColor: d.surface,
          title: Text(
            'Excluir projeto?',
            style: GoogleFonts.dmSans(
              fontWeight: FontWeight.w700,
              color: d.text,
            ),
          ),
          content: Text(
            'Isso remove o projeto, todas as variações e os arquivos no armazenamento. Não dá para desfazer.',
            style: GoogleFonts.dmSans(color: d.muted, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('Cancelar', style: GoogleFonts.dmSans(color: d.muted)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(
                'Excluir',
                style: GoogleFonts.dmSans(
                  color: StatusBadgeColors.failed,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );
    if (ok != true || !mounted) return;
    try {
      await widget.service.deleteGeneration(_g.id);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao excluir: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    final c = _channel;
    if (c != null) {
      widget.service.removeChannel(c);
    }
    super.dispose();
  }

  static String _formatDate(DateTime d) {
    final local = d.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}/'
        '${local.year} · '
        '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
  }

  static String _projectTitle(Generation g) {
    final d = g.createdAt.toLocal();
    return 'Projeto · ${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  static String _providerLine(Generation _) {
    return 'IA: Google Gemini (2.5 Flash / Flash Image)';
  }

  int _gridColumns(double width) {
    if (width <= 600) return 1;
    if (width <= 900) return 2;
    return 3;
  }

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    return Scaffold(
      backgroundColor: p.background,
      appBar: AppBar(
        title: Text(
          'Projeto',
          style: GoogleFonts.dmSans(fontWeight: FontWeight.w700),
        ),
        actions: [
          TextButton.icon(
            onPressed: _downloadAllCompleted,
            icon: Icon(Icons.download_rounded, size: 20, color: p.secondary),
            label: Text(
              'Baixar todas',
              style: GoogleFonts.dmSans(
                fontWeight: FontWeight.w600,
                color: p.secondary,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Excluir projeto',
            onPressed: _confirmDeleteProject,
            icon: Icon(Icons.delete_outline_rounded, color: p.tertiary),
          ),
        ],
      ),
      body: MaxWidthBox(
        maxWidth: 1200,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 24),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final innerW = constraints.maxWidth;
                    final isNarrow = innerW < 640;
                    if (isNarrow) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _OriginalPreview(url: _g.originalImageUrl),
                          const SizedBox(height: 20),
                          _ProjectInfoPanel(
                            generation: _g,
                            variantCountInGallery: _variants.length,
                            projectTitle: _projectTitle(_g),
                            formatDate: _formatDate,
                            providerLine: _providerLine(_g),
                          ),
                        ],
                      );
                    }
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _OriginalPreview(url: _g.originalImageUrl),
                        const SizedBox(width: 28),
                        Expanded(
                          child: _ProjectInfoPanel(
                            generation: _g,
                            variantCountInGallery: _variants.length,
                            projectTitle: _projectTitle(_g),
                            formatDate: _formatDate,
                            providerLine: _providerLine(_g),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
            if (_loading && _variants.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Shimmer.fromColors(
                    baseColor: p.surface,
                    highlightColor: p.muted.withValues(alpha: 0.2),
                    child: Container(
                      height: 220,
                      decoration: BoxDecoration(
                        color: p.surface,
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ),
            if (_variants.isNotEmpty)
              SliverPadding(
                padding: const EdgeInsets.only(bottom: 40),
                sliver: SliverLayoutBuilder(
                  builder: (context, constraints) {
                    final cols = _gridColumns(constraints.crossAxisExtent);
                    return SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: cols,
                        mainAxisSpacing: 20,
                        crossAxisSpacing: 20,
                        childAspectRatio: 0.72,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final v = _variants[index];
                          return _VariationCard(
                            variant: v,
                            onDownload: () => _downloadVariant(v),
                            onDiscard: () => _discard(v),
                          );
                        },
                        childCount: _variants.length,
                      ),
                    );
                  },
                ),
              ),
            if (!_loading && _variants.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Center(
                    child: Text(
                      'Aguardando variações…\nElas aparecem aqui em tempo real.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.dmSans(
                        color: p.muted,
                        height: 1.45,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _OriginalPreview extends StatelessWidget {
  const _OriginalPreview({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 300, maxHeight: 300),
        child: AspectRatio(
          aspectRatio: 1,
          child: CachedNetworkImage(
            imageUrl: url,
            fit: BoxFit.cover,
            placeholder: (context, u) => Shimmer.fromColors(
              baseColor: p.surface,
              highlightColor: p.muted.withValues(alpha: 0.25),
              child: Container(color: p.surface),
            ),
            errorWidget: (context, u, e) => Container(
              color: p.surface,
              alignment: Alignment.center,
              child: Icon(Icons.image_not_supported_outlined,
                  color: p.muted, size: 40),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProjectInfoPanel extends StatelessWidget {
  const _ProjectInfoPanel({
    required this.generation,
    required this.variantCountInGallery,
    required this.projectTitle,
    required this.formatDate,
    required this.providerLine,
  });

  final Generation generation;
  final int variantCountInGallery;
  final String projectTitle;
  final String Function(DateTime) formatDate;
  final String providerLine;

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          projectTitle,
          style: GoogleFonts.dmSans(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: p.text,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 12),
        StatusBadge(status: generation.status),
        const SizedBox(height: 16),
        _infoRow(
          p,
          'Data',
          formatDate(generation.createdAt),
          GoogleFonts.dmSans(fontSize: 14, color: p.text, height: 1.35),
        ),
        const SizedBox(height: 8),
        _infoRow(
          p,
          'Provedores',
          providerLine,
          GoogleFonts.dmSans(fontSize: 14, color: p.text, height: 1.35),
        ),
        const SizedBox(height: 8),
        _infoRow(
          p,
          'Quantidade',
          '${generation.variantCount} pedidas · $variantCountInGallery na galeria',
          p.mono(fontSize: 14, weight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _infoRow(AppPalette p, String label, String value, TextStyle valueStyle) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 108,
          child: Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: 13,
              color: p.muted,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: valueStyle,
          ),
        ),
      ],
    );
  }
}

class _VariationCard extends StatelessWidget {
  const _VariationCard({
    required this.variant,
    required this.onDownload,
    required this.onDiscard,
  });

  final Variant variant;
  final VoidCallback onDownload;
  final VoidCallback onDiscard;

  bool get _hasImage =>
      variant.imageUrl.isNotEmpty &&
      (variant.status.toLowerCase() == 'complete' ||
          variant.status.toLowerCase() == 'completed');

  bool get _isGenerating {
    final s = variant.status.toLowerCase();
    return (s == 'processing' || s == 'pending' || s == 'generating') &&
        variant.imageUrl.isEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    final direction = (variant.direction != null && variant.direction!.isNotEmpty)
        ? variant.direction!
        : 'Variação';

    return Container(
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: _buildThumb(context, p),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  direction,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: p.text,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 8),
                StatusBadge(status: variant.status),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _hasImage ? onDownload : null,
                        icon: const Icon(Icons.download_rounded, size: 18),
                        label: const Text('Baixar'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: p.secondary,
                          side: BorderSide(color: p.secondary),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      tooltip: 'Descartar',
                      onPressed: onDiscard,
                      icon: const Icon(Icons.delete_outline_rounded),
                      color: p.tertiary,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThumb(BuildContext context, AppPalette p) {
    if (_hasImage) {
      return CachedNetworkImage(
        imageUrl: variant.imageUrl,
        fit: BoxFit.cover,
        placeholder: (context, url) => Shimmer.fromColors(
          baseColor: p.surface,
          highlightColor: p.muted.withValues(alpha: 0.28),
          child: Container(color: p.surface),
        ),
        errorWidget: (context, url, error) => Container(
          color: p.surface,
          alignment: Alignment.center,
          child: Icon(Icons.broken_image_outlined, color: p.muted),
        ),
      );
    }
    if (_isGenerating ||
        variant.status.toLowerCase() == 'processing' ||
        (variant.status.toLowerCase() == 'pending' && variant.imageUrl.isEmpty)) {
      return Shimmer.fromColors(
        baseColor: p.surface,
        highlightColor: StatusBadgeColors.generating.withValues(alpha: 0.35),
        period: const Duration(milliseconds: 1400),
        child: Container(color: p.surface),
      );
    }
    if (variant.status.toLowerCase() == 'failed') {
      return Container(
        color: p.surface,
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded, color: StatusBadgeColors.failed, size: 40),
            const SizedBox(height: 8),
            Text(
              'Falha',
              style: GoogleFonts.dmSans(
                color: StatusBadgeColors.failed,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }
    return Shimmer.fromColors(
      baseColor: p.surface,
      highlightColor: p.muted.withValues(alpha: 0.2),
      child: Container(color: p.surface),
    );
  }
}
