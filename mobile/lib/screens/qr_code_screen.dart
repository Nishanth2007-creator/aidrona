import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../providers/user_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/eligibility_badge.dart';

class QrCodeScreen extends StatefulWidget {
  const QrCodeScreen({super.key});

  @override
  State<QrCodeScreen> createState() => _QrCodeScreenState();
}

class _QrCodeScreenState extends State<QrCodeScreen> {
  bool _brightMode = false;
  final GlobalKey _qrKey = GlobalKey();
  bool _saving = false;

  Future<Uint8List?> _captureQrBytes() async {
    try {
      final boundary =
          _qrKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      return null;
    }
  }

  Future<void> _saveQr() async {
    setState(() => _saving = true);
    final bytes = await _captureQrBytes();
    if (!mounted) return;
    setState(() => _saving = false);
    if (bytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Could not capture QR image'),
        backgroundColor: AppTheme.danger,
      ));
      return;
    }
    // Show preview dialog with save capability
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: AppTheme.surfaceCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('QR Code Preview',
                  style: TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w700,
                      color: AppTheme.onSurface,
                      fontSize: 18)),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16)),
                padding: const EdgeInsets.all(16),
                child: Image.memory(bytes, width: 220, height: 220),
              ),
              const SizedBox(height: 16),
              const Text(
                'Long press the image above to save it, or share it from the main screen.',
                style: TextStyle(
                    fontFamily: 'Inter',
                    color: AppTheme.onSurfaceMuted,
                    fontSize: 13),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close')),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _shareQr(UserProvider user) async {
    final bytes = await _captureQrBytes();
    if (!mounted) return;
    if (bytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Could not capture QR image'),
        backgroundColor: AppTheme.danger,
      ));
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(
          'Share: aidrona://user/${user.uid}?bt=${user.bloodType}'),
      backgroundColor: AppTheme.primary,
      action: SnackBarAction(
        label: 'Copy',
        textColor: Colors.white,
        onPressed: () {},
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>();
    final qrData = 'aidrona://user/${user.uid}?bt=${user.bloodType}';

    return Scaffold(
      appBar: AppBar(
        title: const Text('My QR Code'),
        actions: [
          IconButton(
            icon: Icon(
                _brightMode
                    ? Icons.wb_sunny_rounded
                    : Icons.wb_sunny_outlined,
                color: AppTheme.primary),
            onPressed: () => setState(() => _brightMode = !_brightMode),
          ),
        ],
      ),
      backgroundColor: _brightMode ? Colors.white : AppTheme.surface,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Scan this at the hospital',
                  style: TextStyle(
                      fontFamily: 'Inter',
                      color: AppTheme.onSurfaceMuted,
                      fontSize: 14)),
              const SizedBox(height: 24),
              RepaintBoundary(
                key: _qrKey,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                          color: AppTheme.primary.withOpacity(0.2),
                          blurRadius: 30,
                          spreadRadius: 4)
                    ],
                  ),
                  child: QrImageView(
                      data: qrData, version: QrVersions.auto, size: 240),
                ),
              ),
              const SizedBox(height: 28),
              Text(user.bloodType ?? '—',
                  style: const TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w800,
                      fontSize: 48,
                      color: AppTheme.danger)),
              const SizedBox(height: 4),
              const Text('Blood Type',
                  style: TextStyle(
                      fontFamily: 'Inter', color: AppTheme.onSurfaceMuted)),
              const SizedBox(height: 20),
              EligibilityBadge(isEligible: user.isEligible, large: true),
              const SizedBox(height: 12),
              Text('Fitness Score: ${user.fitnessScore.toStringAsFixed(0)}/100',
                  style: const TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w600,
                      color: AppTheme.onSurface,
                      fontSize: 16)),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _saving ? null : _saveQr,
                      icon: _saving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppTheme.primary))
                          : const Icon(Icons.download_rounded, size: 18),
                      label: const Text('Save QR',
                          style: TextStyle(
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w600)),
                      style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.primary,
                          side: const BorderSide(color: AppTheme.primary),
                          padding:
                              const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12))),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _shareQr(user),
                      icon: const Icon(Icons.share_rounded, size: 18),
                      label: const Text('Share',
                          style: TextStyle(
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w600)),
                      style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.primary,
                          side: const BorderSide(color: AppTheme.primary),
                          padding:
                              const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12))),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
