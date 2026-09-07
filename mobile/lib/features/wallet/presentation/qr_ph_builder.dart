/// Builds a spec-shaped EMVCo/QR Ph (EMV QRCPS) payload for GastoApp-to-
/// GastoApp transfers.
///
/// IMPORTANT: GastoApp is not a BSP-registered QR Ph participant, so the
/// Merchant Account Information template below uses a private/proprietary
/// GUID ("com.gastoapp.p2p") rather than a real acquirer-issued GUID. That
/// means:
///   - A GastoApp phone scanning a GastoApp-generated code works fine,
///     because QrPhParser knows how to read our own proprietary template
///     (see QrPhParser/ParsedQrPh.cardWalletId).
///   - A real bank/GCash/Maya scanner will NOT recognize this code as a
///     valid QR Ph merchant payment, since our GUID isn't in the registry.
///
/// The TLV structure, length encoding, and CRC (CRC-16/CCITT-FALSE) are
/// otherwise built to the real EMVCo spec so the payload is well-formed
/// and passes CRC verification against QrPhParser.
library qr_ph_builder;

class QrPhBuilder {
  QrPhBuilder._();

  static const String _proprietaryGuid = 'com.gastoapp.p2p';
  static const String _merchantCategoryCode = '0000'; // unclassified
  static const String _currencyPhp = '608'; // ISO 4217 numeric
  static const String _countryCode = 'PH';
  static const String _defaultMerchantCity = 'MANILA';

  /// Builds the full payload string, including the trailing CRC.
  ///
  /// [cardWalletId] identifies the receiving wallet and is carried inside
  /// the proprietary Merchant Account Information template (tag 26, sub-tag
  /// 01) so the paying device — and our backend, on scan — knows which
  /// wallet to reserve funds against. QrPhParser.ParsedQrPh.cardWalletId
  /// reads it back out of that same sub-tag.
  /// [merchantName] is shown to the payer and is truncated to the EMVCo
  /// 25-character limit for tag 59.
  /// [amount] must be > 0 — callers are expected to gate on this before
  /// calling build(), since a zero/blank amount produces a payload the
  /// backend's QrReserveRequest (Field(gt=0)) will always reject.
  static String build({
    required String cardWalletId,
    required String merchantName,
    required double amount,
  }) {
    assert(amount > 0, 'QrPhBuilder.build requires amount > 0');

    final buffer = StringBuffer()
      ..write(_tlv('00', '01')) // Payload Format Indicator
      ..write(_tlv('01', '12')) // Point of Initiation Method: 12 = dynamic (single-use, amount included)
      ..write(_tlv('26', _merchantAccountInfo(cardWalletId)))
      ..write(_tlv('52', _merchantCategoryCode))
      ..write(_tlv('53', _currencyPhp))
      ..write(_tlv('54', _formatAmount(amount)))
      ..write(_tlv('58', _countryCode))
      ..write(_tlv('59', _truncate(merchantName, 25)))
      ..write(_tlv('60', _defaultMerchantCity));

    // CRC covers everything written so far PLUS the "6304" tag/length
    // prefix of the CRC field itself, per EMVCo spec.
    final withCrcTag = '${buffer.toString()}6304';
    final crc = _crc16CcittFalse(withCrcTag);
    return '$withCrcTag$crc';
  }

  /// Merchant Account Information template (tag 26).
  /// Sub-tag 00: Globally Unique Identifier (our proprietary reverse-DNS id)
  /// Sub-tag 01: the wallet id payment should be reserved against — this is
  /// the sub-tag QrPhParser.ParsedQrPh.cardWalletId reads back out.
  static String _merchantAccountInfo(String cardWalletId) {
    final sub = StringBuffer()
      ..write(_tlv('00', _proprietaryGuid))
      ..write(_tlv('01', cardWalletId));
    return sub.toString();
  }

  static String _formatAmount(double amount) {
    // EMVCo amount field: up to 13 digits, decimal point, max 2 decimals,
    // no leading zeros, no trailing zeros beyond 2dp, no currency symbol.
    return amount.toStringAsFixed(2);
  }

  static String _truncate(String value, int maxLength) {
    return value.length <= maxLength ? value : value.substring(0, maxLength);
  }

  /// Encodes a single TLV field: 2-digit tag, 2-digit length, value.
  static String _tlv(String id, String value) {
    final length = value.length.toString().padLeft(2, '0');
    return '$id$length$value';
  }

  /// CRC-16/CCITT-FALSE: poly 0x1021, init 0xFFFF, no reflect, no xorout.
  /// This is the exact variant QrPhParser._crc16Ccitt verifies against.
  static String _crc16CcittFalse(String data) {
    const poly = 0x1021;
    var crc = 0xFFFF;

    for (final byte in data.codeUnits) {
      crc ^= byte << 8;
      for (var i = 0; i < 8; i++) {
        if ((crc & 0x8000) != 0) {
          crc = (crc << 1) ^ poly;
        } else {
          crc = crc << 1;
        }
        crc &= 0xFFFF;
      }
    }

    return crc.toRadixString(16).toUpperCase().padLeft(4, '0');
  }
}