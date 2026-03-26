import 'package:flutter/material.dart';

import '../../core/models/message.dart';
import '../../core/theme/flai_theme.dart';

/// A compact inline citation card that displays a source reference.
///
/// Shows the citation title in bold with a link icon, and an optional snippet
/// below. Tapping the card invokes [onTap] with the underlying [Citation]
/// object so the host app can open a browser or navigate to the source.
class FlaiCitationCard extends StatelessWidget {
  /// The citation data to display.
  final Citation citation;

  /// Called when the card is tapped with the citation object.
  final void Function(Citation)? onTap;

  const FlaiCitationCard({
    super.key,
    required this.citation,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = FlaiTheme.of(context);

    return GestureDetector(
      onTap: onTap != null ? () => onTap!(citation) : null,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: theme.spacing.md,
          vertical: theme.spacing.sm,
        ),
        decoration: BoxDecoration(
          color: theme.colors.accent.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(theme.radius.md),
          border: Border.all(
            color: theme.colors.accent.withValues(alpha: 0.25),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(top: 2),
              child: Icon(
                Icons.link_rounded,
                size: 14,
                color: theme.colors.accent,
              ),
            ),
            SizedBox(width: theme.spacing.sm),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title
                  Text(
                    citation.title,
                    style: theme.typography.bodySmall(
                      color: theme.colors.accentForeground,
                    ).copyWith(fontWeight: FontWeight.w600),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  // URL hint
                  if (citation.url != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      citation.url!,
                      style: theme.typography.bodySmall(
                        color: theme.colors.mutedForeground,
                      ).copyWith(fontSize: 10),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],

                  // Snippet
                  if (citation.snippet != null) ...[
                    SizedBox(height: theme.spacing.xs),
                    Text(
                      citation.snippet!,
                      style: theme.typography.bodySmall(
                        color: theme.colors.mutedForeground,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
