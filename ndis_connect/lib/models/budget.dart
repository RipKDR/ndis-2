class BudgetSummary {
  final String uid;
  final int year;
  final double core;
  final double capacity;
  final double capital;
  final double spentCore;
  final double spentCapacity;
  final double spentCapital;

  BudgetSummary({
    required this.uid,
    required this.year,
    required this.core,
    required this.capacity,
    required this.capital,
    required this.spentCore,
    required this.spentCapacity,
    required this.spentCapital,
  });

  double get remainingCore => (core - spentCore).clamp(0, core);
  double get remainingCapacity => (capacity - spentCapacity).clamp(0, capacity);
  double get remainingCapital => (capital - spentCapital).clamp(0, capital);

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'year': year,
        'core': core,
        'capacity': capacity,
        'capital': capital,
        'spentCore': spentCore,
        'spentCapacity': spentCapacity,
        'spentCapital': spentCapital,
      };

  factory BudgetSummary.fromMap(Map<String, dynamic> m) => BudgetSummary(
        uid: m['uid'] as String,
        year: (m['year'] as num).toInt(),
        core: (m['core'] as num).toDouble(),
        capacity: (m['capacity'] as num).toDouble(),
        capital: (m['capital'] as num).toDouble(),
        spentCore: (m['spentCore'] as num).toDouble(),
        spentCapacity: (m['spentCapacity'] as num).toDouble(),
        spentCapital: (m['spentCapital'] as num).toDouble(),
      );
}

