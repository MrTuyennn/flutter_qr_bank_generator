import 'package:flutter/material.dart';
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

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('flutter_qr_bank_generator example')),
        body: const _QrDemoBody(),
      ),
    );
  }
}

class _QrDemoBody extends StatelessWidget {
  const _QrDemoBody();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 250,
            height: 250,
            child: QrGeneratorView.from(data: _qrData),
          ),
          const SizedBox(height: 24),
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
        ],
      ),
    );
  }

  Future<void> _handleDownload(BuildContext context) async {
    // No `data:` needed — reuses the QrData from the QrGeneratorView above.
    final saved = await downloadQrCode();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(saved ? 'Saved to gallery' : 'Save failed')),
    );
  }

  Future<void> _handleShare(BuildContext context) async {
    await shareQrCode(text: 'My NAPAS bank-transfer QR');
  }
}
