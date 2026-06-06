class CategoryHelper {
  static const categories = [
    'Food & Drink',
    'Shopping',
    'Transport',
    'Bills & Utilities',
    'Health',
    'Travel',
    'Entertainment',
    'ATM / Cash',
    'Transfer',
    'Other',
  ];

  static const _rules = <String, List<String>>{
    'Food & Drink': [
      'restaurant', 'pizza', 'burger', 'cafe', 'coffee', 'starbucks',
      'mcdonald', 'subway', 'chipotle', 'doordash', 'grubhub', 'ubereats',
      'instacart', 'dining', 'sushi', 'taco', 'diner', 'bakery', 'bar ',
      'brewery', 'wingstop', 'dominos', 'wendy', 'chick-fil', 'panera',
    ],
    'Shopping': [
      'amazon', 'walmart', 'target', 'costco', 'ebay', 'etsy', 'shop',
      'store', 'market', 'best buy', 'apple store', 'nordstrom', 'macy',
      'tj maxx', 'marshalls', 'ross ', 'ikea', 'home depot', 'lowes',
    ],
    'Transport': [
      'uber', 'lyft', 'taxi', 'gas', 'fuel', 'shell', 'chevron', 'bp ',
      'exxon', 'mobil', 'speedway', 'parking', 'mta', 'bart', 'metro',
      'transit', 'train', 'bus ', 'toll',
    ],
    'Bills & Utilities': [
      'electric', 'utility', 'verizon', 'at&t', 'att', 't-mobile', 'sprint',
      'comcast', 'xfinity', 'spectrum', 'netflix', 'spotify', 'hulu',
      'disney+', 'apple one', 'youtube', 'insurance', 'geico', 'allstate',
      'progressive', 'state farm', 'rent', 'mortgage', 'internet', 'water ',
      'sewage', 'trash',
    ],
    'Health': [
      'cvs', 'walgreens', 'rite aid', 'pharmacy', 'doctor', 'hospital',
      'clinic', 'medical', 'dental', 'vision', 'optometry', 'gym',
      'fitness', 'planet fitness', 'health',
    ],
    'Travel': [
      'airline', 'delta', 'united', 'american air', 'southwest', 'jetblue',
      'spirit', 'frontier', 'hotel', 'marriott', 'hilton', 'hyatt',
      'airbnb', 'expedia', 'booking', 'kayak', 'vrbo',
    ],
    'Entertainment': [
      'amc', 'regal', 'cinema', 'movie', 'theater', 'ticketmaster',
      'eventbrite', 'concert', 'museum', 'game', 'steam', 'playstation',
      'xbox', 'nintendo',
    ],
    'ATM / Cash': [
      'atm', 'withdrawal', 'cash advance',
    ],
    'Transfer': [
      'venmo', 'paypal', 'zelle', 'cashapp', 'cash app', 'wire', 'transfer',
      'send money',
    ],
  };

  /// Infer a category from the merchant name.
  static String infer(String merchant) {
    final lower = merchant.toLowerCase();
    for (final entry in _rules.entries) {
      for (final keyword in entry.value) {
        if (lower.contains(keyword)) return entry.key;
      }
    }
    return 'Other';
  }

  static String iconFor(String category) {
    return switch (category) {
      'Food & Drink' => '🍔',
      'Shopping' => '🛍️',
      'Transport' => '🚗',
      'Bills & Utilities' => '💡',
      'Health' => '💊',
      'Travel' => '✈️',
      'Entertainment' => '🎬',
      'ATM / Cash' => '💵',
      'Transfer' => '↕️',
      _ => '📦',
    };
  }
}
