# Using FlAI with AI Coding Assistants

FlAI provides first-class support for AI-assisted development through a Claude Code skill, an MCP server, and project configuration files for popular AI coding tools.

## Quick Reference

| Tool | Setup Method | Best For |
|---|---|---|
| Claude Code | Skill + CLAUDE.md | Full development workflow, component creation, architecture decisions |
| Cursor | .cursorrules | Inline editing, autocomplete, chat within editor |
| GitHub Copilot | CLAUDE.md context | Code completion, inline suggestions |
| Windsurf | .cursorrules + CLAUDE.md | Cascade flows, multi-file editing |

---

## Claude Code

Claude Code has the deepest integration with FlAI through a dedicated skill and project CLAUDE.md.

### Skill Installation

The FlAI skill lives at `packages/flai_skill/skill.md`. It teaches Claude Code about FlAI's components, installation process, theming system, and provider setup.

To use it, ensure the skill is available in your Claude Code configuration. The skill activates when you ask about:

- Adding AI chat UI to a Flutter app
- FlAI component selection and installation
- Theming and customization
- OpenAI or Anthropic provider setup

### Project Configuration

The `CLAUDE.md` file at the repo root provides Claude Code with full project context:

- Repository structure and architecture
- Development commands (melos bootstrap, analyze, test)
- Key conventions (theme access, widget patterns, naming)
- Code style requirements

### MCP Server

FlAI includes an MCP (Model Context Protocol) server at `packages/flai_mcp/` that provides AI assistants with:

- Component catalog and metadata
- Brick template information
- Theme token reference
- Provider configuration details

#### MCP Server Configuration

Add the FlAI MCP server to your Claude Code config (`~/.claude/claude_desktop_config.json` or project-level `.claude/settings.json`):

```json
{
  "mcpServers": {
    "flai": {
      "command": "dart",
      "args": ["run", "bin/server.dart"],
      "cwd": "/path/to/flutter-ai-chat-components/packages/flai_mcp"
    }
  }
}
```

### Recommended Prompts for Claude Code

**Starting a new chat feature:**
```
I want to add an AI chat screen to my Flutter app. I'm using FlAI.
Set up a complete chat page with the Anthropic provider, dark theme,
and a custom system prompt.
```

**Adding a specific component:**
```
Add the FlAI streaming_text component to my project and show me
how to use it standalone with a stream from my existing API client.
```

**Custom theme creation:**
```
Create a FlAI theme that matches my app's brand colors:
primary=#6366F1 (indigo), background=#0A0A0F, with Inter font.
```

**Provider configuration:**
```
Set up the FlAI Anthropic provider with extended thinking enabled
and tool use for a weather lookup function.
```

**Architecture guidance:**
```
I need to build a multi-conversation chat app with FlAI.
How should I structure the state management for conversation
switching while keeping the FlAI controller pattern?
```

---

## Cursor

Cursor reads the `.cursorrules` file at the repo root for project-specific context.

### What Cursor Gets

The `.cursorrules` file provides:

- Project architecture overview
- Widget naming conventions (Flai prefix for widgets, no prefix for data classes)
- Theme access patterns with FlaiTheme.of(context)
- Streaming event pattern matching with ChatEvent sealed class
- AiProvider interface contract
- Color token reference (shadcn/ui naming)
- Code style rules (Dart 3.4+, const constructors, doc comments)
- File structure for new brick components

### Cursor-Specific Tips

**Composer mode** works well for:
- Creating new FlAI components (Cursor understands the brick template structure)
- Refactoring theme tokens across multiple widgets
- Adding new ChatEvent subtypes and handling them across providers

**Chat mode** works well for:
- Asking about FlAI architecture decisions
- Understanding the sealed ChatEvent pattern
- Getting theme token recommendations

### Recommended Cursor Prompts

```
Create a new FlAI brick component called "reaction_picker" that lets
users add emoji reactions to messages. Follow the existing brick
structure and use FlaiTheme.of(context) for all styling.
```

```
Add a new color token "codeBackground" to FlaiColors with appropriate
values in all four presets (light, dark, ios, premium).
```

---

## GitHub Copilot

GitHub Copilot benefits from the project's well-structured code and doc comments.

### Setup

No special configuration is needed. Copilot reads from:

1. Open files in your editor for context
2. `CLAUDE.md` if you have it open or referenced
3. Doc comments on FlAI classes

### Tips for Better Copilot Suggestions

1. **Keep relevant files open.** When working on a new component, open `flai_theme.dart`, `message.dart`, and an existing component like `message_bubble.dart` for Copilot to reference.

2. **Write doc comments first.** Start with `///` documentation, and Copilot will generate implementations that match FlAI patterns:

```dart
/// A widget that displays a list of suggested prompts the user can tap.
///
/// Styled as rounded chips using [FlaiTheme] tokens. Arranged in a
/// horizontally scrolling row below the chat input.
class FlaiSuggestionChips extends StatelessWidget {
  // Copilot will fill in the rest following FlAI patterns
```

3. **Use the sealed class pattern.** When handling ChatEvent, type `switch (event) {` and Copilot will suggest all cases.

### Recommended Workflow

1. Open the files: `flai_theme.dart`, `chat_event.dart`, `ai_provider.dart`
2. Create your new file with a doc comment describing the widget
3. Let Copilot generate the implementation
4. Verify it uses `FlaiTheme.of(context)` and follows the naming conventions

---

## Windsurf

Windsurf reads both `.cursorrules` and can reference `CLAUDE.md` for project context.

### Setup

The `.cursorrules` file is automatically loaded. For deeper context in Cascade flows, reference the CLAUDE.md:

```
@CLAUDE.md Help me create a new FlAI component for displaying
markdown content with syntax highlighting.
```

### Cascade Flow Tips

Windsurf's Cascade works well for multi-step FlAI tasks:

1. **Component creation flow:** "Create a new brick component, register it in the CLI, add it to the example app, and write tests."

2. **Theme iteration flow:** "Create a new theme preset, apply it in the example app, and take a screenshot to review."

3. **Provider integration flow:** "Add a new provider for Gemini following the AiProvider interface, with streaming support."

### Recommended Windsurf Prompts

```
Create a complete FlAI component for displaying code blocks with
syntax highlighting and a copy button. Include the brick.yaml,
template files, and add it to the example app showcase.
```

```
Refactor the ChatScreenController to support multiple simultaneous
conversations with independent message histories, following FlAI's
existing ChangeNotifier pattern.
```

---

## Writing Custom MCP Tools

If you want to extend the MCP server with custom tools for your workflow:

The MCP server at `packages/flai_mcp/` can be extended to provide:

- **Component scaffolding:** Generate brick templates from a description
- **Theme generation:** Create FlaiColors from a color palette
- **Provider testing:** Validate API keys and test connectivity
- **Documentation lookup:** Search FlAI docs for specific topics

---

## Environment Variables

All AI tools benefit from having API keys available for testing. Use `--dart-define` flags rather than hardcoded values:

```bash
# Development
flutter run \
  --dart-define=OPENAI_API_KEY=sk-... \
  --dart-define=ANTHROPIC_API_KEY=sk-ant-...

# Or use a .env file with your tool's env loading mechanism
OPENAI_API_KEY=sk-...
ANTHROPIC_API_KEY=sk-ant-...
```

Never commit API keys to the repository. The `.gitignore` should include `.env` files.
