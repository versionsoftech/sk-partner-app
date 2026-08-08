import 'dart:convert';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sixam_mart_store/api/api_client.dart';
import 'package:sixam_mart_store/features/category/domain/models/assignable_food_model.dart';
import 'package:sixam_mart_store/features/category/domain/models/category_model.dart';
import 'package:sixam_mart_store/features/category/domain/repositories/category_repository_interface.dart';
import 'package:sixam_mart_store/features/store/domain/models/item_model.dart';
import 'package:sixam_mart_store/util/app_constants.dart';

class CategoryRepository implements CategoryRepositoryInterface {
  final ApiClient apiClient;
  CategoryRepository({required this.apiClient});

  @override
  Future<List<CategoryModel>?> getCategoryList({bool isRestaurantWise = false, String? search}) async {
    List<CategoryModel>? categoryList;
    final String uri = search != null && search.isNotEmpty
        ? '${AppConstants.categoryUri}?search=$search'
        : AppConstants.categoryUri;
    Response response = await apiClient.getData(uri);
    if (response.statusCode == 200) {
      categoryList = [];
      response.body.forEach((category) => categoryList!.add(CategoryModel.fromJson(category)));
    }
    return categoryList;
  }

  @override
  Future<List<CategoryModel>?> getSubCategoryList(int? parentID, {bool isRestaurantWise = false}) async {
    List<CategoryModel>? subCategoryList;
    Response response = await apiClient.getData('${AppConstants.subCategoryUri}$parentID');
    if (response.statusCode == 200) {
      subCategoryList = [];
      response.body.forEach((subCategory) => subCategoryList!.add(CategoryModel.fromJson(subCategory)));
    }
    return subCategoryList;
  }

  @override
  Future<ItemModel?> getCategoryItemList({required String offset, required int id, required int isSubCategory}) async {
    ItemModel? itemModel;
    Response response = await apiClient.getData('${AppConstants.categoryWiseProducts}/$id?offset=$offset&limit=10&sub_category=$isSubCategory');
    if (response.statusCode == 200) {
      itemModel = ItemModel.fromJson(response.body);
    }
    return itemModel;
  }

  @override
  Future<List<CategoryModel>?> getMyCategoryList({String search = '', int limit = 100, int offset = 1}) async {
    List<CategoryModel>? list;
    final Response response = await apiClient.getData(
      '${AppConstants.storeCategoryListUri}?limit=$limit&offset=$offset&search=$search',
      handleError: false,
    );
    if (response.statusCode == 200) {
      list = [];
      final body = response.body;
      final Iterable items = (body is List) ? body : (body['categories'] ?? body['data'] ?? []);
      for (final item in items) {
        list.add(CategoryModel.fromJson(item));
      }
    }
    return list;
  }

  @override
  Future<CategoryModel?> getStoreCategoryDetails(int id) async {
    final Response response = await apiClient.getData('${AppConstants.storeCategoryDetailsUri}/$id');
    if (response.statusCode == 200) {
      return CategoryModel.fromJson(response.body);
    }
    return null;
  }

  @override
  Future<CategoryModel?> addStoreCategory(List<Translation> translations, String priority, XFile? image) async {
    final Map<String, String> fields = {
      'translations': jsonEncode(translations.map((t) => t.toJson()).toList()),
      'priority': priority,
    };
    final Response response = await apiClient.postMultipartData(
      AppConstants.storeCategoryCreateUri,
      fields,
      [MultipartBody('image', image)],
    );
    if (response.statusCode == 200 && response.body != null) {
      final categoryData = response.body['category'];
      if (categoryData != null) {
        return CategoryModel.fromJson(categoryData);
      }
    }
    return null;
  }

  @override
  Future<bool> updateStoreCategory(int id, List<Translation> translations, String priority, XFile? image) async {
    final Map<String, String> fields = {
      'translations': jsonEncode(translations.map((t) => t.toJson()).toList()),
      'priority': priority,
    };
    final Response response = await apiClient.postMultipartData(
      '${AppConstants.storeCategoryUpdateUri}/$id',
      fields,
      [MultipartBody('image', image)],
    );
    return response.statusCode == 200;
  }

  @override
  Future<bool> deleteStoreCategory(int id) async {
    final Response response = await apiClient.deleteData('${AppConstants.storeCategoryDeleteUri}?id=$id');
    return response.statusCode == 200;
  }

  @override
  Future<bool> updateCategoryStatus(int id, int status) async {
    final Response response = await apiClient.postData(AppConstants.storeCategoryStatusUri, {'id': id, 'status': status});
    return response.statusCode == 200;
  }

  // ── New features ─────────────────────────────────────────────────────────────
  // Requires these AppConstants (add to app_constants.dart if missing):
  //   static const String storeCategoryItemsUri = '...';
  //   static const String assignFoodToCategoryUri = '...';
  //   static const String assignFoodsUri = '...';

  @override
  Future<ItemModel?> getStoreCategoryItems(int id, {required String offset}) async {
    final Response response = await apiClient.getData('${AppConstants.storeCategoryItemsUri}/$id?offset=$offset&limit=10');
    if (response.statusCode == 200) {
      final body = Map<String, dynamic>.from(response.body as Map);
      body['items'] ??= body['products'];
      return ItemModel.fromJson(body);
    }
    return null;
  }

  @override
  Future<AssignableFoodModel?> getAssignableFoods(int categoryId, {required String offset, String search = ''}) async {
    final Response response = await apiClient.getData(
      '${AppConstants.assignFoodToCategoryUri}/$categoryId?offset=$offset&limit=25&search=${Uri.encodeQueryComponent(search)}',
    );
    if (response.statusCode == 200) {
      return AssignableFoodModel.fromJson(response.body);
    }
    return null;
  }

  @override
  Future<bool> assignFoodsToCategory(int categoryId, List<int> foodIds) async {
    print('===========category id: ${categoryId.runtimeType} // foodIds: ${foodIds.runtimeType}===========');
    final Response response = await apiClient.postMultipartData(AppConstants.assignFoodsUri,
        {'category_id': categoryId.toString(), 'item_ids': jsonEncode(foodIds)}, []);
    print('DEBUG assignFoodsToCategory Response statusCode: ${response.statusCode}');
    print('DEBUG assignFoodsToCategory Response statusText: ${response.statusText}');
    print('DEBUG assignFoodsToCategory Response body: ${response.body}');

    // Accept 2xx status codes
    final bool success = response.statusCode != null && response.statusCode! >= 200 && response.statusCode! < 300;
    print('DEBUG assignFoodsToCategory returning: $success');
    return success;
  }

  @override
  Future add(value) {
    throw UnimplementedError();
  }

  @override
  Future delete(int? id) {
    throw UnimplementedError();
  }

  @override
  Future get(int? id) {
    throw UnimplementedError();
  }

  @override
  Future update(Map<String, dynamic> body) {
    throw UnimplementedError();
  }
  
  @override
  Future<dynamic> getList() {
    // TODO: implement getList
    throw UnimplementedError();
  }
}
