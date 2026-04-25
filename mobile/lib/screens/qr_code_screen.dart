import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
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
    try {
      final user = context.read<UserProvider>();
      final hasAccess = await Gal.hasAccess();
      if (!hasAccess) {
        final request = await Gal.requestAccess();
        if (!request) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Storage permission is required to save QR code'),
            backgroundColor: AppTheme.danger,
          ));
          return;
        }
      }
      await Gal.putImageBytes(bytes, name: 'aidrona_qr_${user.uid}');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('QR Code saved to gallery'),
        backgroundColor: AppTheme.teal,
      ));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Failed to save QR Code to gallery'),
        backgroundColor: AppTheme.danger,
      ));
    }
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
    try {
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/my_qr.png');
      await file.writeAsBytes(bytes);
      await Share.shareXFiles([XFile(file.path)], text: 'My AiDrona Blood Donor QR');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Failed to share QR Code'),
        backgroundColor: AppTheme.danger,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>();
    final token = base64Encode(utf8.encode('${user.uid}:${DateTime.now().millisecondsSinceEpoch ~/ 300000}'));
    final qrData = 'aidrona://user/${user.uid}?token=$token';

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
                          color: AppTheme.primary.withValues(alpha: 0.2),
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
