import 'package:flutter/material.dart';

import '../../../design/tokens/app_colors.dart';

Future<void> showNfcSaveFlow(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isDismissible: false,
    enableDrag: false,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => const _NfcSaveFlowSheet(),
  );
}

enum _NfcSaveState { putOnWristband, registering, success }

class _NfcSaveFlowSheet extends StatefulWidget {
  const _NfcSaveFlowSheet();

  @override
  State<_NfcSaveFlowSheet> createState() => _NfcSaveFlowSheetState();
}

class _NfcSaveFlowSheetState extends State<_NfcSaveFlowSheet> {
  _NfcSaveState _state = _NfcSaveState.putOnWristband;

  void _startRegistering() {
    setState(() => _state = _NfcSaveState.registering);
    Future<void>.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => _state = _NfcSaveState.success);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60,
            height: 5,
            decoration: BoxDecoration(
              color: AppColors.disabled,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(height: 24),
          _buildContent(),
        ],
      ),
    );
  }

  Widget _buildContent() {
    switch (_state) {
      case _NfcSaveState.putOnWristband:
        return _PutOnWristband(onContinue: _startRegistering);
      case _NfcSaveState.registering:
        return const _Registering();
      case _NfcSaveState.success:
        return _SuccessRegistration(
          onGoHome: () {
            Navigator.of(context).pop();
            Navigator.of(context).popUntil((Route<dynamic> route) => route.isFirst);
          },
        );
    }
  }
}

class _PutOnWristband extends StatelessWidget {
  const _PutOnWristband({required this.onContinue});

  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Put on the wristband',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 24),
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.primary, width: 3),
          ),
          child: const Icon(Icons.nfc, size: 50, color: AppColors.primary),
        ),
        const SizedBox(height: 20),
        const Text(
          'Please place the wristband to load the\ninformation.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 40,
          child: ElevatedButton(
            onPressed: onContinue,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Start writing',
              style: TextStyle(color: AppColors.white, fontSize: 14),
            ),
          ),
        ),
      ],
    );
  }
}

class _Registering extends StatelessWidget {
  const _Registering();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Registrering in the NFC ...',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 30),
        SizedBox(
          width: 60,
          height: 60,
          child: CircularProgressIndicator(
            strokeWidth: 4,
            color: AppColors.primary,
            backgroundColor: AppColors.primary.withAlpha(40),
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Please wait a moment while the\ninformation loads.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _SuccessRegistration extends StatelessWidget {
  const _SuccessRegistration({required this.onGoHome});

  final VoidCallback onGoHome;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.check_circle, size: 80, color: AppColors.success),
        const SizedBox(height: 16),
        const Text(
          'Succesful Registration',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Patient information successfully saved',
          style: TextStyle(fontSize: 14, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 40,
          child: ElevatedButton(
            onPressed: onGoHome,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00A396),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Go to home',
              style: TextStyle(color: AppColors.white, fontSize: 14),
            ),
          ),
        ),
      ],
    );
  }
}
