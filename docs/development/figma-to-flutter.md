# Figma to Flutter Workflow

## Recommended Strategy

Use Figma as the design source of truth and Flutter as implementation target.
Treat generated code as reference, not final production code.

## Practical Steps

1. In Figma Dev Mode, choose a Flutter-compatible export path when available.
2. Extract design tokens (colors, typography, spacing) first.
3. Build reusable Flutter widgets (buttons, inputs, cards) before screens.
4. Implement screen layout in Flutter and map tokens to `ThemeData`.
5. Validate behavior/responsiveness with widget and golden tests where possible.

## Using MCP/Figma with this project

When you provide a Figma URL and node ID, we can fetch design context and translate it to Flutter-friendly components aligned with this repository conventions.
