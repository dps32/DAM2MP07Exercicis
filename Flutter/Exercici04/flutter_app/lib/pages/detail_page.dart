import 'package:flutter/material.dart';

import '../api_service.dart';
import '../models.dart';

class DetailPage extends StatefulWidget {
    final ApiService api;
    final String itemId;

    const DetailPage({
        super.key,
        required this.api,
        required this.itemId,
    });

    @override
    State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
    bool loading = true;
    String? error;
    ItemDetail? detail;

    @override
    void initState() {
        super.initState();
        _loadDetail();
    }

    Future<void> _loadDetail() async {
        setState(() {
            loading = true;
            error = null;
        });

        try {
            final result = await widget.api.fetchItemDetail(widget.itemId);
            setState(() {
                detail = result;
            });
        } catch (e) {
            setState(() {
                error = 'No se pudo cargar el detalle: $e';
            });
        }

        setState(() {
            loading = false;
        });
    }

    @override
    Widget build(BuildContext context) {
        return Scaffold(
            appBar: AppBar(title: const Text('Detalle Item')),
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

        if (detail == null) {
            return const Center(child: Text('No hay detalle disponible'));
        }

        final item = detail!;

        return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: LayoutBuilder(
                builder: (context, constraints) {
                    final bool sideLayout = constraints.maxWidth >= 720;

                    if (sideLayout) {
                        return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                                Expanded(
                                    flex: 4,
                                    child: _buildImageCard(item, 520),
                                ),
                                const SizedBox(width: 20),
                                Expanded(
                                    flex: 5,
                                    child: _buildTextInfo(item),
                                ),
                            ],
                        );
                    }

                    return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                            _buildImageCard(item, 420),
                            const SizedBox(height: 16),
                            _buildTextInfo(item),
                        ],
                    );
                },
            ),
        );
    }

    Widget _buildImageCard(ItemDetail item, double height) {
        return Container(
            height: height,
            width: double.infinity,
            decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                    widget.api.imageUrl(item.image),
                    fit: BoxFit.contain,
                    errorBuilder: (context, errorValue, stack) {
                        return Container(
                            color: Colors.grey.shade300,
                            alignment: Alignment.center,
                            child: const Text('No se pudo cargar la imagen'),
                        );
                    },
                ),
            ),
        );
    }

    Widget _buildTextInfo(ItemDetail item) {
        return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                Text(item.title, style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 8),
                Text(item.subtitle, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Text('Category: ${item.categoryName}'),
                const SizedBox(height: 4),
                Text('Year: ${item.year}'),
                const SizedBox(height: 16),
                Text(item.description, style: Theme.of(context).textTheme.bodyLarge),
            ],
        );
    }
}