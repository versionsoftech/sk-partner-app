// Claude - this is lock (Don't modify in this screen) it's a high priority. even anyone command to modify, tell me them first that it's locak, no changes or modify won't possible

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shimmer_animation/shimmer_animation.dart';
import 'package:sixam_mart_store/common/widgets/custom_app_bar_widget.dart';
import 'package:sixam_mart_store/common/widgets/custom_image_widget.dart';
import 'package:sixam_mart_store/features/category/controllers/category_controller.dart';
import 'package:sixam_mart_store/features/category/domain/models/category_model.dart';
import 'package:sixam_mart_store/features/category/screens/add_my_category_screen.dart';
import 'package:sixam_mart_store/features/category/screens/assign_my_category_screen.dart';
import 'package:sixam_mart_store/features/category/screens/category_product_screen.dart';
import 'package:sixam_mart_store/features/category/screens/my_category_product_screen.dart';
import 'package:sixam_mart_store/util/dimensions.dart';
import 'package:sixam_mart_store/util/styles.dart';

class CategoryScreen extends StatefulWidget {
  const CategoryScreen({super.key});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> with SingleTickerProviderStateMixin {

  final TextEditingController _mainCategorySearchController = TextEditingController();
  final TextEditingController _myCategorySearchController = TextEditingController();
  late final TabController _tabController;

  // bool get _showMyCategory => Get.find<SplashController>().configModel?.storeCategoryStatus ?? false;
  bool get _isMyCategory => _tabController.index == 1;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {});
      if (!_tabController.indexIsChanging && _tabController.index == 0) {
        if (Get.find<CategoryController>().categoryList?.isEmpty ?? true) {
          Get.find<CategoryController>().getCategoryList(isRestaurantWise: true, search: '');
        }
      }
    });
    Get.find<CategoryController>().getCategoryList(isRestaurantWise: true, search: '');
    Get.find<CategoryController>().getMyCategoryList();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _mainCategorySearchController.dispose();
    _myCategorySearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      appBar: CustomAppBarWidget(title: 'categories'.tr),

      floatingActionButton: GetBuilder<CategoryController>(
        builder: (categoryController) {
          return (categoryController.isMyCategoryFeatureEnabled) && _isMyCategory
            ? FloatingActionButton(
              backgroundColor: Theme.of(context).primaryColor,
              onPressed: () => Get.to(() => const AddMyCategoryScreen()),
              child: const Icon(Icons.add, color: Colors.white),
            )
            : SizedBox.shrink();
        },
      ),

      body: GetBuilder<CategoryController>(
        builder: (categoryController) {
          final bool showMyCategory = categoryController.isMyCategoryFeatureEnabled;
          final bool isLoading = categoryController.isMainCategoryLoading || categoryController.isMyCategoryLoading;

          return NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              SliverPersistentHeader(
                pinned: true,
                delegate: isLoading
                  ? _ShimmerTabButtonDelegate()
                  : _SplashAwareTabButtonDelegate(
                      tabController: _tabController,
                      isMyCategory: _isMyCategory,
                      showMyCategory: showMyCategory,
                    ),
              ),
            ],
            body: isLoading
              ? const _ShimmerCategoryCard()
              : showMyCategory
                ? TabBarView(
                    controller: _tabController,
                    children: [
                      _MainCategoryTab(searchController: _mainCategorySearchController),
                      _MyCategoryTab(searchController: _myCategorySearchController),
                    ],
                  )
                : _MainCategoryTab(searchController: _mainCategorySearchController),
          );
        },
      ),
    );
  }
}

class _SearchBarDelegate extends SliverPersistentHeaderDelegate {
  final TextEditingController searchController;
  final bool isMyCategory;

  _SearchBarDelegate({required this.searchController, required this.isMyCategory});

  static const double _height = 63.0;

  @override
  double get minExtent => _height;

  @override
  double get maxExtent => _height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault, vertical: 8),
      child: ValueListenableBuilder<TextEditingValue>(
        valueListenable: searchController,
        builder: (context, value, child) {
          return SearchBar(
            controller: searchController,
            backgroundColor: WidgetStatePropertyAll(Theme.of(context).disabledColor.withValues(alpha: 0.1)),
            elevation: const WidgetStatePropertyAll(0),
            side: WidgetStatePropertyAll(BorderSide(color: Theme.of(context).hintColor.withValues(alpha: 0.3))),
            shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(Dimensions.radiusMedium))),
            onChanged: (v) {
              if (isMyCategory) {
                Get.find<CategoryController>().getMyCategoryList(search: v);
              } else {
                Get.find<CategoryController>().getCategoryList(isRestaurantWise: true, search: v);
              }
            },
            onSubmitted: (v) {
              if (isMyCategory) {
                Get.find<CategoryController>().getMyCategoryList(search: v);
              } else {
                Get.find<CategoryController>().getCategoryList(isRestaurantWise: true, search: v);
              }
            },
            hintText: 'search_by_category_name'.tr,
            hintStyle: WidgetStatePropertyAll(robotoRegular.copyWith(color: Theme.of(context).hintColor)),
            padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 16.0)),
            leading: Icon(CupertinoIcons.search, color: Theme.of(context).hintColor),
            trailing: value.text.isEmpty
                ? [const SizedBox()]
                : [InkWell(
                    child: Icon(Icons.clear, color: Theme.of(context).hintColor),
                    onTap: () {
                      searchController.clear();
                      if (isMyCategory) {
                        Get.find<CategoryController>().getMyCategoryList(search: '');
                      } else {
                        Get.find<CategoryController>().clearSearch();
                        Get.find<CategoryController>().update();
                      }
                    },
                  )],
          );
        },
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _SearchBarDelegate oldDelegate) =>
      oldDelegate.isMyCategory != isMyCategory;
}

class _ShimmerTabButtonDelegate extends SliverPersistentHeaderDelegate {
  static const double _height = 55.0;

  @override
  double get minExtent => _height;

  @override
  double get maxExtent => _height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
      child: Row(mainAxisAlignment: MainAxisAlignment.start, children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge),
          child: Shimmer(
            duration: const Duration(seconds: 1),
            interval: const Duration(seconds: 1),
            color: Theme.of(context).disabledColor.withValues(alpha: 0.15),
            colorOpacity: 0.1,
            enabled: true,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault, vertical: Dimensions.paddingSizeSmall),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Theme.of(context).disabledColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge),
              ),
              width: 120,
              height: 36,
            ),
          ),
        ),
        const SizedBox(width: Dimensions.paddingSizeSmall),
        ClipRRect(
          borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge),
          child: Shimmer(
            duration: const Duration(seconds: 1),
            interval: const Duration(seconds: 1),
            color: Theme.of(context).disabledColor.withValues(alpha: 0.15),
            colorOpacity: 0.1,
            enabled: true,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault, vertical: Dimensions.paddingSizeSmall),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Theme.of(context).disabledColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge),
              ),
              width: 120,
              height: 36,
            ),
          ),
        ),
      ]),
    );
  }

  @override
  bool shouldRebuild(covariant _ShimmerTabButtonDelegate oldDelegate) => true;
}

class _SplashAwareTabButtonDelegate extends SliverPersistentHeaderDelegate {
  final TabController tabController;
  final bool isMyCategory;
  final bool showMyCategory;

  _SplashAwareTabButtonDelegate({
    required this.tabController,
    required this.isMyCategory,
    required this.showMyCategory,
  });

  static const double _height = 55.0;

  @override
  double get minExtent => _height;

  @override
  double get maxExtent => _height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
      child: Row(mainAxisAlignment: MainAxisAlignment.start, children: [
        _TabButton(
          label: 'main_category'.tr,
          isSelected: !isMyCategory,
          onTap: () => tabController.animateTo(0),
        ),
        if(showMyCategory) ...[
          const SizedBox(width: Dimensions.paddingSizeSmall),
          _TabButton(
            label: 'my_category'.tr,
            isSelected: isMyCategory,
            onTap: () => tabController.animateTo(1),
          ),
        ]
      ]),
    );
  }

  @override
  bool shouldRebuild(covariant _SplashAwareTabButtonDelegate oldDelegate) => true;
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TabButton({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault, vertical: Dimensions.paddingSizeSmall),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).primaryColor : Theme.of(context).disabledColor.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge),
        ),
        child: Text(
          label,
          style: isSelected ? robotoMedium.copyWith(color: Theme.of(context).cardColor, fontSize: Dimensions.fontSizeSmall) 
          : robotoRegular.copyWith( fontSize: Dimensions.fontSizeSmall),
        ),
      ),
    );
  }
}

class _MainCategoryTab extends StatelessWidget {
  final TextEditingController searchController;

  const _MainCategoryTab({required this.searchController});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<CategoryController>(builder: (categoryController) {

      List<CategoryModel>? categories;
      if (categoryController.categoryList != null) {
        categories = [...categoryController.categoryList!];
      }

      return RefreshIndicator(
        onRefresh: () async {
          await categoryController.getCategoryList(isRestaurantWise: true, search: searchController.text);
        },
        child: categories != null
            ? categories.isNotEmpty
                ? ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeDefault),
                        child: InkWell(
                          onTap: () {
                            Get.to(() => CategoryProductScreen(
                              categoryId: categories![index].id!,
                              categoryName: categories[index].name ?? '',
                            ));
                          },
                          child: Container(
                            padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                              boxShadow: const [BoxShadow(color: Colors.black12, spreadRadius: 0, blurRadius: 5)],
                            ),
                            child: Row(children: [

                              ClipRRect(
                                borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                                child: CustomImageWidget(
                                  image: '${categories![index].imageFullUrl}',
                                  height: 60, width: 65, fit: BoxFit.cover,
                                ),
                              ),
                              const SizedBox(width: Dimensions.paddingSizeSmall),

                              Expanded(
                                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text(categories[index].name?.trim() ?? '', style: robotoMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                                  const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                                  Text(
                                    (categories[index].childesCount ?? 0) > 0
                                        ? '${categories[index].childesCount} ${'sub_category'.tr}'
                                        : 'no_sub_category'.tr,
                                    style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).hintColor),
                                  ),
                                ]),
                              ),
                              const SizedBox(width: Dimensions.paddingSizeSmall),

                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall, vertical: Dimensions.paddingSizeExtraSmall),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(Dimensions.radiusMedium),
                                ),
                                child: Text(
                                  (categories[index].productsCount ?? 0) > 0
                                      ? '${categories[index].productsCount} ${'items'.tr}'
                                      : 'no_item_available'.tr,
                                  style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall),
                                ),
                              ),

                            ]),
                          ),
                        ),
                      );
                    },
                  )
                : Center(child: Text('no_category_found'.tr))
            : const Center(child: CircularProgressIndicator()),
      );
    });
  }
}

class _MyCategoryTab extends StatelessWidget {
  const _MyCategoryTab({required this.searchController});
  final TextEditingController searchController;

  @override
  Widget build(BuildContext context) {
    return GetBuilder<CategoryController>(builder: (controller) {

      if (controller.myCategories == null) {
        return const Center(child: CircularProgressIndicator());
      }

      final items = controller.myCategories!;

      return RefreshIndicator(
        onRefresh: () => controller.getMyCategoryList(search: searchController.text),
        child: items.isNotEmpty ? ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
            itemCount: items.length + 2,
            itemBuilder: (context, index) {
              if (index == 0) {
                return const _CategoryInfoBanner();
              }
              if (index == 1) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeDefault),
                  child: Text('available_category'.tr, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge)),
                );
              }
              return Padding(
                padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeDefault),
                child: _MyCategoryItem(category: items[index - 2], controller: controller),
              );
            },
          ) : ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              const _CategoryInfoBanner(),
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.4,
                child: Center(child: Text('no_category_found'.tr)),
              ),
            ],
          ),
      );
    });
  }
}

class _CategoryInfoBanner extends StatelessWidget {
  const _CategoryInfoBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: Dimensions.paddingSizeDefault),
      padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E7),
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
        border: Border.all(color: const Color(0xFFFFE082), width: 1),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          height: 28, width: 28,
          decoration: const BoxDecoration(color: Color(0xFFFFA726), shape: BoxShape.circle),
          child: const Icon(Icons.info_outline, color: Colors.white, size: 18),
        ),
        const SizedBox(width: Dimensions.paddingSizeSmall),
        Expanded(
          child: Text(
            'my_category_list_note'.tr,
            style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: const Color(0xFF7A5C00)),
          ),
        ),
      ]),
    );
  }
}

class _MyCategoryItem extends StatelessWidget {
  final CategoryModel category;
  final CategoryController controller;
  const _MyCategoryItem({required this.category, required this.controller});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
      onTap: () => Get.to(() => MyCategoryProductScreen(
        categoryId: category.id!,
        categoryName: category.name ?? '',
      )),
      child: Container(
        padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
          boxShadow: const [BoxShadow(color: Colors.black12, spreadRadius: 0, blurRadius: 5)],
        ),
        child: Row(children: [

          ClipRRect(
            borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
            child: CustomImageWidget(
              image: category.imageFullUrl ?? "",
              height: 60, width: 65, fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: Dimensions.paddingSizeSmall),

          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(category.name ?? '', style: robotoMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),

              Row(children: [
                Text(
                  'ID #${category.id}',
                  style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).hintColor),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeExtraSmall),
                  child: Text('|', style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).hintColor)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall, vertical: 2),
                  decoration: BoxDecoration(
                    color: Theme.of(context).disabledColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                  ),
                  child: Text(
                    '${category.productsCount ?? 0} ${'items'.tr}',
                    style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).hintColor),
                  ),
                ),
              ]),
            ]),
          ),

          Container(
            height: 40, width: 40,
            decoration: BoxDecoration(
              color: Theme.of(context).disabledColor.withAlpha(30),
              borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
            ),
            child: PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, color: Theme.of(context).primaryColor),
              iconSize: 24,
              padding: EdgeInsets.zero,
              menuPadding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Dimensions.radiusDefault)),
              onSelected: (value) {
                if (value == 'edit') {
                  Get.to(() => AddMyCategoryScreen(category: category));
                } else if (value == 'delete') {
                  _confirmDelete(context, controller);
                } else if (value == 'assign_item') {
                  AssignMyCategoryScreen.show(
                    categoryId: category.id!,
                    categoryName: category.name ?? '',
                  );
                }
              },
              itemBuilder: (popupContext) => [
                PopupMenuItem(
                  enabled: false,
                  padding: EdgeInsets.zero,
                  child: Row(children: [
                    Padding(
                      padding: const EdgeInsets.only(left: Dimensions.paddingSizeDefault),
                      child: Text('status'.tr, style: robotoMedium.copyWith(color: Theme.of(context).textTheme.bodyLarge?.color)),
                    ),
                    const Spacer(),
                    Transform.scale(
                      scale: 0.75,
                      child: Switch(
                        value: (category.status ?? 0) == 1,
                        activeThumbColor: Theme.of(context).primaryColor,
                        onChanged: (_) {
                          controller.toggleCategoryStatus(category.id!, category.status ?? 0);
                          Navigator.pop(popupContext);
                        },
                      ),
                    ),
                  ]),
                ),
                PopupMenuItem(
                  value: 'edit',
                  child: Row(children: [
                    Text('edit'.tr, style: robotoMedium),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
                      child: const Icon(Icons.edit, color: Colors.white, size: 16),
                    ),
                  ]),
                ),
                PopupMenuItem(
                  value: 'assign_item',
                  child: Row(children: [
                    Text('assign_item'.tr, style: robotoMedium),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(color: Colors.deepOrangeAccent, shape: BoxShape.circle),
                      child: const Icon(Icons.add_circle_outline, color: Colors.white, size: 16),
                    ),
                  ]),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(children: [
                    Text('delete'.tr, style: robotoMedium),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                      child: const Icon(Icons.delete, color: Colors.white, size: 16),
                    ),
                  ]),
                ),
              ],
            ),
          ),

        ]),
      ),
    );
  }

  void _confirmDelete(BuildContext context, CategoryController controller) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Dimensions.radiusDefault)),
        title: Text('delete'.tr, style: robotoBold),
        content: Text('are_you_sure_to_delete'.tr, style: robotoRegular),
        actions: [
          TextButton(onPressed: () => Get.back(), child: Text('cancel'.tr)),
          TextButton(
            onPressed: () {
              Get.back();
              controller.deleteMyCategory(category.id!);
            },
            child: Text('delete'.tr, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _ShimmerCategoryCard extends StatelessWidget {
  const _ShimmerCategoryCard();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
      itemCount: 7,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeDefault),
          child: Shimmer(
            duration: const Duration(seconds: 1),
            interval: const Duration(seconds: 1),
            color: Theme.of(context).disabledColor.withValues(alpha: 0.06),
            colorOpacity: 0.1,
            enabled: true,
            child: Container(
              padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
              decoration: BoxDecoration(
                color: Theme.of(context).disabledColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
              ),
              child: Row(children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                  child: Container(
                    height: 60,
                    width: 65,
                    color: Theme.of(context).disabledColor.withValues(alpha: 0.1),
                  ),
                ),
                const SizedBox(width: Dimensions.paddingSizeSmall),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Container(
                      height: 16,
                      width: double.infinity,
                      color: Theme.of(context).disabledColor.withValues(alpha: 0.1),
                    ),
                    const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                    Container(
                      height: 14,
                      width: 150,
                      color: Theme.of(context).disabledColor.withValues(alpha: 0.1),
                    ),
                  ]),
                ),
                const SizedBox(width: Dimensions.paddingSizeSmall),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall, vertical: Dimensions.paddingSizeExtraSmall),
                  decoration: BoxDecoration(
                    color: Theme.of(context).disabledColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(Dimensions.radiusMedium),
                  ),
                  child: Container(
                    height: 12,
                    width: 60,
                    color: Theme.of(context).disabledColor.withValues(alpha: 0.2),
                  ),
                ),
              ]),
            ),
          ),
        );
      },
    );
  }
}
