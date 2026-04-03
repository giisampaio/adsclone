import 'package:adscloneia/models/brand_profile.dart';
import 'package:adscloneia/services/generation_service.dart';
import 'package:adscloneia/theme/app_palette.dart';
import 'package:adscloneia/widgets/constrained_page.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Lista e CRUD de perfis de marca (`brand_profiles`).
class BrandProfilesScreen extends StatefulWidget {
  const BrandProfilesScreen({super.key, required this.service});

  final GenerationService service;

  @override
  State<BrandProfilesScreen> createState() => _BrandProfilesScreenState();
}

class _BrandProfilesScreenState extends State<BrandProfilesScreen> {
  List<BrandProfile> _profiles = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await widget.service.fetchBrandProfiles();
      if (mounted) {
        setState(() {
          _profiles = list;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  Future<void> _openEditor({BrandProfile? existing}) async {
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.p.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _BrandProfileEditorSheet(
        palette: ctx.p,
        service: widget.service,
        existing: existing,
        onSaved: _reload,
      ),
    );
    if (created == true && mounted) await _reload();
  }

  Future<void> _confirmDelete(BrandProfile p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Excluir perfil?', style: GoogleFonts.dmSans()),
        content: Text(
          '“${p.name}” será removido permanentemente.',
          style: GoogleFonts.dmSans(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancelar', style: GoogleFonts.dmSans()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Excluir', style: GoogleFonts.dmSans(color: ctx.p.tertiary)),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await widget.service.deleteBrandProfile(p.id);
      await _reload();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString(), style: GoogleFonts.dmSans())),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Perfis de marca',
          style: GoogleFonts.dmSans(fontWeight: FontWeight.w700),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(),
        icon: const Icon(Icons.add_rounded),
        label: Text('Novo perfil', style: GoogleFonts.dmSans(fontWeight: FontWeight.w600)),
      ),
      body: ColoredBox(
        color: p.background,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.dmSans(color: p.tertiary),
                      ),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _reload,
                    child: _profiles.isEmpty
                        ? ListView(
                            children: [
                              SizedBox(
                                height: MediaQuery.sizeOf(context).height * 0.5,
                                child: Center(
                                  child: Text(
                                    'Nenhum perfil salvo.\nToque em “Novo perfil”.',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.dmSans(color: p.muted, height: 1.4),
                                  ),
                                ),
                              ),
                            ],
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                            itemCount: _profiles.length,
                            itemBuilder: (context, i) {
                              final pr = _profiles[i];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Material(
                                  color: p.surface,
                                  borderRadius: BorderRadius.circular(16),
                                  child: InkWell(
                                    onTap: () => _openEditor(existing: pr),
                                    borderRadius: BorderRadius.circular(16),
                                    child: Padding(
                                      padding: const EdgeInsets.all(18),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: p.accent.withValues(alpha: 0.12),
                                              borderRadius: BorderRadius.circular(14),
                                            ),
                                            child: Icon(
                                              Icons.storefront_rounded,
                                              color: p.accent,
                                              size: 24,
                                            ),
                                          ),
                                          const SizedBox(width: 14),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  pr.name,
                                                  style: GoogleFonts.dmSans(
                                                    fontWeight: FontWeight.w700,
                                                    fontSize: 16,
                                                    color: p.text,
                                                  ),
                                                ),
                                                const SizedBox(height: 6),
                                                Text(
                                                  pr.description.isEmpty
                                                      ? 'Sem descrição'
                                                      : pr.description,
                                                  maxLines: 3,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: GoogleFonts.dmSans(
                                                    fontSize: 13,
                                                    height: 1.35,
                                                    color: p.muted,
                                                  ),
                                                ),
                                                if (pr.keywords.isNotEmpty) ...[
                                                  const SizedBox(height: 8),
                                                  Wrap(
                                                    spacing: 6,
                                                    runSpacing: 6,
                                                    children: pr.keywords
                                                        .take(6)
                                                        .map(
                                                          (k) => Chip(
                                                            label: Text(
                                                              k,
                                                              style: GoogleFonts.dmSans(fontSize: 11),
                                                            ),
                                                            visualDensity: VisualDensity.compact,
                                                            padding: EdgeInsets.zero,
                                                            materialTapTargetSize:
                                                                MaterialTapTargetSize.shrinkWrap,
                                                          ),
                                                        )
                                                        .toList(),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                          IconButton(
                                            icon: Icon(Icons.delete_outline_rounded, color: p.muted),
                                            onPressed: () => _confirmDelete(pr),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
      ),
    );
  }
}

class _BrandProfileEditorSheet extends StatefulWidget {
  const _BrandProfileEditorSheet({
    required this.palette,
    required this.service,
    this.existing,
    required this.onSaved,
  });

  final AppPalette palette;
  final GenerationService service;
  final BrandProfile? existing;
  final Future<void> Function() onSaved;

  @override
  State<_BrandProfileEditorSheet> createState() => _BrandProfileEditorSheetState();
}

class _BrandProfileEditorSheetState extends State<_BrandProfileEditorSheet> {
  late final TextEditingController _cName;
  late final TextEditingController _cDesc;
  late final TextEditingController _cAudience;
  late final TextEditingController _cTone;
  late final TextEditingController _cKeywords;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _cName = TextEditingController(text: e?.name ?? '');
    _cDesc = TextEditingController(text: e?.description ?? '');
    _cAudience = TextEditingController(text: e?.targetAudience ?? '');
    _cTone = TextEditingController(text: e?.tone ?? '');
    _cKeywords = TextEditingController(text: e?.keywords.join(', ') ?? '');
  }

  @override
  void dispose() {
    _cName.dispose();
    _cDesc.dispose();
    _cAudience.dispose();
    _cTone.dispose();
    _cKeywords.dispose();
    super.dispose();
  }

  List<String> _parseKeywords(String raw) {
    return raw
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  Future<void> _save() async {
    final name = _cName.text.trim();
    if (name.isEmpty) return;
    setState(() => _saving = true);
    try {
      final kw = _parseKeywords(_cKeywords.text);
      final e = widget.existing;
      if (e != null) {
        await widget.service.updateBrandProfile(
          BrandProfile(
            id: e.id,
            name: name,
            description: _cDesc.text.trim(),
            targetAudience: _cAudience.text.trim(),
            tone: _cTone.text.trim(),
            keywords: kw,
            createdAt: e.createdAt,
          ),
        );
      } else {
        await widget.service.insertBrandProfile(
          BrandProfile(
            id: '',
            name: name,
            description: _cDesc.text.trim(),
            targetAudience: _cAudience.text.trim(),
            tone: _cTone.text.trim(),
            keywords: kw,
            createdAt: DateTime.now(),
          ),
        );
      }
      await widget.onSaved();
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (err) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(err.toString(), style: GoogleFonts.dmSans())),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.palette;
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: MaxWidthBox(
        maxWidth: 560,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: p.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                widget.existing != null ? 'Editar perfil' : 'Novo perfil',
                style: GoogleFonts.dmSans(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: p.text,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _cName,
                style: GoogleFonts.dmSans(color: p.text),
                decoration: _dec(p, 'Nome da empresa / produto'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _cDesc,
                maxLines: 3,
                style: GoogleFonts.dmSans(color: p.text),
                decoration: _dec(p, 'Sobre o produto ou serviço'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _cAudience,
                style: GoogleFonts.dmSans(color: p.text),
                decoration: _dec(p, 'Público-alvo'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _cTone,
                style: GoogleFonts.dmSans(color: p.text),
                decoration: _dec(p, 'Tom de comunicação'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _cKeywords,
                style: GoogleFonts.dmSans(color: p.text),
                decoration: _dec(
                  p,
                  'Palavras-chave',
                  hint: 'Separe por vírgula',
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        'Salvar',
                        style: GoogleFonts.dmSans(fontWeight: FontWeight.w700),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _dec(AppPalette p, String label, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: GoogleFonts.dmSans(color: p.muted, fontSize: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: p.border),
      ),
    );
  }
}
