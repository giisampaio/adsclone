import 'package:adscloneia/models/variant.dart';
import 'package:adscloneia/theme/app_palette.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';

class VariantCard extends StatelessWidget {
  const VariantCard({
    super.key,
    required this.variant,
    required this.onDiscard,
  });

  final Variant variant;
  final VoidCallback onDiscard;

  Future<void> _openUrl() async {
    final uri = Uri.tryParse(variant.imageUrl);
    if (uri == null) return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _shareLink(BuildContext context) async {
    try {
      await Share.share(
        variant.imageUrl,
        subject: 'Variação de criativo — adscloneia',
      );
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível compartilhar.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: CachedNetworkImage(
              imageUrl: variant.imageUrl,
              fit: BoxFit.cover,
              placeholder: (context, url) => Shimmer.fromColors(
                baseColor: p.surface,
                highlightColor: p.muted.withValues(alpha: 0.3),
                child: Container(color: p.surface),
              ),
              errorWidget: (context, url, error) => Container(
                color: p.surface,
                alignment: Alignment.center,
                child: Icon(Icons.broken_image_outlined,
                    color: p.muted, size: 40),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (variant.direction != null && variant.direction!.isNotEmpty)
                  Text(
                    variant.direction!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      color: p.muted,
                    ),
                  ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.open_in_new_rounded, size: 20),
                      color: p.secondary,
                      onPressed: _openUrl,
                      tooltip: 'Abrir',
                    ),
                    IconButton(
                      icon: const Icon(Icons.download_rounded, size: 20),
                      color: p.accent,
                      onPressed: () => _shareLink(context),
                      tooltip: 'Baixar / compartilhar',
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, size: 20),
                      color: p.tertiary,
                      onPressed: onDiscard,
                      tooltip: 'Descartar',
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
}
