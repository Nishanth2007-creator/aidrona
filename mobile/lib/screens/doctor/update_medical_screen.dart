import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/gradient_button.dart';

class UpdateMedicalScreen extends StatefulWidget {
  final String patientId;
  const UpdateMedicalScreen({super.key, required this.patientId});

  @override
  State<UpdateMedicalScreen> createState() => _UpdateMedicalScreenState();
}

class _UpdateMedicalScreenState extends State<UpdateMedicalScreen> {
  final _diagnosisCtrl = TextEditingController();
  final _hospitalCtrl = TextEditingController();
  final _hemoglobinCtrl = TextEditingController();
  final _bpCtrl = TextEditingController();
  final _medCtrl = TextEditingController();
  final _condCtrl = TextEditingController();

  final List<String> _medications = [];
  final List<String> _conditions = [];
  bool _loading = false;
  String _doctorRegId = 'DR-TEMP';
  Map<String, dynamic>? _previewScore;

  @override
  void initState() {
    super.initState();
    _loadDoctorId();
  }

  Future<void> _loadDoctorId() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('doctor_reg_id');
    if (saved != null && mounted) setState(() => _doctorRegId = saved);
  }

  @override
  void dispose() {
    _diagnosisCtrl.dispose();
    _hospitalCtrl.dispose();
    _hemoglobinCtrl.dispose();
    _bpCtrl.dispose();
    _medCtrl.dispose();
    _condCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _loading = true);
    try {
      final result = await context.read<ApiService>().doctorUpdateMedical({
        'patient_id': widget.patientId,
        'doctor_reg_id': _doctorRegId,
        'hospital': _hospitalCtrl.text.trim(),
        'diagnosis': _diagnosisCtrl.text.trim(),
        'hemoglobin': double.tryParse(_hemoglobinCtrl.text) ?? 13.0,
        'blood_pressure': _bpCtrl.text.trim(),
        'new_medications': _medications,
        'new_conditions': _conditions,
      });
      setState(() { _previewScore = result; _loading = false; });
      if (mounted && _previewScore != null) _showSuccessDialog();
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.danger));
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.surfaceCard,
        title: const Text('Record Updated', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700, color: AppTheme.onSurface)),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('New Fitness Score: ${_previewScore?['fitness_score'] ?? '—'}', style: const TextStyle(fontFamily: 'Inter', color: AppTheme.onSurface, fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text('Eligible: ${_previewScore?['is_eligible'] == true ? 'Yes ✓' : 'No ✗'}', style: TextStyle(fontFamily: 'Inter', color: _previewScore?['is_eligible'] == true ? AppTheme.eligible : AppTheme.danger)),
        ]),
        actions: [ElevatedButton(onPressed: () { Navigator.pop(context); context.pop(); }, child: const Text('Done'))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Update Medical Record'), leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded), onPressed: () => context.pop())),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _field(_hospitalCtrl, 'Hospital Name', Icons.business_outlined),
            const SizedBox(height: 14),
            _field(_diagnosisCtrl, 'Diagnosis', Icons.notes_rounded, maxLines: 3),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(child: _field(_hemoglobinCtrl, 'Hemoglobin (g/dL)', Icons.monitor_heart_outlined, type: TextInputType.number)),
              const SizedBox(width: 12),
              Expanded(child: _field(_bpCtrl, 'Blood Pressure', Icons.favorite_border_rounded)),
            ]),
            const SizedBox(height: 20),
            _chipSection('Medications', _medications, _medCtrl, AppTheme.danger),
            const SizedBox(height: 16),
            _chipSection('Conditions', _conditions, _condCtrl, AppTheme.amber),
            const SizedBox(height: 28),
            GradientButton(onPressed: _loading ? null : _submit, loading: _loading, label: 'Submit Record', color: AppTheme.teal),
          ],
        ),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label, IconData icon, {int maxLines = 1, TextInputType? type}) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      keyboardType: type,
      style: const TextStyle(fontFamily: 'Inter', color: AppTheme.onSurface),
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon, color: AppTheme.onSurfaceMuted, size: 20)),
    );
  }

  Widget _chipSection(String label, List<String> items, TextEditingController ctrl, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, color: AppTheme.onSurface, fontSize: 14)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            ...items.map((m) => Chip(
              label: Text(m, style: const TextStyle(fontFamily: 'Inter', fontSize: 12)),
              deleteIcon: const Icon(Icons.close, size: 14),
              onDeleted: () => setState(() => items.remove(m)),
              backgroundColor: color.withValues(alpha: 0.1),
              side: BorderSide(color: color.withValues(alpha: 0.3)),
            )),
            ActionChip(
              label: const Text('+ Add', style: TextStyle(fontFamily: 'Inter', fontSize: 12)),
              onPressed: () => _showAddDialog(label, ctrl, items),
              backgroundColor: AppTheme.surfaceElevated,
            ),
          ],
        ),
      ],
    );
  }

  void _showAddDialog(String label, TextEditingController ctrl, List<String> items) {
    ctrl.clear();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.surfaceCard,
        title: Text('Add $label', style: const TextStyle(fontFamily: 'Inter', color: AppTheme.onSurface)),
        content: TextField(controller: ctrl, autofocus: true, style: const TextStyle(fontFamily: 'Inter', color: AppTheme.onSurface), decoration: InputDecoration(hintText: label)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: AppTheme.onSurfaceMuted))),
          ElevatedButton(onPressed: () { setState(() => items.add(ctrl.text.trim())); Navigator.pop(context); }, child: const Text('Add')),
        ],
      ),
    );
  }
}
