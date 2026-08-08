import 'package:sixam_mart_store/features/store/domain/models/item_model.dart';

class CategoryModel {
  int? id;
  String? name;
  String? image;
  int? parentId;
  int? position;
  int? status;
  String? createdAt;
  String? updatedAt;
  int? priority;
  int? moduleId;
  String? slug;
  int? featured;
  int? productsCount;
  int? childesCount;
  String? imageFullUrl;
  List<Translation>? translations;

  CategoryModel({
    this.id,
    this.name,
    this.image,
    this.parentId,
    this.position,
    this.status,
    this.createdAt,
    this.updatedAt,
    this.priority,
    this.moduleId,
    this.slug,
    this.featured,
    this.productsCount,
    this.childesCount,
    this.imageFullUrl,
    this.translations,
  });

  CategoryModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    image = json['image'];
    parentId = json['parent_id'];
    position = json['position'];
    status = json['status'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    priority = json['priority'];
    moduleId = json['module_id'];
    slug = json['slug'];
    featured = json['featured'];
    productsCount = json['items_count'];
    childesCount = json['childes_count'];
    imageFullUrl = json['image_full_url'];
    if (json['translations'] != null) {
      translations = <Translation>[];
      json['translations'].forEach((v) {
        translations!.add(Translation.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    data['image'] = image;
    data['parent_id'] = parentId;
    data['position'] = position;
    data['status'] = status;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    data['priority'] = priority;
    data['module_id'] = moduleId;
    data['slug'] = slug;
    data['featured'] = featured;
    data['products_count'] = productsCount;
    data['childes_count'] = childesCount;
    data['image_full_url'] = imageFullUrl;
    if (translations != null) {
      data['translations'] = translations!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}
