class TransactionDetails {
  final String amount;
  final String merchant;
  final String date;
  final String time;
  final String paymentMethod;

  TransactionDetails({
    required this.amount,
    required this.merchant,
    required this.date,
    required this.time,
    required this.paymentMethod,
  });
}

TransactionDetails parseTransactionText(String text) {
  final lines = text
      .split('\n')
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .toList();

  String amount = '';
  String merchant = '';
  String date = '';
  String time = '';
  String paymentMethod = 'UPI';

  // =========================================================
  // 1. AMOUNT
  // =========================================================

  // First: normal decimal amount such as ₹265.00 or 265.00
  final decimalAmountRegex = RegExp(
    r'(?<!\d)(?:₹\s*)?(\d+(?:,\d{3})*\.\d{2})(?!\d)',
  );

  for (final line in lines) {
    final match = decimalAmountRegex.firstMatch(line);

    if (match != null) {
      amount = match.group(1)!.replaceAll(',', '');
      break;
    }
  }

  // Second: amount explicitly containing ₹
  if (amount.isEmpty) {
    final rupeeRegex = RegExp(
      r'₹\s*(\d+(?:,\d{3})*(?:\.\d{1,2})?)',
    );

    final match = rupeeRegex.firstMatch(text);

    if (match != null) {
      amount = match.group(1)!.replaceAll(',', '');
    }
  }

  // Third: GPay fallback.
  // GPay OCR can sometimes return just "40" instead of "₹40".
  //
  // We only look at the first few lines and reject numbers that
  // look like dates, times, IDs, etc.
  if (amount.isEmpty) {
    final plainAmountRegex = RegExp(
      r'^\d+(?:\.\d{1,2})?$',
    );

    for (int i = 0; i < lines.length && i < 8; i++) {
      final candidate = lines[i].replaceAll(',', '').trim();

      if (!plainAmountRegex.hasMatch(candidate)) {
        continue;
      }

      final value = double.tryParse(candidate);

      if (value == null || value <= 0) {
        continue;
      }

      // Avoid treating very large numbers as an amount.
      if (value > 1000000) {
        continue;
      }

      amount = candidate;
      break;
    }
  }

  // =========================================================
  // 2. MERCHANT
  // =========================================================

  // GPay-specific pattern:
  // "to PURVA NILESH AMBRE"
  // "Paid to PURVA NILESH AMBRE"
  // "Sent to PURVA NILESH AMBRE"

  final merchantPattern = RegExp(
    r'(?:^|\s)(?:to|paid\s+to|sent\s+to|receiver|beneficiary)'
    r'\s*[:\-]?\s+([A-Za-z][A-Za-z .&_-]{2,})$',
    caseSensitive: false,
  );

  for (final line in lines) {
    final match = merchantPattern.firstMatch(line);

    if (match != null) {
      final candidate = match.group(1)!.trim();

      if (_looksLikeMerchant(candidate, candidate.toLowerCase())) {
        merchant = candidate;
        break;
      }
    }
  }

  // Also handle:
  //
  // to
  // PURVA NILESH AMBRE
  //
  if (merchant.isEmpty) {
    for (int i = 0; i < lines.length - 1; i++) {
      final lower = lines[i].toLowerCase();

      if (lower == 'to' ||
          lower == 'paid to' ||
          lower == 'sent to' ||
          lower == 'receiver' ||
          lower == 'beneficiary') {
        final candidate = lines[i + 1].trim();

        if (_looksLikeMerchant(candidate, candidate.toLowerCase())) {
          merchant = candidate;
          break;
        }
      }
    }
  }

  // Existing BHIM-style logic:
  // merchant appears shortly after the amount.
  if (merchant.isEmpty && amount.isNotEmpty) {
    final amountIndex = lines.indexWhere(
      (line) => line.contains(amount),
    );

    if (amountIndex != -1) {
      for (int i = amountIndex + 1;
          i < lines.length && i < amountIndex + 5;
          i++) {
        final candidate = lines[i];
        final lower = candidate.toLowerCase();

        if (_looksLikeMerchant(candidate, lower)) {
          merchant = candidate;
          break;
        }
      }
    }
  }

  // Final fallback: common merchant labels.
  if (merchant.isEmpty) {
    final merchantKeywords = [
      'merchant',
      'paid to',
      'sent to',
      'receiver',
      'beneficiary',
    ];

    for (int i = 0; i < lines.length; i++) {
      final lower = lines[i].toLowerCase();

      for (final keyword in merchantKeywords) {
        if (lower.contains(keyword) && i + 1 < lines.length) {
          final candidate = lines[i + 1].trim();

          if (_looksLikeMerchant(candidate, candidate.toLowerCase())) {
            merchant = candidate;
            break;
          }
        }
      }

      if (merchant.isNotEmpty) {
        break;
      }
    }
  }

  // =========================================================
  // 3. DATE
  // =========================================================

  final dateRegex = RegExp(
    r'\b\d{1,2}(?:st|nd|rd|th)?[\s,]+'
    r'(?:Jan(?:uary)?|Feb(?:ruary)?|Mar(?:ch)?|Apr(?:il)?|'
    r'May|Jun(?:e)?|Jul(?:y)?|Aug(?:ust)?|Sep(?:t(?:ember)?)?|'
    r'Oct(?:ober)?|Nov(?:ember)?|Dec(?:ember)?)'
    r'[\s,]+\d{2,4}\b',
    caseSensitive: false,
  );

  final dateMatch = dateRegex.firstMatch(text);

  if (dateMatch != null) {
    date = dateMatch.group(0)!.replaceAll(',', '').trim();
  }

  // =========================================================
  // 4. TIME
  // =========================================================

  final timeRegex = RegExp(
    r'\b\d{1,2}:\d{2}\s*(?:am|pm)\b',
    caseSensitive: false,
  );

  final timeMatch = timeRegex.firstMatch(text);

  if (timeMatch != null) {
    time = timeMatch.group(0)!;
  }

  // =========================================================
  // 5. PAYMENT METHOD
  // =========================================================

  final lowerText = text.toLowerCase();

  if (lowerText.contains('upi')) {
    paymentMethod = 'UPI';
  } else if (lowerText.contains('card')) {
    paymentMethod = 'Card';
  } else if (lowerText.contains('cash')) {
    paymentMethod = 'Cash';
  } else if (lowerText.contains('net banking')) {
    paymentMethod = 'Net Banking';
  }

  return TransactionDetails(
    amount: amount,
    merchant: merchant,
    date: date,
    time: time,
    paymentMethod: paymentMethod,
  );
}

// =============================================================
// MERCHANT VALIDATION
// =============================================================

bool _looksLikeMerchant(String value, String lower) {
  if (value.length < 3) {
    return false;
  }

  // Don't select another number.
  if (RegExp(r'^\d+$').hasMatch(value)) {
    return false;
  }

  // Don't select transaction IDs.
  if (RegExp(r'^\d{8,}$').hasMatch(value.replaceAll(' ', ''))) {
    return false;
  }

  const ignoredWords = [
    'transaction id',
    'upi transaction id',
    'date',
    'time',
    'date & time',
    'more details',
    'split this',
    'expense',
    'share',
    'screenshot',
    'home',
    'upi help',
    'powered by',
    'banking name',
    'paid',
    'completed',
    'pending',
    'failed',
    'cancelled',
    'upi',
  ];

  for (final word in ignoredWords) {
    if (lower == word) {
      return false;
    }
  }

  // Don't select lines containing date/time information.
  if (RegExp(r'\d{1,2}:\d{2}').hasMatch(value)) {
    return false;
  }

  if (RegExp(
    r'\b\d{1,2}\s+(?:jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)',
    caseSensitive: false,
  ).hasMatch(value)) {
    return false;
  }

  return true;
}