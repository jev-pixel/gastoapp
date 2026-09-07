/// Parser for EMVCo Merchant Presented Mode QR codes — the standard PH
/// e-wallets and banks use under the "QR Ph" scheme (GCash, Maya,
/// UnionBank, BDO, etc. all emit this same TLV format).
///
/// This is NOT the same thing as GastoApp's old `provider|amount|merchant|
/// account` test format — that format is being retired in favor of this
/// parser, which understands what real wallet apps actually generate.
///
/// Spec reference: EMVCo "QR Code Specification for Payment Systems —
/// Merchant Presented Mode", as adopted locally under BSP's QR Ph standard.
library qr_ph_parser;

class QrPhTag {
  final String id;
  final String value;
  const QrPhTag(this.id, this.value);
}

class ParsedQrPh {
  final bool isDynamic; // point of initiation method == '12'
  final String? merchantName; // tag 59
  final String? merchantCity; // tag 60
  final String? countryCode; // tag 58
  final double? amount; // tag 54 — often null for static/person QR codes
  final String currency; // tag 53, decoded from ISO 4217 numeric (608 = PHP)
  final String rawPayload;

  // Raw (unparsed) nested TLV templates. Kept as opaque strings at the
  // top-level split — see QrPhParser._extractSubTag for drilling into
  // them. Null when the scanned code doesn't carry that tag at all
  // (e.g. a real bank QR with no additional data template).
  final String? merchantAccountInfoRaw; // tag 26
  final String? additionalDataRaw; // tag 62

  ParsedQrPh({
    required this.isDynamic,
    required this.merchantName,
    required this.merchantCity,
    required this.countryCode,
    required this.amount,
    required this.currency,
    required this.rawPayload,
    this.merchantAccountInfoRaw,
    this.additionalDataRaw,
  });

  /// True when the code itself doesn't specify how much to pay — the
  /// normal case for static personal/merchant QR Ph codes. The UI must
  /// collect an amount from the user before reserving.
  bool get requiresManualAmount => amount == null || amount! <= 0;

  /// The GastoApp wallet to reserve payment against, read out of tag 26's
  /// sub-tag 01 (see QrPhBuilder._merchantAccountInfo, which writes it
  /// there). Null for any code that isn't GastoApp-generated — e.g. a
  /// real bank/GCash/Maya QR, which uses a registered acquirer GUID
  /// instead of GastoApp's proprietary one and won't carry this sub-tag.
  /// Callers should treat a null here as "not a GastoApp P2P code," not
  /// as a parse error.
  String? get cardWalletId {
    final template = merchantAccountInfoRaw;
    if (template == null) return null;
    return QrPhParser._extractSubTag(template, '01');
  }
}

class QrPhParseException implements Exception {
  final String message;
  QrPhParseException(this.message);
  @override
  String toString() => message;
}

class QrPhParser {
  /// Parses a raw QR string. Throws [QrPhParseException] if the payload
  /// isn't a well-formed EMVCo QR (wrong CRC, truncated TLV, etc.) — the
  /// caller should treat that as "not a QR Ph code" and fall back to
  /// telling the user this isn't a recognized payment code.
  static ParsedQrPh parse(String raw) {
    final trimmed = raw.trim();
    if (trimmed.length < 4) {
      throw QrPhParseException('Code too short to be a QR Ph payload.');
    }

    _verifyCrc(trimmed);

    final tags = _splitTlv(trimmed);
    final tagMap = {for (final t in tags) t.id: t.value};

    final pointOfInitiation = tagMap['01'];
    final isDynamic = pointOfInitiation == '12';

    double? amount;
    final amountStr = tagMap['54'];
    if (amountStr != null && amountStr.isNotEmpty) {
      amount = double.tryParse(amountStr);
    }

    final currencyCode = tagMap['53'];
    final currency = currencyCode == '608' ? 'PHP' : (currencyCode ?? 'PHP');

    return ParsedQrPh(
      isDynamic: isDynamic,
      merchantName: tagMap['59'],
      merchantCity: tagMap['60'],
      countryCode: tagMap['58'],
      amount: amount,
      currency: currency,
      rawPayload: trimmed,
      merchantAccountInfoRaw: tagMap['26'],
      additionalDataRaw: tagMap['62'],
    );
  }

  /// Splits a flat ID(2)+Len(2)+Value TLV string into top-level tags.
  /// Nested templates (e.g. merchant account info under tag 26, or the
  /// additional data template under tag 62) are kept as opaque value
  /// strings here — see [_extractSubTag] for reading a specific sub-field
  /// out of one of those templates on demand.
  static List<QrPhTag> _splitTlv(String data) {
    final tags = <QrPhTag>[];
    var i = 0;
    while (i < data.length) {
      if (i + 4 > data.length) {
        throw QrPhParseException('Truncated TLV field at position $i.');
      }
      final id = data.substring(i, i + 2);
      final lenStr = data.substring(i + 2, i + 4);
      final len = int.tryParse(lenStr);
      if (len == null) {
        throw QrPhParseException('Invalid length field for tag $id.');
      }
      final valueStart = i + 4;
      final valueEnd = valueStart + len;
      if (valueEnd > data.length) {
        throw QrPhParseException('Tag $id declares length $len past end of payload.');
      }
      final value = data.substring(valueStart, valueEnd);
      tags.add(QrPhTag(id, value));
      i = valueEnd;
    }
    return tags;
  }

  /// Extracts a single sub-tag's value from a nested TLV template string
  /// (e.g. the value of top-level tag 26 or 62), using the same
  /// ID(2)+Len(2)+Value scheme as the top-level split. Returns null if
  /// the sub-tag isn't present or the template is malformed — callers
  /// should treat that as "this code doesn't carry that data" rather
  /// than an error, since well-formed QR Ph codes from other issuers
  /// legitimately won't have GastoApp's proprietary sub-tags.
  static String? _extractSubTag(String template, String subTagId) {
    var i = 0;
    while (i + 4 <= template.length) {
      final id = template.substring(i, i + 2);
      final len = int.tryParse(template.substring(i + 2, i + 4));
      if (len == null) return null;
      final valueStart = i + 4;
      final valueEnd = valueStart + len;
      if (valueEnd > template.length) return null;
      if (id == subTagId) return template.substring(valueStart, valueEnd);
      i = valueEnd;
    }
    return null;
  }

  /// Tag 63 (CRC) must be the final field and covers everything before
  /// and including its own ID+Length ("6304"), per spec. This is the
  /// cheapest, most reliable way to reject a scanned code that isn't a
  /// real QR Ph payload before wasting effort on TLV parsing.
  static void _verifyCrc(String data) {
    final crcTagIndex = data.indexOf('6304');
    if (crcTagIndex != data.length - 8) {
      throw QrPhParseException('Missing or misplaced CRC field (tag 63).');
    }
    final dataToCheck = data.substring(0, crcTagIndex + 4);
    final providedCrc = data.substring(crcTagIndex + 4).toUpperCase();
    final computedCrc = _crc16Ccitt(dataToCheck).toRadixString(16).padLeft(4, '0').toUpperCase();
    if (providedCrc != computedCrc) {
      throw QrPhParseException('CRC checksum mismatch — payload may be corrupted or not a QR Ph code.');
    }
  }

  /// CRC-16/CCITT-FALSE (poly 0x1021, init 0xFFFF) — the exact variant
  /// EMVCo specifies for tag 63.
  static int _crc16Ccitt(String input) {
    const poly = 0x1021;
    var crc = 0xFFFF;
    for (final byte in input.codeUnits) {
      crc ^= (byte << 8);
      for (var b = 0; b < 8; b++) {
        if ((crc & 0x8000) != 0) {
          crc = ((crc << 1) ^ poly) & 0xFFFF;
        } else {
          crc = (crc << 1) & 0xFFFF;
        }
      }
    }
    return crc;
  }
}