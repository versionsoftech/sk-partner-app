import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart_store/common/widgets/custom_button_widget.dart';
import 'package:sixam_mart_store/common/widgets/custom_image_widget.dart';
import 'package:sixam_mart_store/common/widgets/custom_snackbar_widget.dart';
import 'package:sixam_mart_store/features/category/controllers/category_controller.dart';
import 'package:sixam_mart_store/features/category/domain/models/assignable_food_model.dart';
import 'package:sixam_mart_store/helper/price_converter_helper.dart';
import 'package:sixam_mart_store/util/dimensions.dart';
import 'package:sixam_mart_store/util/styles.dart';

class AssignMyCategoryScreen extends StatefulWidget {
  final int categoryId;
  final String categoryName;
  const AssignMyCategoryScreen({super.key, required this.categoryId, required this.categoryName});

  static Future<T?> show<T>({required int categoryId, required String categoryName}) {
    return Get.bottomSheet<T>(
      AssignMyCategoryScreen(categoryId: categoryId, categoryName: categoryName),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  @override
  State<AssignMyCategoryScreen> createState() => _AssignMyCategoryScreenState();
}

class _AssignMyCategoryScreenState extends State<AssignMyCategoryScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final List<int> _selectedIds = [];
  Timer? _searchDebounce;
  String _lastSearchText = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.find<CategoryController>().getAssignableFoods(offset: '1', categoryId: widget.categoryId, search: _lastSearchText);

      _scrollController.addListener(() {
        final ctrl = Get.find<CategoryController>();
        if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent
            && ctrl.assignableFoodList != null
            && !ctrl.isAssignableFoodLoading) {
          final int pageSize = (ctrl.assignableFoodPageSize! / 25).ceil();
          if (ctrl.assignableFoodOffset < pageSize) {
            ctrl.setAssignableFoodOffset(ctrl.assignableFoodOffset + 1);
            ctrl.showAssignableFoodBottomLoader();
            ctrl.getAssignableFoods(offset: ctrl.assignableFoodOffset.toString(), categoryId: widget.categoryId, search: _lastSearchText);
          }
        }
      });
    });

    _initializeAssignedItems();
  }

  void _initializeAssignedItems() {
    final ctrl = Get.find<CategoryController>();
    if (ctrl.assignableFoodList != null) {
      for (final food in ctrl.assignableFoodList!) {
        if (food.isAssigned == true && !_selectedIds.contains(food.id)) {
          _selectedIds.add(food.id!);
        }
      }
    }
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _searchItem(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
      final String search = value.trim();
      if (_lastSearchText == search) return;
      _lastSearchText = search;
      Get.find<CategoryController>().getAssignableFoods(offset: '1', categoryId: widget.categoryId, search: search);
    });
  }

  void _toggleSelection(int id) {
    final ctrl = Get.find<CategoryController>();
    final food = ctrl.assignableFoodList?.firstWhere((f) => f.id == id, orElse: () => AssignableFood());

    if (food?.isAssigned == true) {
      return;
    }

    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _reset() {
    setState(() => _selectedIds.clear());
  }

  Future<void> _save() async {
    if (_selectedIds.isEmpty) {
      showCustomSnackBar('please_select_item'.tr, isError: true);
      return;
    }
    final bool success = await Get.find<CategoryController>().assignFoodsToCategory(widget.categoryId, _selectedIds);
    if (success) {
      Get.find<CategoryController>().getMyCategoryList();
      Get.until((route) => route.isFirst || route.settings.name == '/categories');
      showCustomSnackBar('category_updated_successfully'.tr, isError: false);
    } else {
      showCustomSnackBar('failed_to_assign_items'.tr, isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<CategoryController>(builder: (ctrl) {
        final List<AssignableFood>? foods = ctrl.assignableFoodList;
        if (foods == null) {
          return const Center(child: CircularProgressIndicator());
        }

        return AnimatedPadding(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.92,
            ),
            child: Material(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(Dimensions.radiusExtraLarge)),
              clipBehavior: Clip.antiAlias,
              child: Column(children: [
        
                _BottomSheetHeader(title: widget.categoryName),
        
                Expanded(
                  child: CustomScrollView(
                    controller: _scrollController,
                    slivers: [
      
                      SliverToBoxAdapter(
                        child: _TopMessagesSection(
                          unassignedCount: ctrl.assignableUnassignedCount ?? 0, uncategorised: foods,
                        ),
                      ),
      
                     foods.isEmpty ? SliverToBoxAdapter(child: SizedBox.shrink()) : SliverPersistentHeader(
                        pinned: true,
                        delegate: _SearchHeaderDelegate(
                          child: _SearchAndListHeader(
                            controller: _searchController,
                            selectedCount: _selectedIds.length,
                            onChanged: _searchItem,
                          ),
                        ),
                      ),
      
                      foods.isEmpty ? SliverFillRemaining(
                        hasScrollBody: false,
                        child: Padding(
                          padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.inventory_2_outlined, size: 56, color: Theme.of(context).disabledColor.withValues(alpha: 0.4)),
                              const SizedBox(height: Dimensions.paddingSizeDefault),
                              Text(
                                'all_items_assigned_title'.tr,
                                textAlign: TextAlign.center,
                                style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeDefault, color: Theme.of(context).hintColor),
                              ),
                              const SizedBox(height: Dimensions.paddingSizeSmall),
                              Text(
                                'all_items_assigned_subtitle'.tr,
                                textAlign: TextAlign.center,
                                style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).disabledColor),
                              ),
                            ],
                          ),
                        ),
                      ) : SliverPadding(
                        padding: const EdgeInsets.fromLTRB(Dimensions.paddingSizeDefault, Dimensions.paddingSizeSmall, Dimensions.paddingSizeDefault, Dimensions.paddingSizeDefault),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              if (index == foods.length) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall),
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
                                    ),
                                  ),
                                );
                              }
      
                              final food = foods[index];
                              final bool userSelected = _selectedIds.contains(food.id);
                              final bool alreadyAssigned = food.isAssigned == true;
      
                              return Padding(
                                padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
                                child: _AssignItemCard(
                                  food: food,
                                  alreadyAssigned: alreadyAssigned,
                                  userSelected: userSelected,
                                  onTap: alreadyAssigned ? null : () => _toggleSelection(food.id!),
                                ),
                              );
                            },
                            childCount: foods.length + (ctrl.isAssignableFoodLoading ? 1 : 0),
                          ),
                        ),
                      ),
      
                    ],
                  )
                ),
        
                foods.isEmpty ? SizedBox.shrink() : GetBuilder<CategoryController>(
                  builder: (ctrl) => _BottomActionBar(
                    onReset: _reset,
                    onSave: _save,
                    isSaveLoading: ctrl.isAssignSubmitLoading,
                  ),
                ),
        
              ]),
            ),
          ),
        );
      }
    );
  }
}

class _BottomSheetHeader extends StatelessWidget {
  final String title;
  const _BottomSheetHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(Dimensions.paddingSizeDefault, Dimensions.paddingSizeSmall, Dimensions.paddingSizeDefault, 0),
        child: Column(children: [

          Container(
            height: 5,
            width: 48,
            decoration: BoxDecoration(
              color: Theme.of(context).disabledColor.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
            ),
          ),
          const SizedBox(height: Dimensions.paddingSizeSmall),

          Row(children: [

            const SizedBox(width: 40),

            Expanded(
              child: Text(
                title,
                style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            InkWell(
              onTap: () => Get.back(),
              borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
              child: Padding(
                padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                child: Icon(Icons.close, color: Theme.of(context).hintColor),
              ),
            ),

          ]),

          Text(
            'assign_unassigned_items'.tr,
            style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeDefault, color: Theme.of(context).hintColor),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),

        ]),
      ),
    );
  }
}

class _TopMessagesSection extends StatelessWidget {
  final int unassignedCount;
  final List<AssignableFood> uncategorised;
  const _TopMessagesSection({required this.unassignedCount, required this.uncategorised});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(Dimensions.paddingSizeDefault, Dimensions.paddingSizeDefault, Dimensions.paddingSizeDefault, 0),
      child: Column(children: [

        _MessageCard(
          icon: Icons.info,
          iconColor: const Color(0xFFFFB233),
          backgroundColor: const Color(0xFFFFF7E8),
          child: Text(
            'assign_category_note'.tr,
            style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeDefault, height: 1.5, color: Theme.of(context).textTheme.bodyLarge!.color),
          ),
        ),
        const SizedBox(height: Dimensions.paddingSizeDefault),
        if (uncategorised.isNotEmpty && unassignedCount > 0) _MessageCard(
          icon: Icons.warning_rounded,
          iconColor: const Color(0xFFFF4D4F),
          backgroundColor: const Color(0xFFFFE8E8),
          child: RichText(
            text: TextSpan(
              style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeDefault, height: 1.5, color: Theme.of(context).textTheme.bodyLarge!.color),
              children: [
                TextSpan(text: '${'there_are'.tr} '),
                TextSpan(text: '$unassignedCount ${'items'.tr.toLowerCase()}', style: robotoBold.copyWith(fontSize: Dimensions.fontSizeDefault, color: Theme.of(context).textTheme.bodyLarge!.color)),
                TextSpan(text: ' ${'unassigned_items_message'.tr}'),
              ],
            ),
          ),
        ),

      ]),
    );
  }
}

class _MessageCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;
  final Widget child;
  const _MessageCard({required this.icon, required this.iconColor, required this.backgroundColor, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [

        Icon(icon, color: iconColor, size: 22),
        const SizedBox(width: Dimensions.paddingSizeSmall),

        Expanded(child: child),

      ]),
    );
  }
}

class _SearchHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  const _SearchHeaderDelegate({required this.child});

  @override
  double get minExtent => 118;

  @override
  double get maxExtent => 118;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: child,
    );
  }

  @override
  bool shouldRebuild(covariant _SearchHeaderDelegate oldDelegate) {
    return child != oldDelegate.child;
  }
}

class _SearchAndListHeader extends StatelessWidget {
  final TextEditingController controller;
  final int selectedCount;
  final ValueChanged<String> onChanged;
  const _SearchAndListHeader({required this.controller, required this.selectedCount, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(Dimensions.paddingSizeDefault, Dimensions.paddingSizeSmall, Dimensions.paddingSizeDefault, 0),
      child: Column(children: [

        TextField(
          controller: controller,
          onChanged: onChanged,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: 'search_by_item_name'.tr,
            hintStyle: robotoRegular.copyWith(color: Theme.of(context).hintColor),
            prefixIcon: Icon(Icons.search, color: Theme.of(context).hintColor),
            contentPadding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault, vertical: 14),
            filled: true,
            fillColor: Theme.of(context).cardColor,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide(color: Theme.of(context).disabledColor.withValues(alpha: 0.25)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide(color: Theme.of(context).primaryColor),
            ),
          ),
        ),
        const SizedBox(height: Dimensions.paddingSizeDefault),

        Row(children: [

          Expanded(child: Text('item_list'.tr, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge))),

          Text('$selectedCount ${'selected'.tr}', style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeDefault, color: Theme.of(context).textTheme.bodyLarge!.color)),

        ]),

      ]),
    );
  }
}

class _AssignItemCard extends StatelessWidget {
  final AssignableFood food;
  final bool alreadyAssigned;
  final bool userSelected;
  final VoidCallback? onTap;
  const _AssignItemCard({
    required this.food,
    required this.alreadyAssigned,
    required this.userSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = Theme.of(context).primaryColor;
    final Color disabledColor = Theme.of(context).disabledColor;

    Color cardColor;
    Color borderColor;
    List<BoxShadow>? shadow;
    IconData checkIcon;
    Color checkColor;

    if (alreadyAssigned) {
      cardColor = Theme.of(context).disabledColor.withValues(alpha: 0.07);
      borderColor = disabledColor.withValues(alpha: 0.2);
      shadow = null;
      checkIcon = Icons.check_box;
      checkColor = disabledColor;
    } else if (userSelected) {
      cardColor = Theme.of(context).cardColor;
      borderColor = disabledColor.withValues(alpha: 0.16);
      shadow = const [BoxShadow(color: Colors.black12, blurRadius: 6, spreadRadius: 0)];
      checkIcon = Icons.check_box;
      checkColor = primaryColor;
    } else {
      cardColor = Theme.of(context).cardColor;
      borderColor = disabledColor.withValues(alpha: 0.16);
      shadow = const [BoxShadow(color: Colors.black12, blurRadius: 6, spreadRadius: 0)];
      checkIcon = Icons.check_box_outline_blank;
      checkColor = disabledColor;
    }

    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor: alreadyAssigned ? SystemMouseCursors.forbidden : SystemMouseCursors.click,
        child: Container(
          padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
            border: Border.all(color: borderColor),
            boxShadow: shadow,
          ),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [

          Opacity(
            opacity: alreadyAssigned ? 0.45 : 1.0,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(Dimensions.radiusMedium),
              child: food.imageFullUrl != null
                  ? CustomImageWidget(image: food.imageFullUrl!, height: 70, width: 70, fit: BoxFit.cover)
                  : Container(
                      height: 70, width: 70,
                      decoration: BoxDecoration(
                        color: disabledColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(Dimensions.radiusMedium),
                      ),
                      child: Icon(Icons.shopping_bag_outlined, color: disabledColor),
                    ),
            ),
          ),
          const SizedBox(width: Dimensions.paddingSizeSmall),

          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

              Text(
                'ID #${food.id}',
                style: robotoRegular.copyWith(
                  fontSize: Dimensions.fontSizeSmall,
                  color: alreadyAssigned ? disabledColor : Theme.of(context).hintColor,
                ),
              ),
              const SizedBox(height: 2),

              Text(
                food.name ?? '',
                style: robotoBold.copyWith(
                  fontSize: Dimensions.fontSizeDefault,
                  color: alreadyAssigned ? disabledColor : null,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),

              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: RichText(
                  maxLines: 1,
                  text: TextSpan(
                    children:[
                      TextSpan(
                      text: '${'price'.tr} : ${PriceConverterHelper.convertPrice(food.price)}',
                      style: robotoRegular.copyWith(
                        fontSize: Dimensions.fontSizeDefault,
                        color: alreadyAssigned ? disabledColor : Theme.of(context).hintColor,
                      )),
                      food.variationsCount! > 0 ? TextSpan(
                        text: ' |  ${'variation'.tr} : ${food.variationsCount}',
                        style: robotoRegular.copyWith(
                          fontSize: Dimensions.fontSizeDefault,
                          color: alreadyAssigned ? disabledColor : Theme.of(context).hintColor,
                        )) : const TextSpan(),
                    ],
                  ),
                ),
              ),

            ]),
          ),

          Icon(checkIcon, color: checkColor, size: 26),

        ]),
        ),
      ),
    );
  }
}

class _BottomActionBar extends StatelessWidget {
  final VoidCallback onReset;
  final VoidCallback onSave;
  final bool isSaveLoading;
  const _BottomActionBar({required this.onReset, required this.onSave, required this.isSaveLoading});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        Dimensions.paddingSizeDefault,
        Dimensions.paddingSizeSmall,
        Dimensions.paddingSizeDefault,
        MediaQuery.of(context).padding.bottom + Dimensions.paddingSizeSmall,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, -2))],
      ),
      child: Row(children: [

        Expanded(
          child: CustomButtonWidget(
            buttonText: 'reset'.tr,
            transparent: true,
            isBorder: true,
            height: 50,
            onPressed: onReset,
          ),
        ),
        const SizedBox(width: Dimensions.paddingSizeDefault),

        Expanded(
          child: CustomButtonWidget(
            buttonText: 'save'.tr,
            height: 50,
            isLoading: isSaveLoading,
            onPressed: isSaveLoading ? null : onSave,
          ),
        ),

      ]),
    );
  }
}
