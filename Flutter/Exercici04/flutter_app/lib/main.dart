import 'package:flutter/material.dart';

import 'api_service.dart';
import 'pages/categories_page.dart';

const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3000',
);

void main() {
    runApp(const PaintingsDbApp());
}

class PaintingsDbApp extends StatelessWidget {
    const PaintingsDbApp({super.key});

    @override
    Widget build(BuildContext context) {
        final api = ApiService(baseUrl: apiBaseUrl);

        return MaterialApp(
            title: 'DB Pinturas clásicas',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
                colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFE60012)),
                scaffoldBackgroundColor: const Color(0xFFF7F8FA),
                useMaterial3: true,
            ),
            home: CategoriesPage(api: api),
        );
    }
}
