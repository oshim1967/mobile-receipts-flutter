class Shop {
  final int id;
  final String title;
  final String websiteUrl;

  Shop({required this.id, required this.title, required this.websiteUrl});

  factory Shop.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic v) {
      if (v is int) return v;
      if (v is String) return int.tryParse(v) ?? 0;
      return 0;
    }
    return Shop(
      id: parseInt(json['id']),
      title: json['title'] ?? '',
      websiteUrl: json['website_url'] ?? '',
    );
  }
} 