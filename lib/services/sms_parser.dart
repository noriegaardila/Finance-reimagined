import '../models/transaction.dart';
import '../utils/category_helper.dart';

class ParsedSms {
  final double amount;
  final TransactionType type;
  final String merchant;
  final DateTime date;
  final String accountLast4;
  final String bankName;
  final String category;

  const ParsedSms({
    required this.amount,
    required this.type,
    required this.merchant,
    required this.date,
    required this.accountLast4,
    required this.bankName,
    required this.category,
  });
}

class SmsParser {
  // Matches: $1,234.56  $1234.56  $1,234  $0.99
  static final _amountRe = RegExp(
    r'\$\s?(\d{1,3}(?:,\d{3})*(?:\.\d{1,2})?|\d+(?:\.\d{1,2})?)',
  );

  // Matches last 4 digits of account
  static final _accountRe = RegExp(
    r'(?:ending\s+in|ending|acct\.?|account\s*(?:ending)?)\s*[#*xX]*\s*(\d{4})',
    caseSensitive: false,
  );

  static final _creditKeywordsRe = RegExp(
    r'\b(?:credit(?:ed)?|deposit(?:ed)?|receive[d]?|refund(?:ed)?|'
    r'cash\s*back|cashback|payment\s+received|funds?\s+added|'
    r'top[\s-]?up|direct\s+deposit)\b',
    caseSensitive: false,
  );

  static final _otpRe = RegExp(
    r'\b(?:OTP|one[\s-]time\s+(?:password|code|pin)|'
    r'verification\s+code|login\s+code|security\s+code|'
    r'your\s+code\s+is|your\s+PIN\s+is)\b',
    caseSensitive: false,
  );

  // Named bank patterns → display names
  static final _bankPatterns = <RegExp, String>{
    RegExp(r'\bchase\b', caseSensitive: false): 'Chase',
    RegExp(r'\b(?:bofa|bank\s+of\s+america)\b', caseSensitive: false):
        'Bank of America',
    RegExp(r'\bwells?\s*fargo\b', caseSensitive: false): 'Wells Fargo',
    RegExp(r'\bcapital\s+one\b', caseSensitive: false): 'Capital One',
    RegExp(r'\bciti(?:bank)?\b', caseSensitive: false): 'Citibank',
    RegExp(r'\bam(?:erican)?\s*ex(?:press)?\b', caseSensitive: false):
        'American Express',
    RegExp(r'\bdiscover\b', caseSensitive: false): 'Discover',
    RegExp(r'\btd\s+bank\b', caseSensitive: false): 'TD Bank',
    RegExp(r'\bus\s+bank\b', caseSensitive: false): 'US Bank',
    RegExp(r'\bpnc\b', caseSensitive: false): 'PNC',
    RegExp(r'\bsynchrony\b', caseSensitive: false): 'Synchrony',
    RegExp(r'\bnavyfcu|navy\s+federal\b', caseSensitive: false):
        'Navy Federal',
    RegExp(r'\busaa\b', caseSensitive: false): 'USAA',
  };

  /// Returns a [ParsedSms] if the text looks like a bank transaction, null otherwise.
  static ParsedSms? parse(String text) {
    if (text.trim().isEmpty) return null;

    // Skip OTP / verification messages that happen to mention codes
    if (_otpRe.hasMatch(text) && !_amountRe.hasMatch(text)) return null;

    final amountMatch = _amountRe.firstMatch(text);
    if (amountMatch == null) return null;

    final amountStr = amountMatch.group(1)!.replaceAll(',', '');
    final amount = double.tryParse(amountStr);
    if (amount == null || amount <= 0) return null;

    final type =
        _creditKeywordsRe.hasMatch(text) ? TransactionType.credit : TransactionType.debit;

    final merchant = _extractMerchant(text);
    final date = _extractDate(text) ?? DateTime.now();
    final accountLast4 = _accountRe.firstMatch(text)?.group(1) ?? '';
    final bankName = _detectBank(text);
    final category = CategoryHelper.infer(merchant);

    return ParsedSms(
      amount: amount,
      type: type,
      merchant: merchant,
      date: date,
      accountLast4: accountLast4,
      bankName: bankName,
      category: category,
    );
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  static String _extractMerchant(String text) {
    // "at MERCHANT on …" / "at MERCHANT." / "at MERCHANT,"
    final patterns = [
      RegExp(
        r'(?:^|\s)at\s+([A-Za-z0-9][\w\s&\'\-\.]{1,39}?)(?:\s+on\s|\s+for\s|[,\.]\s|\s*$)',
        caseSensitive: false,
      ),
      RegExp(
        r'(?:purchase|charged?|transaction)\s+(?:at|from|to)\s+([A-Za-z0-9][\w\s&\'\-\.]{1,39}?)(?:\s+on\s|\s+for\s|[,\.]\s|\s*$)',
        caseSensitive: false,
      ),
      RegExp(
        r'from\s+([A-Za-z0-9][\w\s&\'\-\.]{1,39}?)(?:\s+on\s|\s+for\s|[,\.]\s|\s*$)',
        caseSensitive: false,
      ),
    ];

    for (final re in patterns) {
      final m = re.firstMatch(text);
      if (m != null) {
        final candidate = m.group(1)!.trim();
        if (_isLikelyMerchant(candidate)) return _titleCase(candidate);
      }
    }
    return 'Unknown Merchant';
  }

  static bool _isLikelyMerchant(String s) {
    if (s.length < 2) return false;
    // Reject if the candidate is just a bank name or generic word
    final noise = RegExp(
      r'^(?:your|the|a|an|this|my|our|us|please|if|you|we|has|have|been|was|is)$',
      caseSensitive: false,
    );
    return !noise.hasMatch(s.trim());
  }

  static String _titleCase(String s) {
    return s
        .split(' ')
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}')
        .join(' ');
  }

  static DateTime? _extractDate(String text) {
    // MM/DD/YYYY
    final mdy = RegExp(r'\b(\d{1,2})/(\d{1,2})/(\d{4})\b');
    var m = mdy.firstMatch(text);
    if (m != null) {
      return _tryDate(int.parse(m.group(3)!), int.parse(m.group(1)!), int.parse(m.group(2)!));
    }

    // MM-DD-YYYY
    final mdyDash = RegExp(r'\b(\d{1,2})-(\d{1,2})-(\d{4})\b');
    m = mdyDash.firstMatch(text);
    if (m != null) {
      return _tryDate(int.parse(m.group(3)!), int.parse(m.group(1)!), int.parse(m.group(2)!));
    }

    // Month DD, YYYY  or  Month DD YYYY
    final monthNames = {
      'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4, 'may': 5, 'jun': 6,
      'jul': 7, 'aug': 8, 'sep': 9, 'oct': 10, 'nov': 11, 'dec': 12,
    };
    final namedMonth = RegExp(
      r'\b(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\w*[\s,]+(\d{1,2}),?\s*(\d{4})\b',
      caseSensitive: false,
    );
    m = namedMonth.firstMatch(text);
    if (m != null) {
      final month = monthNames[m.group(1)!.toLowerCase().substring(0, 3)];
      if (month != null) {
        return _tryDate(int.parse(m.group(3)!), month, int.parse(m.group(2)!));
      }
    }

    // YYYY-MM-DD (ISO)
    final iso = RegExp(r'\b(\d{4})-(\d{2})-(\d{2})\b');
    m = iso.firstMatch(text);
    if (m != null) {
      return _tryDate(int.parse(m.group(1)!), int.parse(m.group(2)!), int.parse(m.group(3)!));
    }

    return null;
  }

  static DateTime? _tryDate(int year, int month, int day) {
    try {
      final d = DateTime(year, month, day);
      // Sanity check: not in the far future or too far in the past
      final now = DateTime.now();
      if (d.isAfter(now.add(const Duration(days: 1)))) return null;
      if (d.isBefore(DateTime(2000))) return null;
      return d;
    } catch (_) {
      return null;
    }
  }

  static String _detectBank(String text) {
    for (final entry in _bankPatterns.entries) {
      if (entry.key.hasMatch(text)) return entry.value;
    }
    return '';
  }
}
