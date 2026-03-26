import 'package:flutter/material.dart';

import '../../core/theme/flai_theme.dart';
import '../../components/model_selector/model_selector.dart';

/// Available theme presets for the theme picker.
enum FlaiThemePreset {
  /// Zinc light theme.
  light,

  /// Zinc dark theme.
  dark,

  /// iOS Apple Messages style.
  ios,

  /// Premium Linear-inspired dark theme.
  premium,
}

/// A settings screen with theme picker, model selector, API key input,
/// and about section.
///
/// All visual styling comes from [FlaiTheme.of]. The screen is purely
/// presentational — it reports user actions through callbacks.
///
/// ```dart
/// FlaiSettingsScreen(
///   currentTheme: FlaiThemePreset.dark,
///   onThemeChanged: (preset) => updateTheme(preset),
///   models: availableModels,
///   selectedModelId: 'claude-3-sonnet',
///   onSelectModel: (model) => switchModel(model),
///   apiKey: maskedKey,
///   onApiKeyChanged: (key) => saveApiKey(key),
///   onBack: () => context.go('/chats'),
///   appVersion: '1.0.0',
/// )
/// ```
class FlaiSettingsScreen extends StatefulWidget {
  /// The currently active theme preset.
  final FlaiThemePreset currentTheme;

  /// Called when the user picks a different theme.
  final void Function(FlaiThemePreset)? onThemeChanged;

  /// Available models for the model selector.
  final List<FlaiModelOption> models;

  /// The currently selected model id.
  final String? selectedModelId;

  /// Called when the user picks a different model.
  final void Function(FlaiModelOption)? onSelectModel;

  /// The current API key (may be masked).
  final String? apiKey;

  /// Called when the user submits a new API key.
  final void Function(String)? onApiKeyChanged;

  /// Called when the user taps the back button.
  final VoidCallback? onBack;

  /// The app version string displayed in the About section.
  final String appVersion;

  const FlaiSettingsScreen({
    super.key,
    this.currentTheme = FlaiThemePreset.dark,
    this.onThemeChanged,
    this.models = const [],
    this.selectedModelId,
    this.onSelectModel,
    this.apiKey,
    this.onApiKeyChanged,
    this.onBack,
    this.appVersion = '1.0.0',
  });

  @override
  State<FlaiSettingsScreen> createState() => _FlaiSettingsScreenState();
}

class _FlaiSettingsScreenState extends State<FlaiSettingsScreen> {
  late final TextEditingController _apiKeyController;
  bool _obscureApiKey = true;

  @override
  void initState() {
    super.initState();
    _apiKeyController = TextEditingController(text: widget.apiKey ?? '');
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlaiTheme.of(context);

    return Scaffold(
      backgroundColor: theme.colors.background,
      body: Column(
        children: [
          // App bar
          _SettingsAppBar(theme: theme, onBack: widget.onBack),

          // Settings content
          Expanded(
            child: ListView(
              padding: EdgeInsets.symmetric(vertical: theme.spacing.md),
              children: [
                // Theme section
                _SectionHeader(title: 'Appearance', theme: theme),
                _ThemePicker(
                  currentTheme: widget.currentTheme,
                  onChanged: widget.onThemeChanged,
                  theme: theme,
                ),
                SizedBox(height: theme.spacing.lg),

                // Model section
                _SectionHeader(title: 'Default Model', theme: theme),
                Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: theme.spacing.md),
                  child: FlaiModelSelector(
                    models: widget.models,
                    selectedModelId: widget.selectedModelId,
                    onSelect: widget.onSelectModel,
                  ),
                ),
                SizedBox(height: theme.spacing.lg),

                // API key section
                _SectionHeader(title: 'API Key', theme: theme),
                _ApiKeyField(
                  controller: _apiKeyController,
                  obscure: _obscureApiKey,
                  theme: theme,
                  onToggleVisibility: () =>
                      setState(() => _obscureApiKey = !_obscureApiKey),
                  onSubmit: (value) {
                    widget.onApiKeyChanged?.call(value);
                  },
                ),
                SizedBox(height: theme.spacing.lg),

                // About section
                _SectionHeader(title: 'About', theme: theme),
                _AboutSection(
                  appVersion: widget.appVersion,
                  theme: theme,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// App bar
// ---------------------------------------------------------------------------

class _SettingsAppBar extends StatelessWidget {
  final FlaiThemeData theme;
  final VoidCallback? onBack;

  const _SettingsAppBar({required this.theme, this.onBack});

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
          Expanded(
            child: Text(
              'Settings',
              style: theme.typography.heading(
                color: theme.colors.foreground,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Section header
// ---------------------------------------------------------------------------

class _SectionHeader extends StatelessWidget {
  final String title;
  final FlaiThemeData theme;

  const _SectionHeader({required this.title, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: theme.spacing.md,
        vertical: theme.spacing.sm,
      ),
      child: Text(
        title,
        style: theme.typography.bodySmall(
          color: theme.colors.mutedForeground,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Theme picker
// ---------------------------------------------------------------------------

class _ThemePicker extends StatelessWidget {
  final FlaiThemePreset currentTheme;
  final void Function(FlaiThemePreset)? onChanged;
  final FlaiThemeData theme;

  const _ThemePicker({
    required this.currentTheme,
    required this.theme,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: theme.spacing.md),
      child: Row(
        children: FlaiThemePreset.values.map((preset) {
          final isSelected = preset == currentTheme;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged?.call(preset),
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: theme.spacing.xs),
                padding: EdgeInsets.symmetric(
                  vertical: theme.spacing.sm + 2,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? theme.colors.primary.withValues(alpha: 0.15)
                      : theme.colors.muted.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(theme.radius.md),
                  border: Border.all(
                    color: isSelected
                        ? theme.colors.primary
                        : theme.colors.border,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Column(
                  children: [
                    _ThemePreview(preset: preset, theme: theme),
                    SizedBox(height: theme.spacing.xs),
                    Text(
                      _presetLabel(preset),
                      style: theme.typography.bodySmall(
                        color: isSelected
                            ? theme.colors.primary
                            : theme.colors.foreground,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  String _presetLabel(FlaiThemePreset preset) => switch (preset) {
        FlaiThemePreset.light => 'Light',
        FlaiThemePreset.dark => 'Dark',
        FlaiThemePreset.ios => 'iOS',
        FlaiThemePreset.premium => 'Premium',
      };
}

class _ThemePreview extends StatelessWidget {
  final FlaiThemePreset preset;
  final FlaiThemeData theme;

  const _ThemePreview({required this.preset, required this.theme});

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (preset) {
      FlaiThemePreset.light => (const Color(0xFFFFFFFF), const Color(0xFF18181B)),
      FlaiThemePreset.dark => (const Color(0xFF09090B), const Color(0xFFFAFAFA)),
      FlaiThemePreset.ios => (const Color(0xFFF2F2F7), const Color(0xFF007AFF)),
      FlaiThemePreset.premium => (const Color(0xFF0A0A0F), const Color(0xFF818CF8)),
    };

    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        border: Border.all(
          color: theme.colors.border,
        ),
      ),
      child: Center(
        child: Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: fg,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// API key field
// ---------------------------------------------------------------------------

class _ApiKeyField extends StatelessWidget {
  final TextEditingController controller;
  final bool obscure;
  final FlaiThemeData theme;
  final VoidCallback onToggleVisibility;
  final void Function(String) onSubmit;

  const _ApiKeyField({
    required this.controller,
    required this.obscure,
    required this.theme,
    required this.onToggleVisibility,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: theme.spacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: controller,
            obscureText: obscure,
            onSubmitted: onSubmit,
            style: theme.typography.mono(color: theme.colors.foreground),
            decoration: InputDecoration(
              hintText: 'sk-...',
              hintStyle: theme.typography.mono(
                color: theme.colors.mutedForeground,
              ),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: onToggleVisibility,
                    child: Icon(
                      obscure
                          ? theme.icons.expand
                          : theme.icons.collapse,
                      size: 20,
                      color: theme.colors.mutedForeground,
                    ),
                  ),
                  SizedBox(width: theme.spacing.sm),
                  GestureDetector(
                    onTap: () => onSubmit(controller.text),
                    child: Icon(
                      theme.icons.check,
                      size: 20,
                      color: theme.colors.primary,
                    ),
                  ),
                  SizedBox(width: theme.spacing.sm),
                ],
              ),
              filled: true,
              fillColor: theme.colors.input,
              contentPadding: EdgeInsets.symmetric(
                horizontal: theme.spacing.md,
                vertical: theme.spacing.sm + 2,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(theme.radius.md),
                borderSide: BorderSide(color: theme.colors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(theme.radius.md),
                borderSide: BorderSide(color: theme.colors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(theme.radius.md),
                borderSide: BorderSide(color: theme.colors.ring, width: 2),
              ),
            ),
          ),
          SizedBox(height: theme.spacing.xs),
          Text(
            'Your API key is stored locally and never sent to our servers.',
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
// About section
// ---------------------------------------------------------------------------

class _AboutSection extends StatelessWidget {
  final String appVersion;
  final FlaiThemeData theme;

  const _AboutSection({required this.appVersion, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: theme.spacing.md),
      child: Container(
        padding: EdgeInsets.all(theme.spacing.md),
        decoration: BoxDecoration(
          color: theme.colors.card,
          borderRadius: BorderRadius.circular(theme.radius.md),
          border: Border.all(color: theme.colors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  theme.icons.chat,
                  size: 20,
                  color: theme.colors.primary,
                ),
                SizedBox(width: theme.spacing.sm),
                Text(
                  'FlAI Chat',
                  style: theme.typography.bodyBase(
                    color: theme.colors.foreground,
                  ),
                ),
              ],
            ),
            SizedBox(height: theme.spacing.sm),
            Text(
              'Version $appVersion',
              style: theme.typography.bodySmall(
                color: theme.colors.mutedForeground,
              ),
            ),
            SizedBox(height: theme.spacing.xs),
            Text(
              'Built with FlAI components for Flutter.',
              style: theme.typography.bodySmall(
                color: theme.colors.mutedForeground,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
