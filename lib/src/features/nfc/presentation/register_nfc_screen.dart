import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../../core/di/app_scope.dart';
import '../../../core/nfc/nfc_service.dart';
import '../../../design/tokens/app_colors.dart';
import '../../../shared/widgets/screen_bottom_handle.dart';
import '../domain/patient_record.dart';
import 'add_consultation_screen.dart';
import 'add_vaccine_screen.dart';
import 'shared_read_nfc_header.dart';

class RegisterNfcScreen extends StatefulWidget {
  const RegisterNfcScreen({super.key});
  @override
  State<RegisterNfcScreen> createState() => _RegisterNfcScreenState();
}

class _RegisterNfcScreenState extends State<RegisterNfcScreen> {
  int _step = 0;

  // Step 1: NFC
  String? _deviceUid;
  bool _isScanning = false;
  String? _scanError;
  final TextEditingController _manualUidCtrl = TextEditingController();

  // Step 2: Patient
  String _docType = 'MS';
  final TextEditingController _docNumberCtrl = TextEditingController();
  final TextEditingController _firstNameCtrl = TextEditingController();
  final TextEditingController _secondNameCtrl = TextEditingController();
  final TextEditingController _firstLastNameCtrl = TextEditingController();
  final TextEditingController _secondLastNameCtrl = TextEditingController();
  String _biologicalSex = 'F';
  final TextEditingController _dobCtrl = TextEditingController();
  String _nationalityCode = 'VEN';
  String _bloodType = 'O+';
  final TextEditingController _cityCtrl = TextEditingController();
  final TextEditingController _stateCtrl = TextEditingController();

  // Guardian
  final TextEditingController _guardianNameCtrl = TextEditingController();
  String _guardianRelationship = 'Madre';
  final TextEditingController _guardianPhoneCtrl = TextEditingController();
  // Guardian wristband device_uid (replaces PIN — captured via NFC scan)
  final TextEditingController _guardianUidCtrl = TextEditingController();
  bool _isScanningGuardian = false;

  // Step 3
  bool _isSaving = false;
  bool _saved = false;
  PatientFullRecord? _savedRecord;

  static const Map<String, String> _docTypes = {
    'RC': 'Registro Civil',
    'TI': 'Tarjeta de Identidad',
    'CC': 'Cédula de Ciudadanía',
    'CE': 'Cédula de Extranjería',
    'PA': 'Pasaporte',
    'PE': 'Permiso Especial de Permanencia',
    'PT': 'Permiso por Protección Temporal',
    'SC': 'Salvoconducto',
    'MS': 'Menor sin identificación',
    'AS': 'Adulto sin identificación',
    'CN': 'Certificado de nacido vivo',
    'DE': 'Documento extranjero',
  };
  static const Map<String, String> _sexOptions = {
    'F': 'Femenino',
    'M': 'Masculino',
    'I': 'Indeterminado',
  };
  static const Map<String, String> _nationalities = {
    'VEN': 'Venezolana',
    'COL': 'Colombiana',
    'ECU': 'Ecuatoriana',
    'PER': 'Peruana',
    'HTI': 'Haitiana',
  };
  static const List<String> _bloodTypes = [
    'O+',
    'O-',
    'A+',
    'A-',
    'B+',
    'B-',
    'AB+',
    'AB-',
  ];
  static const List<String> _relationships = [
    'Madre',
    'Padre',
    'Abuela',
    'Abuelo',
    'Tía',
    'Tío',
    'Hermana',
    'Hermano',
    'Otro',
  ];

  @override
  void dispose() {
    _manualUidCtrl.dispose();
    _docNumberCtrl.dispose();
    _firstNameCtrl.dispose();
    _secondNameCtrl.dispose();
    _firstLastNameCtrl.dispose();
    _secondLastNameCtrl.dispose();
    _dobCtrl.dispose();
    _cityCtrl.dispose();
    _stateCtrl.dispose();
    _guardianNameCtrl.dispose();
    _guardianPhoneCtrl.dispose();
    _guardianUidCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEBF2F8),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                SharedReadNfcHeader(
                  title: _step == 2
                      ? 'Registro completo'
                      : _step == 1
                      ? 'Datos del paciente'
                      : 'Register NFC',
                  stepText: '${_step + 1}/3',
                  onBack: _step == 0
                      ? () => Navigator.of(context).pop()
                      : _saved
                      ? null
                      : () => setState(() => _step--),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(18, 14, 18, 60),
                    child: _buildStep(),
                  ),
                ),
              ],
            ),
            const Positioned(
              left: 116,
              right: 116,
              bottom: 14,
              child: ScreenBottomHandle(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case 0:
        return _buildStep1Scan();
      case 1:
        return _buildStep2Data();
      case 2:
        return _buildStep3Confirmation();
      default:
        return const SizedBox.shrink();
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // STEP 1 — Patient NFC scan
  // ──────────────────────────────────────────────────────────────────────────

  Widget _buildStep1Scan() {
    return Column(
      children: [
        const SizedBox(height: 20),
        const Text(
          'Acerque una manilla nueva',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.secondary,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'El sistema verificará que no esté asignada',
          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 40),
        GestureDetector(
          onTap: _isScanning ? null : _startNfcScan,
          child: Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: _deviceUid != null
                    ? AppColors.success
                    : AppColors.primary,
                width: 3,
              ),
              color: const Color(0x0A1CABE2),
            ),
            child: _isScanning
                ? const Center(child: CircularProgressIndicator(strokeWidth: 3))
                : Icon(
                    _deviceUid != null ? Icons.check : Icons.add,
                    size: 60,
                    color: _deviceUid != null
                        ? AppColors.success
                        : AppColors.primary,
                  ),
          ),
        ),
        const SizedBox(height: 16),
        if (_deviceUid != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.check_circle,
                  size: 18,
                  color: AppColors.success,
                ),
                const SizedBox(width: 8),
                Text(
                  'Manilla $_deviceUid lista — nueva',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.success,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        if (_scanError != null) ...[
          const SizedBox(height: 8),
          Text(
            _scanError!,
            style: const TextStyle(fontSize: 13, color: AppColors.error),
          ),
        ],
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _manualUidCtrl,
                style: const TextStyle(fontSize: 13),
                decoration: const InputDecoration(
                  hintText: 'UID manual (testing)',
                  hintStyle: TextStyle(fontSize: 12),
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              height: 38,
              child: ElevatedButton(
                onPressed: () {
                  if (_manualUidCtrl.text.trim().isNotEmpty) {
                    setState(() {
                      _deviceUid = _manualUidCtrl.text.trim();
                      _scanError = null;
                    });
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'OK',
                  style: TextStyle(color: AppColors.white, fontSize: 13),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          'Manillas válidas: NTAG213/215 con prefijo HWB- *',
          style: TextStyle(
            fontSize: 11,
            color: AppColors.textSecondary.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 30),
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 44,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    side: const BorderSide(color: AppColors.textSecondary),
                  ),
                  child: const Text('Cancelar', style: TextStyle(fontSize: 14)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SizedBox(
                height: 44,
                child: ElevatedButton.icon(
                  onPressed: _deviceUid != null
                      ? () => setState(() => _step = 1)
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    disabledBackgroundColor: AppColors.disabled,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(
                    Icons.arrow_forward,
                    size: 18,
                    color: AppColors.white,
                  ),
                  label: const Text(
                    'Continuar',
                    style: TextStyle(color: AppColors.white, fontSize: 14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _startNfcScan() async {
    setState(() {
      _isScanning = true;
      _scanError = null;
    });
    try {
      final uid = await NfcService.readDeviceUid();
      if (mounted)
        setState(() {
          _deviceUid = uid;
          _manualUidCtrl.text = uid;
        });
    } on NfcNotAvailableException {
      if (mounted)
        setState(() => _scanError = 'NFC no disponible. Use entrada manual.');
    } on NfcSessionException catch (e) {
      if (mounted) setState(() => _scanError = e.message);
    } finally {
      if (mounted) setState(() => _isScanning = false);
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // STEP 2 — Patient + Guardian data
  // ──────────────────────────────────────────────────────────────────────────

  Widget _buildStep2Data() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFE8F5E9),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.check_circle,
                size: 16,
                color: AppColors.success,
              ),
              const SizedBox(width: 6),
              Text(
                'Manilla $_deviceUid lista — nueva',
                style: const TextStyle(fontSize: 12, color: AppColors.success),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        _sectionTitle('Identificación'),
        const SizedBox(height: 10),
        _dropdownField('Tipo de documento *', _docType, _docTypes, (v) {
          if (v != null) {
            setState(() => _docType = v);
          }
        }),
        const SizedBox(height: 10),
        _textField('Número de documento', _docNumberCtrl, icon: Icons.badge),
        const SizedBox(height: 16),
        _textField('Nombres *', _firstNameCtrl, icon: Icons.person),
        const SizedBox(height: 10),
        _textField(
          'Segundo nombre',
          _secondNameCtrl,
          icon: Icons.person_outline,
        ),
        const SizedBox(height: 10),
        _textField('Primer apellido *', _firstLastNameCtrl, icon: Icons.person),
        const SizedBox(height: 10),
        _textField(
          'Segundo apellido',
          _secondLastNameCtrl,
          icon: Icons.person_outline,
        ),
        const SizedBox(height: 16),
        _dropdownField('Género *', _biologicalSex, _sexOptions, (v) {
          if (v != null) {
            setState(() => _biologicalSex = v);
          }
        }),
        const SizedBox(height: 10),
        _dateField('Fecha de nacimiento *', _dobCtrl),
        const SizedBox(height: 10),
        _dropdownField('Nacionalidad *', _nationalityCode, _nationalities, (v) {
          if (v != null) {
            setState(() => _nationalityCode = v);
          }
        }),
        const SizedBox(height: 16),
        _sectionTitle('Procedencia'),
        const SizedBox(height: 10),
        _textField('Ciudad / región', _cityCtrl, icon: Icons.location_on),
        const SizedBox(height: 10),
        _textField('Departamento / estado', _stateCtrl, icon: Icons.map),
        const SizedBox(height: 16),
        _sectionTitle('Datos clínicos'),
        const SizedBox(height: 10),
        _chipSelector(
          'Tipo de sangre',
          _bloodTypes,
          _bloodType,
          (v) => setState(() => _bloodType = v),
        ),
        const SizedBox(height: 24),
        _sectionTitle('Guardián (menores de 18)'),
        const SizedBox(height: 10),
        _textField(
          'Nombre del guardián *',
          _guardianNameCtrl,
          icon: Icons.family_restroom,
        ),
        const SizedBox(height: 10),
        _chipSelector(
          'Parentesco',
          _relationships,
          _guardianRelationship,
          (v) => setState(() => _guardianRelationship = v),
        ),
        const SizedBox(height: 10),
        _textField(
          'Teléfono del guardián *',
          _guardianPhoneCtrl,
          icon: Icons.phone,
          keyboard: TextInputType.phone,
        ),
        const SizedBox(height: 10),
        // ── Guardian device_uid (NFC scan of guardian's wristband) ────────
        _guardianUidField(),
        const SizedBox(height: 30),
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 44,
                child: OutlinedButton.icon(
                  onPressed: () => setState(() => _step = 0),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    side: const BorderSide(color: AppColors.textSecondary),
                  ),
                  icon: const Icon(Icons.arrow_back_ios, size: 14),
                  label: const Text('Atrás', style: TextStyle(fontSize: 14)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SizedBox(
                height: 44,
                child: ElevatedButton.icon(
                  onPressed: _validateAndContinue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(
                    Icons.arrow_forward,
                    size: 18,
                    color: AppColors.white,
                  ),
                  label: const Text(
                    'Continuar',
                    style: TextStyle(color: AppColors.white, fontSize: 14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Guardian wristband field: text input + NFC scan button
  Widget _guardianUidField() {
    final hasUid = _guardianUidCtrl.text.trim().isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Manilla del guardián',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(width: 6),
            Tooltip(
              message:
                  'Escanee la manilla NFC del guardián o ingrese el UID manualmente',
              child: Icon(
                Icons.help_outline,
                size: 14,
                color: AppColors.disabled,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _guardianUidCtrl,
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  isDense: true,
                  hintText: 'UID de la manilla del guardián',
                  hintStyle: const TextStyle(
                    fontSize: 12,
                    color: AppColors.disabled,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  prefixIcon: Icon(
                    Icons.family_restroom,
                    size: 18,
                    color: hasUid ? AppColors.success : AppColors.secondary,
                  ),
                  suffixIcon: hasUid
                      ? Icon(
                          Icons.check_circle,
                          size: 18,
                          color: AppColors.success,
                        )
                      : null,
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(width: 8),
            // NFC scan button for guardian wristband
            SizedBox(
              height: 42,
              child: ElevatedButton(
                onPressed: _isScanningGuardian ? null : _scanGuardianWristband,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  disabledBackgroundColor: AppColors.disabled,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                child: _isScanningGuardian
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.white,
                        ),
                      )
                    : const Icon(Icons.nfc, size: 22, color: AppColors.white),
              ),
            ),
          ],
        ),
        if (hasUid) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(
                Icons.check_circle,
                size: 13,
                color: AppColors.success,
              ),
              const SizedBox(width: 4),
              Text(
                'Manilla escaneada: ${_guardianUidCtrl.text.trim()}',
                style: const TextStyle(fontSize: 11, color: AppColors.success),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Future<void> _scanGuardianWristband() async {
    setState(() => _isScanningGuardian = true);
    try {
      final uid = await NfcService.readDeviceUid();
      if (mounted) {
        setState(() => _guardianUidCtrl.text = uid);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Manilla del guardián escaneada: $uid'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } on NfcNotAvailableException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('NFC no disponible. Ingrese el UID manualmente.'),
          ),
        );
      }
    } on NfcSessionException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al escanear: ${e.message}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isScanningGuardian = false);
      }
    }
  }

  void _validateAndContinue() {
    final missing = <String>[];
    if (_firstNameCtrl.text.trim().isEmpty) missing.add('Nombres');
    if (_firstLastNameCtrl.text.trim().isEmpty) missing.add('Primer apellido');
    if (_dobCtrl.text.trim().isEmpty) missing.add('Fecha de nacimiento');
    if (_guardianNameCtrl.text.trim().isEmpty)
      missing.add('Nombre del guardián');
    if (_guardianPhoneCtrl.text.trim().isEmpty)
      missing.add('Teléfono del guardián');
    if (missing.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Campos requeridos: ${missing.join(", ")}')),
      );
      return;
    }
    setState(() => _step = 2);
  }

  // ──────────────────────────────────────────────────────────────────────────
  // STEP 3 — Confirmation
  // ──────────────────────────────────────────────────────────────────────────

  Widget _buildStep3Confirmation() {
    if (_saved) return _buildSavedState();
    final name = '${_firstNameCtrl.text} ${_firstLastNameCtrl.text}'.trim();
    return Column(
      children: [
        const SizedBox(height: 30),
        const Icon(
          Icons.check_circle_outline,
          size: 80,
          color: AppColors.primary,
        ),
        const SizedBox(height: 16),
        const Text(
          'Paciente registrado',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: AppColors.secondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$name · $_deviceUid',
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 30),
        _confirmRow(
          Icons.check_circle,
          AppColors.success,
          'Datos:',
          'Guardados localmente',
        ),
        const SizedBox(height: 10),
        _confirmRow(
          Icons.nfc,
          AppColors.primary,
          'Manilla:',
          'Escrita y sellada',
        ),
        const SizedBox(height: 10),
        _confirmRow(
          Icons.cloud_upload,
          const Color(0xFFE6A817),
          'Sync:',
          'Pendiente (1 registro)',
        ),
        const SizedBox(height: 40),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: _isSaving ? null : _saveRecord,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              disabledBackgroundColor: AppColors.disabled,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            icon: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.white,
                    ),
                  )
                : const Icon(Icons.save, size: 20, color: AppColors.white),
            label: Text(
              _isSaving ? 'Guardando...' : 'Confirmar registro',
              style: const TextStyle(color: AppColors.white, fontSize: 16),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 44,
          child: OutlinedButton.icon(
            onPressed: _isSaving ? null : () => setState(() => _step = 1),
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              side: const BorderSide(color: AppColors.textSecondary),
            ),
            icon: const Icon(Icons.arrow_back_ios, size: 14),
            label: const Text('Revisar datos', style: TextStyle(fontSize: 14)),
          ),
        ),
      ],
    );
  }

  Widget _buildSavedState() {
    final name = '${_firstNameCtrl.text} ${_firstLastNameCtrl.text}'.trim();
    return Column(
      children: [
        const SizedBox(height: 40),
        Container(
          width: 80,
          height: 80,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFF00A396),
          ),
          child: const Icon(Icons.check, size: 48, color: AppColors.white),
        ),
        const SizedBox(height: 20),
        const Text(
          'Registro completo',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: AppColors.secondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$name · $_deviceUid',
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 30),
        _confirmRow(
          Icons.check_circle,
          AppColors.success,
          'Datos:',
          'Guardados localmente',
        ),
        const SizedBox(height: 10),
        _confirmRow(
          Icons.nfc,
          AppColors.success,
          'Manilla:',
          'Escrita y sellada',
        ),
        const SizedBox(height: 10),
        _confirmRow(
          Icons.cloud_upload,
          const Color(0xFFE6A817),
          'Sync:',
          'Pendiente (1 registro)',
        ),
        const SizedBox(height: 40),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: _savedRecord != null
                ? () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          AddConsultationScreen(patient: _savedRecord!),
                    ),
                  )
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            icon: const Icon(
              Icons.medical_services,
              size: 20,
              color: AppColors.white,
            ),
            label: const Text(
              'Añadir consulta',
              style: TextStyle(color: AppColors.white, fontSize: 15),
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: _savedRecord != null
                ? () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => AddVaccineScreen(patient: _savedRecord!),
                    ),
                  )
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            icon: const Icon(Icons.vaccines, size: 20, color: AppColors.white),
            label: const Text(
              'Añadir vacuna',
              style: TextStyle(color: AppColors.white, fontSize: 15),
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          height: 44,
          child: OutlinedButton(
            onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              side: const BorderSide(color: AppColors.textSecondary),
            ),
            child: const Text(
              'Volver al inicio',
              style: TextStyle(fontSize: 14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _confirmRow(IconData icon, Color color, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 22, color: color),
        const SizedBox(width: 10),
        Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _saveRecord() async {
    setState(() => _isSaving = true);
    try {
      final record = _buildRecord();
      final scope = AppScope.of(context);
      await scope.localDatabase.savePatient(record);
      try {
        await scope.patientRepository.syncPatient(record);
        await scope.localDatabase.markSynced(record.patientId);
      } catch (_) {}
      if (mounted)
        setState(() {
          _saved = true;
          _isSaving = false;
          _savedRecord = record;
        });
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al guardar: $e')));
      }
    }
  }

  PatientFullRecord _buildRecord() {
    return PatientFullRecord(
      patientId: const Uuid().v4(),
      deviceUid: _deviceUid!,
      patientInfo: PatientInfo(
        identification: PatientIdentification(
          documentType: _docType,
          documentNumber: _docNumberCtrl.text.trim(),
        ),
        firstName: _firstNameCtrl.text.trim(),
        secondName: _secondNameCtrl.text.trim().isEmpty
            ? null
            : _secondNameCtrl.text.trim(),
        firstLastName: _firstLastNameCtrl.text.trim(),
        secondLastName: _secondLastNameCtrl.text.trim().isEmpty
            ? null
            : _secondLastNameCtrl.text.trim(),
        dob: _dobCtrl.text.trim(),
        nationalityCode: _nationalityCode,
        nationalityName: _nationalities[_nationalityCode],
        biologicalSex: _biologicalSex,
        address: Address(
          city: _cityCtrl.text.trim(),
          state: _stateCtrl.text.trim(),
          country: 'COL',
          countryName: 'Colombia',
        ),
        bloodType: _bloodType,
      ),
      guardianInfo: GuardianInfo(
        name: _guardianNameCtrl.text.trim(),
        relationship: _guardianRelationship,
        phone: _guardianPhoneCtrl.text.trim(),
        // Store guardian's wristband device_uid for 2FA scan later
        deviceUid: _guardianUidCtrl.text.trim().isEmpty
            ? null
            : _guardianUidCtrl.text.trim(),
      ),
      backgroundHistory: BackgroundHistory(
        familyHistory: <FamilyHistoryItem>[],
      ),
      allergies: <AllergyInfo>[],
      medicalHistory: <MedicalHistoryItem>[],
      vaccinationRecord: <VaccinationRecordItem>[],
    );
  }

  // ── Form helpers ─────────────────────────────────────────────────────────

  Widget _sectionTitle(String text) => Text(
    text,
    style: const TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w700,
      color: AppColors.secondary,
    ),
  );

  Widget _textField(
    String label,
    TextEditingController ctrl, {
    IconData? icon,
    TextInputType keyboard = TextInputType.text,
    bool obscure = false,
    int? maxLength,
  }) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
      ),
      const SizedBox(height: 4),
      TextField(
        controller: ctrl,
        keyboardType: keyboard,
        obscureText: obscure,
        maxLength: maxLength,
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          isDense: true,
          counterText: '',
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 12,
          ),
          prefixIcon: icon != null
              ? Icon(icon, size: 18, color: AppColors.secondary)
              : null,
        ),
      ),
    ],
  );

  Widget _dateField(String label, TextEditingController ctrl) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
      ),
      const SizedBox(height: 4),
      TextField(
        controller: ctrl,
        readOnly: true,
        style: const TextStyle(fontSize: 14),
        decoration: const InputDecoration(
          isDense: true,
          hintText: 'DD/MM/AAAA',
          hintStyle: TextStyle(fontSize: 13, color: AppColors.disabled),
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          prefixIcon: Icon(
            Icons.calendar_today,
            size: 18,
            color: AppColors.secondary,
          ),
        ),
        onTap: () async {
          final now = DateTime.now();
          final picked = await showDatePicker(
            context: context,
            initialDate: DateTime(now.year - 5),
            firstDate: DateTime(1920),
            lastDate: now,
          );
          if (picked != null) {
            ctrl.text =
                '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
          }
        },
      ),
    ],
  );

  Widget _dropdownField(
    String label,
    String value,
    Map<String, String> options,
    ValueChanged<String?> onChanged,
  ) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
      ),
      const SizedBox(height: 4),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.divider, width: 1.5),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            isExpanded: true,
            value: value,
            items: options.entries
                .map(
                  (e) => DropdownMenuItem(
                    value: e.key,
                    child: Text(e.value, style: const TextStyle(fontSize: 14)),
                  ),
                )
                .toList(),
            onChanged: onChanged,
          ),
        ),
      ),
    ],
  );

  Widget _chipSelector(
    String label,
    List<String> options,
    String selected,
    ValueChanged<String> onChanged,
  ) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
      ),
      const SizedBox(height: 6),
      Wrap(
        spacing: 8,
        runSpacing: 6,
        children: options.map((opt) {
          final isSel = opt == selected;
          return GestureDetector(
            onTap: () => onChanged(opt),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: isSel ? AppColors.primary : AppColors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSel ? AppColors.primary : AppColors.divider,
                ),
              ),
              child: Text(
                opt,
                style: TextStyle(
                  fontSize: 13,
                  color: isSel ? AppColors.white : AppColors.textPrimary,
                  fontWeight: isSel ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    ],
  );
}
