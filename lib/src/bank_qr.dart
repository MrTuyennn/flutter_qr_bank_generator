import 'dart:convert';

class BankQrData {
  final String bankBin;
  final String accountNumber;
  final String? amount;

  /// Transfer message / purpose, shown to the payer's banking app.
  final String? content;

  const BankQrData({
    required this.bankBin,
    required this.accountNumber,
    this.amount,
    this.content,
  });

  /// Parses the JSON shape `{"bankBin","accountNumber","amount","content"}`.
  factory BankQrData.fromJson(String source) {
    final map = jsonDecode(source) as Map<String, dynamic>;
    return BankQrData(
      bankBin: map['bankBin'] as String,
      accountNumber: map['accountNumber'] as String,
      amount: (map['amount'] as Object?)?.toString(),
      content: map['content'] as String?,
    );
  }

  /// Builds the final EMVCo QR payload string (with CRC16 checksum).
  String toPayload() {
    final hasAmount = amount != null && amount!.isNotEmpty;

    final beneficiary = _tlv('00', bankBin) + _tlv('01', accountNumber);
    final merchantAccountInfo =
        _tlv('00', 'A000000727') +
        _tlv('01', beneficiary) +
        _tlv('02', 'QRIBFTTA');

    final buffer = StringBuffer()
      ..write(_tlv('00', '01')) // Payload Format Indicator
      ..write(_tlv('01', hasAmount ? '12' : '11')) // Point of Initiation
      ..write(_tlv('38', merchantAccountInfo)) // NAPAS beneficiary info
      ..write(_tlv('53', '704')); // Currency: VND

    if (hasAmount) buffer.write(_tlv('54', amount!));

    buffer.write(_tlv('58', 'VN')); // Country code

    if (content != null && content!.isNotEmpty) {
      buffer.write(_tlv('62', _tlv('08', content!))); // Purpose of transaction
    }

    final withCrcId = '${buffer.toString()}6304';
    final crc = _crc16(utf8.encode(withCrcId))
        .toRadixString(16)
        .toUpperCase()
        .padLeft(4, '0');
    return '$withCrcId$crc';
  }
}

String _tlv(String id, String value) {
  final length = utf8.encode(value).length.toString().padLeft(2, '0');
  return '$id$length$value';
}

/// CRC-16/CCITT-FALSE, as required by the EMVCo QR Code spec.
int _crc16(List<int> bytes) {
  var crc = 0xFFFF;
  for (final byte in bytes) {
    crc ^= byte << 8;
    for (var i = 0; i < 8; i++) {
      crc = (crc & 0x8000) != 0
          ? ((crc << 1) ^ 0x1021) & 0xFFFF
          : (crc << 1) & 0xFFFF;
    }
  }
  return crc & 0xFFFF;
}
