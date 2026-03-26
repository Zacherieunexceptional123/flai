import 'package:flutter/material.dart';

import '../../core/theme/flai_theme.dart';
import '../../components/chat_screen/chat_screen.dart';
import '../../components/chat_screen/chat_screen_controller.dart';
import '../../components/model_selector/model_selector.dart';

/// A full chat detail screen wrapping [FlaiChatScreen] with an app bar
/// containing a back button and model selector.
///
/// Expects a [ChatScreenController] to be provided. The controller should
/// already be initialised with the appropriate [AiProvider].
///
/// ```dart
/// FlaiChatDetailScreen(
///   controller: chatController,
///   title: 'New Chat',
///   models: availableModels,
///   selectedModelId: 'claude-3-sonnet',
///   onBack: () => context.go('/chats'),
///   onSelectModel: (model) => switchModel(model),
/// )
/// ```
class FlaiChatDetailScreen extends StatelessWidget {
  /// Controller managing the chat state and AI interaction.
  final ChatScreenController controller;

  /// Title displayed in the app bar.
  final String title;

  /// Available models for the model selector in the app bar.
  final List<FlaiModelOption> models;

  /// The currently selected model id.
  final String? selectedModelId;

  /// Called when the user taps the back button.
  final VoidCallback? onBack;

  /// Called when the user picks a different model.
  final void Function(FlaiModelOption)? onSelectModel;

  /// Called when a citation is tapped.
  final void Function(dynamic citation)? onTapCitation;

  /// Called when the attachment button is tapped.
  final VoidCallback? onAttachmentTap;

  const FlaiChatDetailScreen({
    super.key,
    required this.controller,
    this.title = 'Chat',
    this.models = const [],
    this.selectedModelId,
    this.onBack,
    this.onSelectModel,
    this.onTapCitation,
    this.onAttachmentTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = FlaiTheme.of(context);

    return Scaffold(
      backgroundColor: theme.colors.background,
      body: Column(
        children: [
          // Custom app bar
          _ChatAppBar(
            title: title,
            theme: theme,
            onBack: onBack,
            models: models,
            selectedModelId: selectedModelId,
            onSelectModel: onSelectModel,
          ),

          // Chat screen (without its own header since we have the app bar)
          Expanded(
            child: FlaiChatScreen(
              controller: controller,
              showHeader: false,
              onAttachmentTap: onAttachmentTap,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Chat app bar with back button and model selector
// ---------------------------------------------------------------------------

class _ChatAppBar extends StatelessWidget {
  final String title;
  final FlaiThemeData theme;
  final VoidCallback? onBack;
  final List<FlaiModelOption> models;
  final String? selectedModelId;
  final void Function(FlaiModelOption)? onSelectModel;

  const _ChatAppBar({
    required this.title,
    required this.theme,
    this.onBack,
    this.models = const [],
    this.selectedModelId,
    this.onSelectModel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + theme.spacing.sm,
        left: theme.spacing.xs,
        right: theme.spacing.md,
        bottom: theme.spacing.sm,
      ),
      decoration: BoxDecoration(
        color: theme.colors.card,
        border: Border(
          bottom: BorderSide(color: theme.colors.border),
        ),
      ),
      child: Row(
        children: [
          // Back button
          GestureDetector(
            onTap: onBack ?? () => Navigator.of(context).maybePop(),
            child: Padding(
              padding: EdgeInsets.all(theme.spacing.sm),
              child: Icon(
                theme.icons.collapse,
                size: 22,
                color: theme.colors.foreground,
              ),
            ),
          ),

          // Title
          Expanded(
            child: Text(
              title,
              style: theme.typography.bodyBase(
                color: theme.colors.foreground,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Model selector
          if (models.isNotEmpty)
            FlaiModelSelector(
              models: models,
              selectedModelId: selectedModelId,
              onSelect: onSelectModel,
            ),
        ],
      ),
    );
  }
}
