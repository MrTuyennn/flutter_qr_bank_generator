import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'bank_qr.dart';

const String _viewType = 'flutter_qr_bank_generator/qrcode';

class QrGeneratorView extends StatelessWidget {
  final String? content;
  final BankQrData? bankData;
  final String? image;

  const QrGeneratorView({super.key, required String this.content, this.image})
    : bankData = null;

  /// Builds a NAPAS bank-transfer QR from a [BankQrData] model.
  const QrGeneratorView.bank({
    super.key,
    required BankQrData this.bankData,
    this.image,
  }) : content = null;

  String _resolveContent() {
    final bankData = this.bankData;
    if (bankData != null) return bankData.toPayload();
    return content!;
  }

  @override
  Widget build(BuildContext context) {
    final creationParams = <String, dynamic>{
      'content': _resolveContent(),
      'image': image ?? '',
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
