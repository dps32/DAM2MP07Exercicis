import 'package:flutter/material.dart';

import '../api_service.dart';
import '../models.dart';
import 'detail_page.dart';

class ItemsPage extends StatefulWidget {
    final ApiService api;
    final CategoryModel category;

    const ItemsPage({
        super.key,
        required this.api,
        required this.category,
    });

    @override
    State<ItemsPage> createState() => _ItemsPageState();
}

class _ItemsPageState extends State<ItemsPage> {
    bool loading = true;
    String? error;
    List<ItemSummary> items = [];

    @override
    void initState() {
        super.initState();
        _loadItems();
    }

    Future<void> _loadItems() async {
        setState(() {
            loading = true;
            error = null;
        });

        try {
            final result = await widget.api.fetchItemsByCategory(widget.category.id);
            setState(() {
                items = result;
            });
        } catch (e) {
            setState(() {
                error = 'No se pudieron cargar items: $e';
            });
        }

        setState(() {
            loading = false;
        });
    }

    @override
    Widget build(BuildContext context) {
        return Scaffold(
            appBar: AppBar(title: Text('${widget.category.name} - Items')),
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

        if (items.isEmpty) {
            return const Center(child: Text('No hay items en esta categoria'));
        }

        return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
                final item = items[index];

                return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: ListTile(
                        title: Text(item.title),
                        subtitle: Text('${item.subtitle} (${item.year})'),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => DetailPage(
                                        api: widget.api,
                                        itemId: item.id,
                                    ),
                                ),
                            );
                        },
                    ),
                );
            },
        );
    }
}