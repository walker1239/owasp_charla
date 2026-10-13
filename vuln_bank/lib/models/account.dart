class Account {
  Account({
    required this.id,
    required this.number,
    required this.balance,
    required this.currency,
  });

  final int id;
  final String number;
  final double balance;
  final String currency;

  factory Account.fromJson(Map<String, dynamic> json) => Account(
        id: json['id'] as int,
        number: json['number'] as String,
        balance: (json['balance'] as num).toDouble(),
        currency: json['currency'] as String? ?? 'PEN',
      );
}

class Transaction {
  Transaction({
    required this.id,
    required this.concept,
    required this.amount,
    required this.createdAt,
  });

  final int id;
  final String concept;
  final double amount;
  final String createdAt;

  factory Transaction.fromJson(Map<String, dynamic> json) => Transaction(
        id: json['id'] as int,
        concept: json['concept'] as String,
        amount: (json['amount'] as num).toDouble(),
        createdAt: json['created_at'] as String,
      );
}
