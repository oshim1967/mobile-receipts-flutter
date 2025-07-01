class Receipt {
  final int id;
  final int shopId;
  final DateTime createdAt;
  final String totalAmount;
  final int type;
  final int state;
  final List<PaymentTransaction> paymentTransactions;

  Receipt({
    required this.id,
    required this.shopId,
    required this.createdAt,
    required this.totalAmount,
    required this.type,
    required this.state,
    required this.paymentTransactions,
  });

  factory Receipt.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic v) {
      if (v is int) return v;
      if (v is String) return int.tryParse(v) ?? 0;
      return 0;
    }
    return Receipt(
      id: parseInt(json['id']),
      shopId: parseInt(json['shop_id']),
      createdAt: DateTime.parse(json['created_at']),
      totalAmount: json['total_amount']?.toString() ?? '0',
      type: parseInt(json['type'] ?? 1),
      state: parseInt(json['state'] ?? 2),
      paymentTransactions: (json['payment_transactions'] as List?)?.map((e) => PaymentTransaction.fromJson(e)).toList() ?? [],
    );
  }
}

class PaymentTransaction {
  final int transactionTypeId;
  final int paymentTypeId;

  PaymentTransaction({required this.transactionTypeId, required this.paymentTypeId});

  factory PaymentTransaction.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic v) {
      if (v is int) return v;
      if (v is String) return int.tryParse(v) ?? 0;
      return 0;
    }
    return PaymentTransaction(
      transactionTypeId: parseInt(json['transaction_type_id'] ?? 0),
      paymentTypeId: parseInt(json['payment_type_id'] ?? 0),
    );
  }
} 