# @flai/mcp-server

MCP (Model Context Protocol) server for **FlAI** — AI chat components for Flutter.

This server enables AI assistants (Claude, Cursor, Windsurf, etc.) to discover, install, and manage FlAI components directly inside your Flutter project.

## What it does

| Tool | Description |
|---|---|
| `list_components` | Lists all 15 FlAI components grouped by category |
| `add_component` | Installs a component (validates, resolves deps, runs `flai add`) |
| `get_component_info` | Detailed API docs: props, usage example, dependencies |
| `init_project` | Initializes FlAI core (theme, models, provider interface) |
| `doctor` | Health check for the FlAI project setup |
| `get_theme_info` | Theme presets (Light, Dark, iOS, Premium) and customization guide |

## Prerequisites

- [FlAI CLI](../flai_cli/) installed and on your PATH
- A Flutter project with `pubspec.yaml`

## Configuration

### Claude Desktop

Add to `~/Library/Application Support/Claude/claude_desktop_config.json` (macOS) or `%APPDATA%\Claude\claude_desktop_config.json` (Windows):

```json
{
  "mcpServers": {
    "flai": {
      "command": "npx",
      "args": ["@flai/mcp-server"]
    }
  }
}
```

### Claude Code

Add to your project's `.mcp.json`:

```json
{
  "mcpServers": {
    "flai": {
      "command": "npx",
      "args": ["@flai/mcp-server"]
    }
  }
}
```

### Cursor

Add to `.cursor/mcp.json` in your project root:

```json
{
  "mcpServers": {
    "flai": {
      "command": "npx",
      "args": ["@flai/mcp-server"]
    }
  }
}
```

### Windsurf

Add to `~/.codeium/windsurf/mcp_config.json`:

```json
{
  "mcpServers": {
    "flai": {
      "command": "npx",
      "args": ["@flai/mcp-server"]
    }
  }
}
```

### Local development

If running from source instead of npx:

```json
{
  "mcpServers": {
    "flai": {
      "command": "node",
      "args": ["/absolute/path/to/packages/flai_mcp/dist/index.js"]
    }
  }
}
```

## Build from source

```bash
cd packages/flai_mcp
npm install
npm run build
npm start
```

## Example conversation

> **You:** Add a chat screen to my Flutter project at ~/myapp

The AI assistant will:
1. Call `init_project` to set up FlAI core (if not already done)
2. Call `add_component` with `chat_screen` — which auto-installs `message_bubble`, `input_bar`, and `streaming_text` as dependencies
3. Show you the generated code and how to wire it up

> **You:** What theme options are available?

The assistant calls `get_theme_info` and explains the 4 presets with customization examples.

> **You:** Show me how to use the streaming text widget

The assistant calls `get_component_info` for `streaming_text` and returns the full API with props and usage examples.

## Components

### Chat Essentials
- `chat_screen` — Full-page AI chat screen
- `message_bubble` — Chat message bubble with markdown support
- `input_bar` — Chat input bar with send button
- `streaming_text` — Real-time streaming text renderer
- `typing_indicator` — Animated typing dots

### AI Widgets
- `tool_call_card` — AI tool/function call display
- `code_block` — Syntax-highlighted code with copy button
- `thinking_indicator` — Expandable AI reasoning panel
- `citation_card` — Inline citation card
- `image_preview` — Image thumbnail with full-screen expansion

### Conversation
- `conversation_list` — Past conversations with search
- `model_selector` — AI model picker
- `token_usage` — Token count and cost display

### Providers
- `openai_provider` — OpenAI API provider
- `anthropic_provider` — Anthropic API provider

## License

MIT
