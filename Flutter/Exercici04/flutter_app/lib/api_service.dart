import 'dart:convert';

import 'package:http/http.dart' as http;

import 'models.dart';

class ApiService {
    final String baseUrl;

    ApiService({required this.baseUrl});

    // Todas las consultas de datos van por POST
    Future<Map<String, dynamic>> _post(
        String endpoint,
        Map<String, dynamic> body,
    ) async {
        final uri = Uri.parse('$baseUrl$endpoint');

        final response = await http.post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
        );

        if (response.statusCode < 200 || response.statusCode >= 300) {
            throw Exception('Request failed: ${response.statusCode}');
        }

        final decoded = jsonDecode(response.body);
        return decoded as Map<String, dynamic>;
    }

    Future<List<CategoryModel>> fetchCategories() async {
        final raw = await _post('/categories', {});
        final rawList = raw['data'] as List<dynamic>;

        final result = <CategoryModel>[];
        for (int i = 0; i < rawList.length; i += 1) {
            final item = rawList[i] as Map<String, dynamic>;
            result.add(CategoryModel.fromJson(item));
        }

        return result;
    }

    Future<List<ItemSummary>> fetchItemsByCategory(String categoryId) async {
        final raw = await _post('/items', {'categoryId': categoryId});
        final rawList = raw['data'] as List<dynamic>;

        final result = <ItemSummary>[];
        for (int i = 0; i < rawList.length; i += 1) {
            final item = rawList[i] as Map<String, dynamic>;
            result.add(ItemSummary.fromJson(item));
        }

        return result;
    }

    Future<ItemDetail> fetchItemDetail(String itemId) async {
        final raw = await _post('/detail', {'itemId': itemId});
        final detail = raw['data'] as Map<String, dynamic>;

        return ItemDetail.fromJson(detail);
    }

    Future<List<ItemSummary>> searchItems(String query) async {
        final raw = await _post('/search', {'query': query});
        final rawList = raw['data'] as List<dynamic>;

        final result = <ItemSummary>[];
        for (int i = 0; i < rawList.length; i += 1) {
            final item = rawList[i] as Map<String, dynamic>;
            result.add(ItemSummary.fromJson(item));
        }

        return result;
    }

    String imageUrl(String imageName) {
        return '$baseUrl/images/$imageName';
    }
}