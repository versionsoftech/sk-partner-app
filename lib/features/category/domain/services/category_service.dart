import 'package:image_picker/image_picker.dart';
import 'package:sixam_mart_store/features/category/domain/models/assignable_food_model.dart';
import 'package:sixam_mart_store/features/category/domain/models/category_model.dart';
import 'package:sixam_mart_store/features/category/domain/repositories/category_repository_interface.dart';
import 'package:sixam_mart_store/features/category/domain/services/category_service_interface.dart';
import 'package:sixam_mart_store/features/store/domain/models/item_model.dart';

class CategoryService implements CategoryServiceInterface {
  final CategoryRepositoryInterface categoryRepositoryInterface;
  CategoryService({required this.categoryRepositoryInterface});

  @override
  Future<List<CategoryModel>?> getCategoryList({bool isRestaurantWise = false, String? search}) async {
    return await categoryRepositoryInterface.getCategoryList(isRestaurantWise: isRestaurantWise, search: search);
  }

  @override
  Future<List<CategoryModel>?> getSubCategoryList(int? parentID, {bool isRestaurantWise = false}) async {
    return await categoryRepositoryInterface.getSubCategoryList(parentID, isRestaurantWise: isRestaurantWise);
  }

  @override
  Future<ItemModel?> getCategoryItemList({required String offset, required int id, required int isSubCategory}) async {
    return await categoryRepositoryInterface.getCategoryItemList(offset: offset, id: id, isSubCategory: isSubCategory);
  }

  @override
  Future<List<CategoryModel>?> getMyCategoryList({String search = ''}) async {
    return await categoryRepositoryInterface.getMyCategoryList(search: search);
  }

  @override
  Future<CategoryModel?> getStoreCategoryDetails(int id) async {
    return await categoryRepositoryInterface.getStoreCategoryDetails(id);
  }

  @override
  Future<CategoryModel?> addStoreCategory(List<Translation> translations, String priority, XFile? image) async {
    return await categoryRepositoryInterface.addStoreCategory(translations, priority, image);
  }

  @override
  Future<bool> updateStoreCategory(int id, List<Translation> translations, String priority, XFile? image) async {
    return await categoryRepositoryInterface.updateStoreCategory(id, translations, priority, image);
  }

  @override
  Future<bool> deleteStoreCategory(int id) async {
    return await categoryRepositoryInterface.deleteStoreCategory(id);
  }

  @override
  Future<bool> updateCategoryStatus(int id, int status) async {
    return await categoryRepositoryInterface.updateCategoryStatus(id, status);
  }

  @override
  Future<ItemModel?> getStoreCategoryItems(int id, {required String offset}) async {
    return await categoryRepositoryInterface.getStoreCategoryItems(id, offset: offset);
  }

  @override
  Future<AssignableFoodModel?> getAssignableFoods(int categoryId, {required String offset, String search = ''}) async {
    return await categoryRepositoryInterface.getAssignableFoods(categoryId, offset: offset, search: search);
  }

  @override
  Future<bool> assignFoodsToCategory(int categoryId, List<int> foodIds) async {
    return await categoryRepositoryInterface.assignFoodsToCategory(categoryId, foodIds);
  }
}
