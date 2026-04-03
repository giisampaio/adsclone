import 'package:flutter/material.dart';

/// Centers content horizontally and caps width; generous horizontal padding.
class MaxWidthBox extends StatelessWidget {
  const MaxWidthBox({
    super.key,
    required this.maxWidth,
    required this.child,
    this.alignment = Alignment.topCenter,
  });

  final double maxWidth;
  final Widget child;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final edge = constraints.maxWidth >= 600 ? 32.0 : 24.0;
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
