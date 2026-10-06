import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_qr_bank_generator/flutter_qr_bank_generator.dart';

void main() {
  runApp(const MyApp());
}

final _qrData = QrData(
  bankData: BankQrData(
    bankBin: '970415',
    accountNumber: '113366668888',
    amount: '79000',
    content: 'Ung Ho Quy Vac Xin',
  ),
  image: 'https://img.joomcdn.net/d86c10de7a40d1da875def95ca5c7bcea861ca44_original.jpeg',
);

final _captureKey = GlobalKey();

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: RepaintBoundary(
        key: _captureKey,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('flutter_qr_bank_generator example'),
          ),
          body: const _QrDemoBody(),
        ),
      ),
    );
  }
}

class _QrDemoBody extends StatelessWidget {
  const _QrDemoBody();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Option 1: QrGeneratorView — native platform view. Renders
            // instantly, but can't be captured via RepaintBoundary.
            const Text('Option 1: QrGeneratorView (native view)'),
            const SizedBox(height: 8),
            SizedBox(
              width: 250,
              height: 250,
              child: QrGeneratorView.from(data: _qrData),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () => _handleDownload(context),
                  child: const Text('Download'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () => _handleShare(context),
                  child: const Text('Share'),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Option 2: QrGeneratorImage — plain Flutter Image.memory widget
            // (same bytes as downloadQrCode/shareQrCode). Renders
            // asynchronously, but can be captured via RepaintBoundary.
            const Text('Option 2: QrGeneratorImage (Image.memory)'),
            const SizedBox(height: 8),
            SizedBox(
              width: 250,
              height: 250,
              child: QrGeneratorImage.from(data: _qrData),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () => _handleCaptureDownload(context),
                  child: const Text('Capture & download'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () => _handleCaptureShare(context),
                  child: const Text('Capture & share'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleDownload(BuildContext context) async {
    final saved = await downloadQrCode(data: _qrData);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(saved ? 'Saved to gallery' : 'Save failed')),
    );
  }

  Future<void> _handleShare(BuildContext context) async {
    await shareQrCode(data: _qrData, text: 'My NAPAS bank-transfer QR');
  }

  Future<Uint8List> _captureScreenshot() async {
    await SchedulerBinding.instance.endOfFrame;

    final boundary =
        _captureKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 3.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  Future<void> _handleCaptureDownload(BuildContext context) async {
    final bytes = await _captureScreenshot();
    final saved = await downloadImageBytes(bytes, fileName: 'qr_screenshot');
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(saved ? 'Screenshot saved' : 'Save failed')),
    );
  }

  Future<void> _handleCaptureShare(BuildContext context) async {
    final bytes = await _captureScreenshot();
    await shareImageBytes(
      bytes,
      fileName: 'qr_screenshot',
      text: 'My NAPAS bank-transfer QR',
    );
  }
}
