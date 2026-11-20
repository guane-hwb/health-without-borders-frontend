// lib/src/features/nfc/presentation/register/widgets/validation_feedback.dart
//
// What the register steps do when «Continuar» finds problems: one summary
// that keeps the missing fields apart from the ones to correct, said to the
// screen reader, and the view taken to the first invalid field.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../../../../core/i18n/app_strings.dart';

/// Same delay as [FormState.validate]: on iOS an immediate announcement is cut
/// off by the one for the button just pressed.
const Duration _kIOSAnnouncementDelay = Duration(seconds: 1);

const Duration _kScrollToTop = Duration(milliseconds: 300);

/// Room kept around the focused input so its label (above) and its error
/// (below) are on screen too.
const EdgeInsets _kRevealPadding = EdgeInsets.fromLTRB(0, 48, 0, 80);

/// «Faltan: …» on one line and «Corrija: …» on the next; format errors never
/// go with the missing fields. Null when there is nothing to report.
String? validationSummary(
  AppStrings s, {
  required List<String> missing,
  required List<String> invalid,
}) {
  final lines = <String>[
    if (missing.isNotEmpty) '${s.formMissingPrefix}: ${missing.join(', ')}',
    if (invalid.isNotEmpty) '${s.formFixPrefix}: ${invalid.join('; ')}',
  ];
  return lines.isEmpty ? null : lines.join('\n');
}

/// One item of the summary: [label] under «Faltan», or under «Corrija» when
/// [invalid]. It is about [field], which «Continuar» marked with
/// [fieldError]; an item with no field stays until the next «Continuar».
class SummaryEntry<F> {
  const SummaryEntry(
    this.label, {
    this.field,
    this.fieldError,
    this.invalid = false,
  });

  final String label;
  final F? field;
  final String? fieldError;
  final bool invalid;
}

/// The summary of the [entries] still open. An entry closes once its field no
/// longer shows the error «Continuar» gave it, so the banner never asks to
/// correct what has been corrected since. Null when nothing is left.
String? openSummary<F>(
  AppStrings s,
  List<SummaryEntry<F>> entries,
  Map<F, String> fieldErrors,
) {
  bool open(SummaryEntry<F> e) =>
      e.field == null || fieldErrors[e.field] == e.fieldError;
  return validationSummary(
    s,
    missing: [
      for (final e in entries)
        if (!e.invalid && open(e)) e.label,
    ],
    invalid: [
      for (final e in entries)
        if (e.invalid && open(e)) e.label,
    ],
  );
}

/// Says [message] to the screen reader. Where the platform has no
/// announcements, the summary banner is a live region instead
/// ([validationLiveRegion]).
void announceValidation(BuildContext context, String message) {
  if (!MediaQuery.supportsAnnounceOf(context)) return;
  final view = View.of(context);
  final direction = Directionality.of(context);
  Future<void> send() => SemanticsService.sendAnnouncement(
    view,
    message,
    direction,
    assertiveness: Assertiveness.assertive,
  );
  if (defaultTargetPlatform == TargetPlatform.iOS) {
    unawaited(Future<void>.delayed(_kIOSAnnouncementDelay, send));
  } else {
    unawaited(send());
  }
}

/// Wraps the summary banner so it is read when it appears on platforms
/// without announcements.
Widget validationLiveRegion(BuildContext context, Widget child) => Semantics(
  container: true,
  liveRegion: !MediaQuery.supportsAnnounceOf(context),
  child: child,
);

/// After the next frame, takes the view to the first invalid [field] and
/// focuses it. The summary sits at the top of the step, so the view goes to
/// the top whenever the field fits on that first screen too, and also when
/// there is no text field to go to or the list has not built it (far off
/// screen); otherwise only the field is brought into view.
void revealFirstInvalid(ScrollController scroll, FocusNode? field) {
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    if (!scroll.hasClients) return;
    var box = _builtBox(field);
    if (box == null || _visibleFromTheTop(box)) {
      await scroll.animateTo(0, duration: _kScrollToTop, curve: Curves.easeOut);
      await WidgetsBinding.instance.endOfFrame;
      box = _builtBox(field);
      if (box == null) return;
    }
    box.showOnScreen(rect: _revealRect(box));
    field!.requestFocus();
  });
}

RenderBox? _builtBox(FocusNode? field) {
  final ctx = field?.context;
  if (ctx == null || !ctx.mounted) return null;
  final box = ctx.findRenderObject();
  return box is RenderBox && box.attached && box.hasSize ? box : null;
}

Rect _revealRect(RenderBox box) =>
    _kRevealPadding.inflateRect(Offset.zero & box.size);

bool _visibleFromTheTop(RenderBox box) {
  final viewport = RenderAbstractViewport.maybeOf(box);
  if (viewport == null) return false;
  return viewport.getOffsetToReveal(box, 1, rect: _revealRect(box)).offset <= 0;
}
