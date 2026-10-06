import 'package:flutter/material.dart';
import 'package:flutter_qr_bank_generator/flutter_qr_bank_generator.dart';

Future<void> downloadQr(BuildContext context) async {
  final saved = await downloadQrCode();
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(saved ? 'Saved to gallery' : 'Save failed')),
  );
}

Future<void> shareQr() async {
  await shareQrCode(text: 'My NAPAS bank-transfer QR');
}
