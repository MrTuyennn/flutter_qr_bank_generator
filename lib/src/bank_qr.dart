import 'dart:convert';

final RegExp _bankBinPattern = RegExp(r'^\d{6}$');
final RegExp _accountNumberPattern = RegExp(r'^\d{6,19}$');
final RegExp _amountPattern = RegExp(r'^\d{1,13}$');
final RegExp _contentCharsetPattern = RegExp(r'^[A-Za-z0-9 ]*$');
final RegExp _whitespacePattern = RegExp(r'\s+');

/// Builds an EMVCo-compliant NAPAS bank-transfer QR payload string.
class BankQrData {
  final String bankBin;
  final String accountNumber;
  final String? amount;

  /// Transfer message / purpose, shown to the payer's banking app.
  final String? content;

  BankQrData({
    required String bankBin,
    required String accountNumber,
    String? amount,
    String? content,
  }) : bankBin = _validateBankBin(bankBin),
       accountNumber = _validateAccountNumber(accountNumber),
       amount = _validateAmount(amount),
       content = _normalizeContent(content);

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

/// Exactly 6 digits after trimming. Invalid characters are rejected, never
/// silently stripped.
String _validateBankBin(String value) {
  final trimmed = value.trim();
  if (!_bankBinPattern.hasMatch(trimmed)) {
    throw ArgumentError.value(
      value,
      'bankBin',
      'must be exactly 6 digits',
    );
  }
  return trimmed;
}

/// Digits only, 6–19 characters after trimming. Kept as a [String] so
/// leading zeros are preserved.
String _validateAccountNumber(String value) {
  final trimmed = value.trim();
  if (!_accountNumberPattern.hasMatch(trimmed)) {
    throw ArgumentError.value(
      value,
      'accountNumber',
      'must contain only digits, 6-19 characters long',
    );
  }
  return trimmed;
}

/// Optional (static QR). When provided: digits only, 1–13 characters, and
/// greater than zero. No separators, decimals, or currency symbols — kept
/// as a [String], never parsed as a [double].
String? _validateAmount(String? value) {
  if (value == null) return null;
  final trimmed = value.trim();
  if (trimmed.isEmpty) return null;

  if (!_amountPattern.hasMatch(trimmed)) {
    throw ArgumentError.value(
      value,
      'amount',
      'must contain only digits (no separators, decimals, or currency symbols), '
          'at most 13 digits',
    );
  }
  if (int.parse(trimmed) <= 0) {
    throw ArgumentError.value(value, 'amount', 'must be greater than 0');
  }
  return trimmed;
}

/// Optional. Trimmed, with internal whitespace collapsed to single spaces.
/// Only plain ASCII letters, digits, and spaces are allowed — no Vietnamese
/// diacritics or other special characters — and at most 25 characters after
/// normalization.
String? _normalizeContent(String? value) {
  if (value == null) return null;
  final trimmed = value.trim();
  if (trimmed.isEmpty) return null;

  final collapsed = trimmed.replaceAll(_whitespacePattern, ' ');

  if (!_contentCharsetPattern.hasMatch(collapsed)) {
    throw ArgumentError.value(
      value,
      'content',
      'must contain only A-Z, a-z, 0-9 and spaces (no Vietnamese diacritics '
          'or special characters)',
    );
  }
  if (collapsed.length > 25) {
    throw ArgumentError.value(
      value,
      'content',
      'must be at most 25 characters',
    );
  }
  return collapsed;
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
