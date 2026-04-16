class CategoryModel {
    final String id;
    final String name;
    final String description;

    CategoryModel({
        required this.id,
        required this.name,
        required this.description,
    });

    factory CategoryModel.fromJson(Map<String, dynamic> json) {
        return CategoryModel(
            id: json['id'] as String,
            name: json['name'] as String,
            description: json['description'] as String,
        );
    }
}

class ItemSummary {
    final String id;
    final String title;
    final String subtitle;
    final String year;
    final String image;
    final String categoryId;
    final String? categoryName;

    ItemSummary({
        required this.id,
        required this.title,
        required this.subtitle,
        required this.year,
        required this.image,
        required this.categoryId,
        this.categoryName,
    });

    factory ItemSummary.fromJson(Map<String, dynamic> json) {
        return ItemSummary(
            id: json['id'] as String,
            title: json['title'] as String,
            subtitle: json['subtitle'] as String,
            year: json['year'] as String,
            image: json['image'] as String,
            categoryId: json['categoryId'] as String,
            categoryName: json['categoryName'] as String?,
        );
    }
}

class ItemDetail {
    final String id;
    final String title;
    final String subtitle;
    final String year;
    final String image;
    final String description;
    final String categoryId;
    final String categoryName;

    ItemDetail({
        required this.id,
        required this.title,
        required this.subtitle,
        required this.year,
        required this.image,
        required this.description,
        required this.categoryId,
        required this.categoryName,
    });

    factory ItemDetail.fromJson(Map<String, dynamic> json) {
        return ItemDetail(
            id: json['id'] as String,
            title: json['title'] as String,
            subtitle: json['subtitle'] as String,
            year: json['year'] as String,
            image: json['image'] as String,
            description: json['description'] as String,
            categoryId: json['categoryId'] as String,
            categoryName: json['categoryName'] as String,
        );
    }
}