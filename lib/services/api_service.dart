import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/shop.dart';
import '../models/receipt.dart';

class ApiService {
  final String login;
  final String password;
  final String apiKey;
  final String token;

  static const String baseUrl = 'https://core.smartkasa.ua';

  ApiService({required this.login, required this.password, required this.apiKey, required this.token});

  /// Получение токена (авторизация)
  static Future<String> getToken({required String login, required String password, required String apiKey}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/v1/auth/sessions'),
      headers: {
        if (apiKey.isNotEmpty) 'X-API-KEY': apiKey,
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'phone_number': login, 'password': password}),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return data['token'] ?? data['data']?['access'] ?? '';
    } else {
      throw Exception('Ошибка авторизации: ${response.statusCode} ${response.body}');
    }
  }

  Future<List<Shop>> getShops() async {
    final List<Shop> shops = [];
    int page = 1;
    while (true) {
      final response = await http.get(
        Uri.parse('$baseUrl/api/v1/rsn/shops?page=$page'),
        headers: {
          if (apiKey.isNotEmpty) 'X-API-KEY': apiKey,
          'Authorization': token,
          'Content-Type': 'application/json',
        },
      );
      if (response.statusCode != 200) {
        print('GET SHOPS ERROR: status = ${response.statusCode}, body = ${response.body}');
        break;
      }
      final data = jsonDecode(response.body);
      final List items = data['data'] ?? [];
      shops.addAll(items.map((e) => Shop.fromJson(e)));
      if (data['meta']?['next_page'] == null) break;
      page = data['meta']['next_page'];
    }
    return shops;
  }

  Future<List<Receipt>> getReceipts(DateTime dateStart, DateTime dateEnd) async {
    final List<Receipt> receipts = [];
    int page = 1;
    while (true) {
      final response = await http.get(
        Uri.parse('$baseUrl/api/v1/pos/receipts?date_start=${dateStart.toIso8601String()}&date_end=${dateEnd.toIso8601String()}&per_page=800&page=$page'),
        headers: {
          if (apiKey.isNotEmpty) 'X-API-KEY': apiKey,
          'Authorization': token,
          'Content-Type': 'application/json',
        },
      );
      if (response.statusCode != 200) {
        print('GET RECEIPTS ERROR: status = ${response.statusCode}, body = ${response.body}');
        break;
      }
      final data = jsonDecode(response.body);
      final List items = data['data'] ?? [];
      receipts.addAll(items.map((e) => Receipt.fromJson(e)));
      if (data['meta']?['next_page'] == null) break;
      page = data['meta']['next_page'];
    }
    return receipts;
  }
} 