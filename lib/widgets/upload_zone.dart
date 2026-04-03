import 'package:adscloneia/theme/app_palette.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

typedef OnImagePicked = void Function(XFile file);

/// Tap to pick an image from gallery (or camera on supported platforms).
class UploadZone extends StatelessWidget {
  const UploadZone({
    super.key,
    required this.onImagePicked,
    this.selectedFile,
  });

  final OnImagePicked onImagePicked;
  final XFile? selectedFile;

  Future<void> _pick(BuildContext context, ImageSource source) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: source,
      imageQuality: 88,
      maxWidth: 4096,
      maxHeight: 4096,
    );
    if (file != null) onImagePicked(file);
  }

  void _showSourceSheet(BuildContext context) {
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
                leading: Icon(Icons.photo_library_outlined,
                    color: sheet.secondary),
                title: Text(
                  'Galeria',
                  style: GoogleFonts.dmSans(color: sheet.text),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _pick(context, ImageSource.gallery);
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
                  _pick(context, ImageSource.camera);
                },
              ),
            ],
          ),
        ),
      );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    final hasFile = selectedFile != null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showSourceSheet(context),
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: [
                p.surface,
                p.surface.withValues(alpha: 0.85),
              ],
            ),
            border: Border.all(
              color: hasFile ? p.accent : p.muted.withValues(alpha: 0.4),
              width: hasFile ? 2 : 1.2,
            ),
            boxShadow: hasFile
                ? [
                    BoxShadow(
                      color: p.accent.withValues(alpha: 0.25),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          child: SizedBox(
            height: 200,
            width: double.infinity,
            child: Center(
              child: hasFile
                  ? Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.check_circle_rounded,
                            color: p.secondary,
                            size: 40,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            selectedFile!.name,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.dmSans(
                              color: p.text,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Toque para trocar',
                            style: GoogleFonts.dmSans(
                              color: p.muted,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ShaderMask(
                          shaderCallback: (bounds) =>
                              p.heroGradient.createShader(bounds),
                          child: const Icon(
                            Icons.cloud_upload_rounded,
                            size: 52,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Toque para enviar criativo',
                          style: GoogleFonts.dmSans(
                            color: p.text,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'PNG, JPG ou WebP',
                          style: GoogleFonts.dmSans(
                            color: p.muted,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
