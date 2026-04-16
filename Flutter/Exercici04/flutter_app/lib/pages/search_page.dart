import 'package:flutter/material.dart';

import '../api_service.dart';
import '../models.dart';
import 'detail_page.dart';

class SearchPage extends StatefulWidget {
    final ApiService api;

    const SearchPage({super.key, required this.api});

    @override
    State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
    final TextEditingController controller = TextEditingController();

    bool loading = false;
    String? error;
    List<ItemSummary> results = [];

    Future<void> _search() async {
        final query = controller.text.trim();

        if (query.isEmpty) {
            setState(() {
                results = [];
                error = null;
            });
            return;
        }

        setState(() {
            loading = true;
            error = null;
        });

        try {
            final found = await widget.api.searchItems(query);
            setState(() {
                results = found;
            });
        } catch (e) {
            setState(() {
                error = 'Error al buscar: $e';
            });
        }

        setState(() {
            loading = false;
        });
    }

    @override
    void dispose() {
        controller.dispose();
        super.dispose();
    }

    @override
    Widget build(BuildContext context) {
        return Scaffold(
            appBar: AppBar(title: const Text('Search Paintings')),
            body: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                    children: [
                        Row(
                            children: [
                                Expanded(
                                    child: TextField(
                                        controller: controller,
                                        textInputAction: TextInputAction.search,
                                        onSubmitted: (_) => _search(),
                                        decoration: const InputDecoration(
                                            hintText: 'Search by title, artist, category... ',
                                            border: OutlineInputBorder(),
                                        ),
                                    ),
                                ),
                                const SizedBox(width: 8),
                                FilledButton(
                                    onPressed: loading ? null : _search,
                                    child: const Text('Search'),
                                ),
                            ],
                        ),
                        const SizedBox(height: 12),
                        if (loading) const LinearProgressIndicator(),
                        if (error != null)
                            Padding(
                                padding: const EdgeInsets.only(top: 10),
                                child: Text(error!),
                            ),
                        const SizedBox(height: 8),
                        Expanded(child: _buildResultList()),
                    ],
                ),
            ),
        );
    }

    Widget _buildResultList() {
        if (!loading && results.isEmpty && controller.text.trim().isNotEmpty) {
            return const Center(child: Text('No results found'));
        }

        if (results.isEmpty) {
            return const Center(child: Text('Type something and press Search'));
        }

        return ListView.builder(
            itemCount: results.length,
            itemBuilder: (context, index) {
                final item = results[index];

                return Card(
                    child: ListTile(
                        title: Text(item.title),
                        subtitle: Text('${item.subtitle} • ${item.categoryName ?? item.categoryId}'),
                        trailing: const Icon(Icons.open_in_new),
                        onTap: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => DetailPage(api: widget.api, itemId: item.id),
                                ),
                            );
                        },
                    ),
                );
            },
        );
    }
}
