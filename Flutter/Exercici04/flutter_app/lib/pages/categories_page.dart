import 'package:flutter/material.dart';

import '../api_service.dart';
import '../models.dart';
import 'items_page.dart';
import 'search_page.dart';

class CategoriesPage extends StatefulWidget {
    final ApiService api;

    const CategoriesPage({super.key, required this.api});

    @override
    State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
    bool loading = true;
    String? error;
    List<CategoryModel> categories = [];

    @override
    void initState() {
        super.initState();
        _loadCategories();
    }

    Future<void> _loadCategories() async {
        setState(() {
            loading = true;
            error = null;
        });

        try {
            final result = await widget.api.fetchCategories();
            setState(() {
                categories = result;
            });
        } catch (e) {
            setState(() {
                error = 'No se pudieron cargar categorias: $e';
            });
        }

        setState(() {
            loading = false;
        });
    }

    @override
    Widget build(BuildContext context) {
        return Scaffold(
            appBar: AppBar(
                title: const Text('Classic Paintings DB - Categories'),
                actions: [
                    IconButton(
                        icon: const Icon(Icons.search),
                        onPressed: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => SearchPage(api: widget.api),
                                ),
                            );
                        },
                    ),
                ],
            ),
            body: _buildBody(),
        );
    }

    Widget _buildBody() {
        if (loading) {
            return const Center(child: CircularProgressIndicator());
        }

        if (error != null) {
            return Center(
                child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(error!, textAlign: TextAlign.center),
                ),
            );
        }

        return RefreshIndicator(
            onRefresh: _loadCategories,
            child: ListView.builder(
                itemCount: categories.length,
                itemBuilder: (context, index) {
                    final category = categories[index];

                    return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        child: ListTile(
                            title: Text(category.name),
                            subtitle: Text(category.description),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => ItemsPage(
                                            api: widget.api,
                                            category: category,
                                        ),
                                    ),
                                );
                            },
                        ),
                    );
                },
            ),
        );
    }
}