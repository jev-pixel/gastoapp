/// Minimal parser for the EMVCo QR Code Specification for Payment Systems
/// (Merchant-Presented Mode) — the TLV-based format underlying QR Ph and
/// used by GCash, Maya, BDO, and every other BSP-supervised app. This is
/// the *same* code regardless of which app displays or reads it — QR Ph
/// does not generally encode "which brand" issued it; the payer's own app
/// resolves the payee's proxy (mobile number / account / email) and
/// settles via InstaPay. There is no provider field to reliably detect
/// here — the provider is whichever wallet the user is paying *from*.
class EmvTlv {
  final String tag;
  final String value;
  const EmvTlv(this.tag, this.value);
}

class EmvQrPayload {
  final String? merchantName;
  final String? merchantCity;
  final String? countryCode;
  final String? currencyCode; // ISO 4217 numeric, PHP = "608"
  final double? amount;       // null for most static/P2P codes
  final bool isStatic;        // tag "01": "11" static, "12" dynamic
  final String? proxyType;    // best-effort — see caveat below
  final String? proxyValue;
  final bool crcValid;
  final List<EmvTlv> rawTlvs; // exposed for debugging/calibration

  const EmvQrPayload({
    this.merchantName,
    this.merchantCity,
    this.countryCode,
    this.currencyCode,
    this.amount,
    required this.isStatic,
    this.proxyType,
    this.proxyValue,
    required this.crcValid,
    required this.rawTlvs,
  });
}

class EmvQrParseException implements Exception {
  final String message;
  EmvQrParseException(this.message);
  @override
  String toString() => message;
}

class EmvQrParser {
  static List<EmvTlv> _tokenize(String data) {
    final tlvs = <EmvTlv>[];
    var i = 0;
    while (i < data.length) {
      if (i + 4 > data.length) break;
      final tag = data.substring(i, i + 2);
      final len = int.tryParse(data.substring(i + 2, i + 4));
      if (len == null) break;
      final start = i + 4;
      final end = start + len;
      if (end > data.length) break;
      tlvs.add(EmvTlv(tag, data.substring(start, end)));
      i = end;
    }
    return tlvs;
  }

  /// EMVCo's trailing checksum: CRC-16/CCITT-FALSE (poly 0x1021, init
  /// 0xFFFF, no reflection). This part of the spec is well-documented and
  /// unambiguous, unlike the proxy sub-tag question below.
  static bool _verifyCrc(String raw) {
    final crcIndex = raw.lastIndexOf('6304');
    if (crcIndex == -1 || crcIndex + 8 != raw.length) return false;
    final toCheck = raw.substring(0, crcIndex + 4);
    final provided = raw.substring(crcIndex + 4).toUpperCase();
    var crc = 0xFFFF;
    for (final byte in toCheck.codeUnits) {
      crc ^= (byte << 8);
      for (var b = 0; b < 8; b++) {
        crc = (crc & 0x8000) != 0 ? ((crc << 1) ^ 0x1021) & 0xFFFF : (crc << 1) & 0xFFFF;
      }
    }
    return crc.toRadixString(16).padLeft(4, '0').toUpperCase() == provided;
  }

  static EmvQrPayload parse(String raw) {
    final root = _tokenize(raw);
    if (root.isEmpty) {
      throw EmvQrParseException('Not a recognizable payment QR code.');
    }

    String? merchantName, merchantCity, countryCode, currencyCode;
    double? amount;
    var isStatic = true;
    String? proxyType, proxyValue;

    for (final tlv in root) {
      switch (tlv.tag) {
        case '01':
          isStatic = tlv.value == '11';
        case '53':
          currencyCode = tlv.value;
        case '54':
          amount = double.tryParse(tlv.value);
        case '58':
          countryCode = tlv.value;
        case '59':
          merchantName = tlv.value;
        case '60':
          merchantCity = tlv.value;
      }

      // Merchant Account Information lives under tags 02–51. QR Ph
      // (BSP Circular 1055) tags its template with the AID
      // "PH.INSTAPAY.ME". CAVEAT: the exact sub-tag numbers below for
      // the proxy type/value are my best-effort inference from the
      // general EMVCo template convention (00 = AID, others = payload),
      // NOT copied from a verified BSP spec table — treat proxyType/
      // proxyValue as provisional until checked against `rawTlvs` from
      // a real scan (see debug dump below).
      final tagNum = int.tryParse(tlv.tag);
      if (tagNum != null && tagNum >= 2 && tagNum <= 51) {
        final sub = _tokenize(tlv.value);
        final aid = sub.firstWhere((s) => s.tag == '00', orElse: () => const EmvTlv('', '')).value;
        if (aid == 'PH.INSTAPAY.ME' || aid == 'com.p2pqrpay') {
          for (final s in sub) {
            switch (s.tag) {
              case '01':
                proxyType = 'MSISDN';
                proxyValue = s.value;
              case '02':
                proxyType = 'ACCT';
                proxyValue = s.value;
              case '03':
                proxyType = 'EMAIL';
                proxyValue = s.value;
            }
          }
        }
      }
    }

    return EmvQrPayload(
      merchantName: merchantName,
      merchantCity: merchantCity,
      countryCode: countryCode,
      currencyCode: currencyCode,
      amount: amount,
      isStatic: isStatic,
      proxyType: proxyType,
      proxyValue: proxyValue,
      crcValid: _verifyCrc(raw),
      rawTlvs: root,
    );
  }
}