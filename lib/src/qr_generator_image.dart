import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'bank_qr.dart';
import 'qr_actions.dart';
import 'qr_data.dart';

class QrGeneratorImage extends StatefulWidget {
  final QrData data;
  final Widget Function(BuildContext context)? loadingBuilder;
  final Widget Function(BuildContext context, Object error)? errorBuilder;

  // ignore: prefer_const_constructors_in_immutables
  QrGeneratorImage({
    super.key,
    required String content,
    String? image,
    this.loadingBuilder,
    this.errorBuilder,
  }) : data = QrData(content: content, image: image);

  QrGeneratorImage.bank({
    super.key,
    required BankQrData bankData,
    String? image,
    this.loadingBuilder,
    this.errorBuilder,
  }) : data = QrData(bankData: bankData, image: image);

  const QrGeneratorImage.from({
    super.key,
    required this.data,
    this.loadingBuilder,
    this.errorBuilder,
  });

  @override
  State<QrGeneratorImage> createState() => _QrGeneratorImageState();
}

class _QrGeneratorImageState extends State<QrGeneratorImage> {
  late Future<Uint8List> _future;

  @override
  void initState() {
    super.initState();
    _future = generateQrImage(widget.data);
  }

  @override
  void didUpdateWidget(QrGeneratorImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data != widget.data) {
      _future = generateQrImage(widget.data);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return widget.errorBuilder?.call(context, snapshot.error!) ??
              const SizedBox.shrink();
        }
        if (!snapshot.hasData) {
          return widget.loadingBuilder?.call(context) ??
              const Center(child: CircularProgressIndicator());
        }
        return Image.memory(snapshot.data!, gaplessPlayback: true);
      },
    );
  }
}
