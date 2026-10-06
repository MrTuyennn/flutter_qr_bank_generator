import 'package:flutter/services.dart';

import 'qr_data.dart';
import 'qr_generator_view.dart';

const MethodChannel _channel = MethodChannel(
  'flutter_qr_bank_generator/methods',
);

QrData _resolveData(QrData? data) {
  final resolved = data ?? QrGeneratorView.lastData;
  if (resolved == null) {
    throw StateError(
      'No QrData available. Render a QrGeneratorView first, or pass `data` explicitly.',
    );
  }
  return resolved;
}

Future<Uint8List> generateQrImage(QrData data) async {
  final resolvedContent = data.bankData?.toPayload() ?? data.content;
  if (resolvedContent == null) {
    throw ArgumentError('QrData must have either content or bankData');
  }

  final bytes = await _channel.invokeMethod<Uint8List>('generate', {
    'content': resolvedContent,
    'image': data.image ?? '',
  });

  if (bytes == null) {
    throw StateError('Failed to generate the QR image');
  }
  return bytes;
}

/// Returns `true` if the image was saved successfully.
Future<bool> downloadQrCode({QrData? data, String fileName = 'qrcode'}) async {
  final bytes = await generateQrImage(_resolveData(data));
  final saved = await _channel.invokeMethod<bool>('download', {
    'bytes': bytes,
    'fileName': fileName,
  });
  return saved ?? false;
}

Future<bool> shareQrCode({
  QrData? data,
  String fileName = 'qrcode',
  String? text,
}) async {
  final bytes = await generateQrImage(_resolveData(data));
  final shared = await _channel.invokeMethod<bool>('share', {
    'bytes': bytes,
    'fileName': fileName,
    'text': text,
  });
  return shared ?? false;
}

Future<bool> downloadImageBytes(
  Uint8List bytes, {
  String fileName = 'qrcode',
}) async {
  final saved = await _channel.invokeMethod<bool>('download', {
    'bytes': bytes,
    'fileName': fileName,
  });
  return saved ?? false;
}

Future<bool> shareImageBytes(
  Uint8List bytes, {
  String fileName = 'qrcode',
  String? text,
}) async {
  final shared = await _channel.invokeMethod<bool>('share', {
    'bytes': bytes,
    'fileName': fileName,
    'text': text,
  });
  return shared ?? false;
}
