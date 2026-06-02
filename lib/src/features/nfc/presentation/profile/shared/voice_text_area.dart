// lib/src/features/nfc/presentation/register/shared/voice_text_area.dart
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../../../../design/tokens/app_colors.dart';
import '../../../../../core/i18n/app_strings.dart';

class VoiceTextArea extends StatefulWidget {
  const VoiceTextArea({
    super.key,
    required this.label,
    required this.controller,
    required this.hint,
    this.maxLines = 3,
    required this.onChanged,
  });

  final String label;
  final TextEditingController controller;
  final String hint;
  final int maxLines;
  final ValueChanged<String> onChanged;

  @override
  State<VoiceTextArea> createState() => _VoiceTextAreaState();
}

class _VoiceTextAreaState extends State<VoiceTextArea>
    with SingleTickerProviderStateMixin {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  bool _speechAvailable = false;
  String _baseText = '';

  // Inicialización perezosa controlada para mitigar fugas en Widget Tests
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    // Se inicializa de forma segura dentro del ciclo de vida sincrónico
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _pulseAnim = Tween<double>(begin: 0.4, end: 1.0).animate(_pulseCtrl);

    _initSpeech();
  }

  Future<void> _initSpeech() async {
    try {
      final available = await _speech.initialize(
        onError: (_) {
          if (mounted) {
            setState(() => _isListening = false);
            _pulseCtrl.stop();
          }
        },
        onStatus: (status) {
          if (status == stt.SpeechToText.doneStatus ||
              status == stt.SpeechToText.notListeningStatus) {
            if (mounted) {
              setState(() => _isListening = false);
              _pulseCtrl.stop();
            }
          }
        },
      );
      if (mounted) {
        setState(() => _speechAvailable = available);
      }
    } catch (_) {
      // Evita caídas silenciosas en entornos sin hardware de audio (como entornos CI/CD)
      if (mounted) {
        setState(() => _speechAvailable = false);
      }
    }
  }

  Future<void> _toggleListening() async {
    final s = AppStrings.of(context);
    final isEs = s.welcome == 'Bienvenido';

    if (_isListening) {
      await _speech.stop();
      if (mounted) {
        setState(() => _isListening = false);
        _pulseCtrl.stop();
      }
      return;
    }

    if (!_speechAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEs ? 'Micrófono no disponible' : 'Microphone not available',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    _baseText = widget.controller.text;
    if (_baseText.isNotEmpty && !_baseText.endsWith(' ')) {
      _baseText += ' ';
    }

    setState(() => _isListening = true);
    _pulseCtrl.repeat(reverse: true);

    await _speech.listen(
      localeId: isEs ? 'es_CO' : 'en_US',
      listenOptions: stt.SpeechListenOptions(
        cancelOnError: true,
        partialResults: true,
      ),
      onResult: (result) {
        if (!mounted) return;
        final recognized = result.recognizedWords;
        setState(() {
          widget.controller.text = _baseText + recognized;
          widget.controller.selection = TextSelection.fromPosition(
            TextPosition(offset: widget.controller.text.length),
          );
        });
        widget.onChanged(widget.controller.text);

        if (result.finalResult) {
          _baseText = widget.controller.text;
          if (mounted) {
            setState(() => _isListening = false);
            _pulseCtrl.stop();
          }
        }
      },
    );
  }

  @override
  void dispose() {
    _speech.cancel();
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final isEs = s.welcome == 'Bienvenido';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Stack(
          children: [
            TextField(
              controller: widget.controller,
              maxLines: widget.maxLines,
              style: const TextStyle(fontSize: 14),
              onChanged: widget.onChanged,
              decoration: InputDecoration(
                hintText: widget.hint,
                hintStyle: const TextStyle(
                  fontSize: 12,
                  color: AppColors.disabled,
                ),
                contentPadding: const EdgeInsets.only(
                  left: 12,
                  right: 12,
                  top: 12,
                  bottom: 44,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: _isListening ? AppColors.primary : AppColors.divider,
                    width: _isListening ? 2 : 1.5,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                    color: AppColors.primary,
                    width: 2,
                  ),
                ),
              ),
            ),
            Positioned(
              right: 8,
              bottom: 8,
              child: GestureDetector(
                onTap: _toggleListening,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: _isListening
                        ? AppColors.primary
                        : AppColors.primary.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _isListening ? Icons.stop_rounded : Icons.mic_none_rounded,
                    size: 18,
                    color: _isListening ? AppColors.white : AppColors.primary,
                  ),
                ),
              ),
            ),
          ],
        ),
        if (_isListening)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Row(
              children: [
                FadeTransition(
                  opacity: _pulseAnim,
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  isEs
                      ? 'Escuchando... toque el micrófono para detener'
                      : 'Listening... tap microphone to stop',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
