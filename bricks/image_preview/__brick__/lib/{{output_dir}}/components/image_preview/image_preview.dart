import 'package:flutter/material.dart';

import '../../core/theme/flai_theme.dart';

/// An image preview thumbnail that loads from a URL, displays a shimmer
/// placeholder while loading, shows a broken-image icon on error, and opens a
/// full-screen interactive viewer dialog on tap.
class FlaiImagePreview extends StatelessWidget {
  /// The network URL of the image to display.
  final String imageUrl;

  /// Optional alt text shown as a tooltip and used as the dialog title.
  final String? alt;

  /// Constrained width for the thumbnail. Defaults to 200.
  final double? width;

  /// Constrained height for the thumbnail. Defaults to 200.
  final double? height;

  /// Overrides the default tap behavior (opening the full-screen dialog).
  final VoidCallback? onTap;

  const FlaiImagePreview({
    super.key,
    required this.imageUrl,
    this.alt,
    this.width,
    this.height,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = FlaiTheme.of(context);
    final effectiveWidth = width ?? 200.0;
    final effectiveHeight = height ?? 200.0;

    return GestureDetector(
      onTap: onTap ?? () => _openFullScreen(context, theme),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(theme.radius.md),
        child: Container(
          width: effectiveWidth,
          height: effectiveHeight,
          decoration: BoxDecoration(
            color: theme.colors.muted,
            border: Border.all(color: theme.colors.border),
            borderRadius: BorderRadius.circular(theme.radius.md),
          ),
          child: Image.network(
            imageUrl,
            width: effectiveWidth,
            height: effectiveHeight,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return _ShimmerPlaceholder(
                width: effectiveWidth,
                height: effectiveHeight,
                theme: theme,
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return _ErrorPlaceholder(
                width: effectiveWidth,
                height: effectiveHeight,
                theme: theme,
              );
            },
          ),
        ),
      ),
    );
  }

  void _openFullScreen(BuildContext context, FlaiThemeData theme) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (dialogContext) {
        return _FullScreenDialog(
          imageUrl: imageUrl,
          alt: alt,
          theme: theme,
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Shimmer placeholder (animated pulse)
// ---------------------------------------------------------------------------

class _ShimmerPlaceholder extends StatefulWidget {
  final double width;
  final double height;
  final FlaiThemeData theme;

  const _ShimmerPlaceholder({
    required this.width,
    required this.height,
    required this.theme,
  });

  @override
  State<_ShimmerPlaceholder> createState() => _ShimmerPlaceholderState();
}

class _ShimmerPlaceholderState extends State<_ShimmerPlaceholder>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          color: widget.theme.colors.muted.withValues(alpha: _animation.value),
          child: Center(
            child: Icon(
              Icons.image_rounded,
              size: 32,
              color: widget.theme.colors.mutedForeground
                  .withValues(alpha: _animation.value),
            ),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Error placeholder
// ---------------------------------------------------------------------------

class _ErrorPlaceholder extends StatelessWidget {
  final double width;
  final double height;
  final FlaiThemeData theme;

  const _ErrorPlaceholder({
    required this.width,
    required this.height,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      color: theme.colors.muted,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.broken_image_rounded,
            size: 28,
            color: theme.colors.mutedForeground.withValues(alpha: 0.6),
          ),
          SizedBox(height: theme.spacing.xs),
          Text(
            'Failed to load',
            style: theme.typography.bodySmall(
              color: theme.colors.mutedForeground,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Full-screen dialog with InteractiveViewer
// ---------------------------------------------------------------------------

class _FullScreenDialog extends StatelessWidget {
  final String imageUrl;
  final String? alt;
  final FlaiThemeData theme;

  const _FullScreenDialog({
    required this.imageUrl,
    this.alt,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            // Image viewer
            Center(
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.broken_image_rounded,
                          size: 48,
                          color: theme.colors.mutedForeground,
                        ),
                        SizedBox(height: theme.spacing.sm),
                        Text(
                          'Failed to load image',
                          style: theme.typography.bodyBase(
                            color: theme.colors.mutedForeground,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),

            // Close button
            Positioned(
              top: MediaQuery.of(context).padding.top + theme.spacing.sm,
              right: theme.spacing.md,
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  padding: EdgeInsets.all(theme.spacing.sm),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    size: 20,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

            // Alt text label
            if (alt != null)
              Positioned(
                bottom: MediaQuery.of(context).padding.bottom + theme.spacing.md,
                left: theme.spacing.lg,
                right: theme.spacing.lg,
                child: Center(
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: theme.spacing.md,
                      vertical: theme.spacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(theme.radius.md),
                    ),
                    child: Text(
                      alt!,
                      style: theme.typography.bodySmall(color: Colors.white),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
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
