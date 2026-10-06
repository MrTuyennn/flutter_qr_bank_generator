import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'bank_qr.dart';
import 'qr_data.dart';

const String _viewType = 'flutter_qr_bank_generator/qrcode';

class QrGeneratorView extends StatelessWidget {
  final QrData data;

  /// The [QrData] most recently rendered by a [QrGeneratorView].
  static QrData? lastData;

  // ignore: prefer_const_constructors_in_immutables
  QrGeneratorView({super.key, required String content, String? image})
    : data = QrData(content: content, image: image);

  // ignore: prefer_const_constructors_in_immutables
  QrGeneratorView.bank({super.key, required BankQrData bankData, String? image})
    : data = QrData(bankData: bankData, image: image);

  const QrGeneratorView.from({super.key, required this.data});

  String _resolveContent() {
    final bankData = data.bankData;
    if (bankData != null) return bankData.toPayload();
    final content = data.content;
    if (content == null) {
      throw ArgumentError('QrData must have either content or bankData');
    }
    return content;
  }

  @override
  Widget build(BuildContext context) {
    lastData = data;

    final creationParams = <String, dynamic>{
      'content': _resolveContent(),
      'image': data.image ?? '',
    };

    if (Platform.isIOS) {
      return UiKitView(
        viewType: _viewType,
        layoutDirection: TextDirection.ltr,
        creationParams: creationParams,
        creationParamsCodec: const StandardMessageCodec(),
      );
    }

    return AndroidView(
      viewType: _viewType,
      layoutDirection: TextDirection.ltr,
      creationParams: creationParams,
      creationParamsCodec: const StandardMessageCodec(),
    );
  }
}
