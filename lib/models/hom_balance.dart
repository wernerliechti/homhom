class HomBalance {
  final int balance;
  final bool isUnlimited;
  final String? userApiKey;
  final DateTime lastUpdated;

  const HomBalance({
    required this.balance,
    required this.isUnlimited,
    this.userApiKey,
    required this.lastUpdated,
  });

  factory HomBalance.unlimited(String apiKey) {
    return HomBalance(
      balance: 0, // Irrelevant for unlimited
      isUnlimited: true,
      userApiKey: apiKey,
      lastUpdated: DateTime.now(),
    );
  }

  factory HomBalance.metered(int balance) {
    return HomBalance(
      balance: balance,
      isUnlimited: false,
      userApiKey: null,
      lastUpdated: DateTime.now(),
    );
  }

  factory HomBalance.initial() {
    return HomBalance(
      balance: 10, // 10 free HOMs for new users
      isUnlimited: false,
      userApiKey: null,
      lastUpdated: DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'balance': balance,
      'isUnlimited': isUnlimited ? 1 : 0,
      'userApiKey': userApiKey,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  factory HomBalance.fromMap(Map<String, dynamic> map) {
    return HomBalance(
      balance: map['balance'] as int,
      isUnlimited: (map['isUnlimited'] as int) == 1,
      userApiKey: map['userApiKey'] as String?,
      lastUpdated: DateTime.parse(map['lastUpdated'] as String),
    );
  }

  HomBalance copyWith({
    int? balance,
    bool? isUnlimited,
    String? userApiKey,
    bool clearApiKey = false,
  }) {
    return HomBalance(
      balance: balance ?? this.balance,
      isUnlimited: isUnlimited ?? this.isUnlimited,
      userApiKey: clearApiKey ? null : (userApiKey ?? this.userApiKey),
      lastUpdated: DateTime.now(),
    );
  }

  /// Check if user can perform a scan
  bool get canScan => isUnlimited || balance > 0;

  /// Get display string for balance
  String get displayBalance => isUnlimited ? '∞' : balance.toString();

  /// Consume one HOM (only for metered users)
  HomBalance consumeHom() {
    if (isUnlimited) return this;
    if (balance <= 0) throw Exception('No HOMs remaining');
    
    return copyWith(balance: balance - 1);
  }

  /// Add HOMs (only for metered users)
  HomBalance addHoms(int homs) {
    if (isUnlimited) return this;
    
    return copyWith(balance: balance + homs);
  }

  /// Switch to unlimited mode with API key
  HomBalance switchToUnlimited(String apiKey) {
    return HomBalance.unlimited(apiKey);
  }

  /// Switch to metered mode
  HomBalance switchToMetered(int initialBalance) {
    return HomBalance.metered(initialBalance);
  }
}

/// HOM pack offerings
class HomPack {
  final String id;
  final int homs;
  final double price;
  final String displayPrice;
  final String description;
  final bool isPopular;

  const HomPack({
    required this.id,
    required this.homs,
    required this.price,
    required this.displayPrice,
    required this.description,
    this.isPopular = false,
  });

  static const List<HomPack> availablePacks = [
    HomPack(
      id: 'hom_pack_10',
      homs: 10,
      price: 2.0,
      displayPrice: '\$2',
      description: '10 HOMs',
    ),
    HomPack(
      id: 'hom_pack_100',
      homs: 100,
      price: 10.0,
      displayPrice: '\$10',
      description: '100 HOMs',
      isPopular: true,
    ),
    HomPack(
      id: 'hom_pack_1000',
      homs: 1000,
      price: 50.0,
      displayPrice: '\$50',
      description: '1000 HOMs',
    ),
  ];

  /// Get price per HOM for comparison
  double get pricePerHom => price / homs;

  /// Get savings percentage compared to smallest pack
  int get savingsPercent {
    const smallestPackPrice = 0.2; // $2 for 10 HOMs = $0.2 per HOM
    final savings = (smallestPackPrice - pricePerHom) / smallestPackPrice;
    return (savings * 100).round();
  }
}