import 'bank_qr.dart';

class QrData {
  final String? content;
  final BankQrData? bankData;
  final String? image;

  const QrData({this.content, this.bankData, this.image})
    : assert(
        content != null || bankData != null,
        'QrData requires either content or bankData',
      );
}
