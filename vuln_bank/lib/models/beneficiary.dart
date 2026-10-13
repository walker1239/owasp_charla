class Beneficiary {
  Beneficiary({
    required this.id,
    required this.alias,
    required this.accountNumber,
    required this.bank,
  });

  final int id;
  final String alias;
  final String accountNumber;
  final String bank;

  factory Beneficiary.fromJson(Map<String, dynamic> json) => Beneficiary(
        id: json['id'] as int,
        alias: json['alias'] as String,
        accountNumber: json['account_number'] as String,
        bank: json['bank'] as String,
      );
}
