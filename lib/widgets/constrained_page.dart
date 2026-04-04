import 'package:flutter/material.dart';

/// Modo de padding horizontal do [MaxWidthBox].
enum MaxWidthPaddingMode {
  /// >=600 → 32px; senão 24px (comportamento anterior).
  standard,

  /// Telas grandes (>=1024) → 32px; 600–1024 → 24px; <600 → 20px.
  gallery,
}

/// Centers content horizontally and caps width; generous horizontal padding.
class MaxWidthBox extends StatelessWidget {
  const MaxWidthBox({
    super.key,
    required this.maxWidth,
    required this.child,
    this.alignment = Alignment.topCenter,
    this.paddingMode = MaxWidthPaddingMode.standard,
  });

  final double maxWidth;
  final Widget child;
  final Alignment alignment;
  final MaxWidthPaddingMode paddingMode;

  double _horizontalEdge(double viewportW) {
    switch (paddingMode) {
      case MaxWidthPaddingMode.standard:
        return viewportW >= 600 ? 32.0 : 24.0;
      case MaxWidthPaddingMode.gallery:
        if (viewportW >= 1024) return 32.0;
        if (viewportW >= 600) return 24.0;
        return 20.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final edge = _horizontalEdge(constraints.maxWidth);
        return Align(
          alignment: alignment,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: edge),
              child: child,
            ),
          ),
        );
      },
    );
  }
}
