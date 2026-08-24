# Figma to Flutter

## Design Source of Truth

Figma is the source of truth for all visual designs. Flutter code is the implementation; Figma design is the specification.

## Design Tokens

Design tokens are centralized in:

- `lib/src/design/tokens/app_colors.dart` — color palette.

- `lib/src/design/theme/app_theme.dart` — ThemeData configuration.

When deploying a new component, **always use tokens** instead of hardcoded values:

```dart
// ✅ Correct
color: AppColors.primary,
style: Theme.of(context).textTheme.bodyLarge,

// ❌ Incorrect
color: Color(0xFF00897B),
fontSize: 16,
```

## Flujo de implementación recomendado

1. **Extract tokens in Figma Dev Mode** — colors, font, spacing, borders.
2. **Update `app_colors.dart` and `app_theme.dart`** if there are new values.
3. **Build atomic widgets first** — buttons (`HwbButton`), inputs (`HwbTextField`), logo (`HwbLogo`) before screens.
4. **Implement the screen** using existing widgets and theme tokens.
5. **Validate on multiple sizes** — use the `MediaQuery` widget and test on at least two screen sizes (small phone and tablet).

2.407
# Figma to Flutter

## Design Source of Truth

Figma is the source of truth for all visual designs. Flutter code is the implementation; Figma design is the specification.

## Design Tokens

Design tokens are centralized in:

- `lib/src/design/tokens/app_colors.dart` — color palette.
- `lib/src/design/theme/app_theme.dart` — ThemeData configuration.

When deploying a new component, **always use tokens** instead of hardcoded values:

```dart
// ✅ Correct
color: AppColors.primary,
style: Theme.of(context).textTheme.bodyLarge,

// ❌ Incorrect
color: Color(0xFF00897B),
fontSize: 16,
```

## Recommended Deployment Flow

1. **Extract tokens in Figma Dev Mode** — colors, font, spacing, borders.
2. **Update `app_colors.dart` and `app_theme.dart`** if there are new values.
3. **Build atomic widgets first** — buttons (`HwbButton`), inputs (`HwbTextField`), logo (`HwbLogo`) before screens.

` .... **Build atomic widgets first** — buttons (`HwbButton`), inputs (`HwbTextField`), and logos (`HwbLogo``)`````````````````````````````````````````````````````````````````````````````````` 4. **Implement the screen** using existing widgets and theme tokens.

5. **Validate on multiple sizes** — use the `MediaQuery` widget and test on at least two screen sizes (small phone and tablet).

## Existing Shared Widgets

Before creating a new widget, check `lib/src/shared/widgets/`:

| Widget | File | Usage |
|---|---|---|
| `HwbButton` | `hwb_button.dart` | Standard primary button |
| `HwbTextField` | `hwb_text_field.dart` | HWB-styled text field |
| `HwbLogo` | `hwb_logo.dart` | App logo |
| `ScreenBottomHandle` | `screen_bottom_handle.dart` | Bottom handle for bottom sheets |
| Widgets de formulario | `form_widgets.dart` | Form fields and sections |

## Sheets and modals

The project uses bottom sheets extensively for inline editing. The standard structure is:

```dart
showModalBottomSheet(
  context: context,
  isScrollControlled: true,
  builder: (_) => SheetScaffold(
    title: 'Título del sheet',
    child: MiFormulario(),
  ),
);
```

`SheetScaffold` is located in `lib/src/features/nfc/presentation/profile/shared/sheet_scaffold.dart` and provides padding, a handle, and a consistent structure.

## Using Figma MCP

If you have Figma's MCP set up in your environment, you can provide a Figma URL and node ID to extract the design context directly and translate it into Flutter components aligned with the conventions of this repository.