import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart_store/common/widgets/confirmation_dialog_widget.dart';
import 'package:sixam_mart_store/common/widgets/custom_app_bar_widget.dart';
import 'package:sixam_mart_store/common/widgets/custom_image_widget.dart';
import 'package:sixam_mart_store/common/widgets/custom_snackbar_widget.dart';
import 'package:sixam_mart_store/features/chat/widgets/search_field_widget.dart';
import 'package:sixam_mart_store/features/order/domain/models/order_details_model.dart';
import 'package:sixam_mart_store/features/order_edit/controllers/order_edit_controller.dart';
import 'package:sixam_mart_store/features/order_edit/widgets/item_details_bottom_sheet_widget.dart';
import 'package:sixam_mart_store/features/order_edit/widgets/quantity_button_widget.dart';
import 'package:sixam_mart_store/features/profile/controllers/profile_controller.dart';
import 'package:sixam_mart_store/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart_store/features/store/controllers/store_controller.dart';
import 'package:sixam_mart_store/features/store/domain/models/item_model.dart';
import 'package:sixam_mart_store/helper/price_converter_helper.dart';
import 'package:sixam_mart_store/util/dimensions.dart';
import 'package:sixam_mart_store/util/images.dart';
import 'package:sixam_mart_store/util/styles.dart';

class AddNewItemsScreen extends StatefulWidget {
  const AddNewItemsScreen({super.key});

  @override
  State<AddNewItemsScreen> createState() => _AddNewItemsScreenState();
}

class _AddNewItemsScreenState extends State<AddNewItemsScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final StoreController storeController = Get.find<StoreController>();
    storeController.getItemList(offset: '1', type: 'all', search: '', categoryId: 0, willUpdate: false);
    storeController.getStoreCategories(isUpdate: false);

    _scrollController.addListener(() {
      if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent
          && storeController.itemList != null && !storeController.isLoading) {
        int pageSize = (storeController.itemSize! / 10).ceil();
        if (storeController.offset < pageSize) {
          storeController.setOffset(storeController.offset + 1);
          storeController.showBottomLoader();
          storeController.getItemList(
            offset: storeController.offset.toString(), type: storeController.type,
            search: _searchController.text, categoryId: storeController.categoryId,
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) Get.find<StoreController>().resetFilters();
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).cardColor,
        appBar: CustomAppBarWidget(title: 'add_new_items'.tr),
        body: SafeArea(child: GetBuilder<StoreController>(builder: (storeController) {
          return Column(children: [

            /// search
            Padding(
              padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
              child: SizedBox(height: 50, child: SearchFieldWidget(
                fromReview: true,
                controller: _searchController,
                hint: '${'search_by_item_name'.tr}...',
                suffixIcon: storeController.isSearching ? CupertinoIcons.clear_thick : CupertinoIcons.search,
                iconPressed: () {
                  if (storeController.isSearching) {
                    _searchController.clear();
                    storeController.setCategoryForSearch(index: 0);
                    storeController.getItemList(offset: '1', type: 'all', search: '', categoryId: 0);
                  } else {
                    _onSearch(storeController);
                  }
                },
                onSubmit: (_) => _onSearch(storeController),
              )),
            ),

            /// categories
            if (storeController.categoryNameList != null)
              SizedBox(height: 40, child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
                itemCount: storeController.categoryNameList!.length,
                itemBuilder: (context, index) {
                  return InkWell(
                    onTap: () {
                      _searchController.clear();
                      storeController.setCategory(index: index, foodType: 'all');
                    },
                    splashColor: Colors.transparent, highlightColor: Colors.transparent,
                    child: Container(
                      margin: const EdgeInsets.only(right: Dimensions.paddingSizeSmall),
                      padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault, vertical: Dimensions.paddingSizeExtraSmall),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge),
                        color: index == storeController.categoryIndex ? Theme.of(context).primaryColor : Theme.of(context).hintColor.withValues(alpha: 0.1),
                      ),
                      child: Text(
                        index == 0 ? 'all'.tr : storeController.categoryNameList![index],
                        style: robotoRegular.copyWith(
                          fontSize: Dimensions.fontSizeSmall,
                          color: index == storeController.categoryIndex ? Theme.of(context).cardColor : Theme.of(context).textTheme.bodyLarge?.color,
                          fontWeight: index == storeController.categoryIndex ? FontWeight.w700 : FontWeight.w400,
                        ),
                      ),
                    ),
                  );
                },
              )),
            const SizedBox(height: Dimensions.paddingSizeDefault),

            /// items
            Expanded(child: storeController.itemList == null
                ? Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor)))
                : storeController.itemList!.isEmpty
                  ? Center(child: Text('no_item_available'.tr, style: robotoMedium))
                  : SingleChildScrollView(
                    controller: _scrollController,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
                    child: Column(children: [
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: storeController.itemList!.length,
                        separatorBuilder: (_, _) => const SizedBox(height: Dimensions.paddingSizeSmall),
                        itemBuilder: (context, index) => _buildItemCard(context, storeController.itemList![index]),
                      ),
                      if (storeController.isLoading) Padding(
                        padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                        child: Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor))),
                      ),
                      const SizedBox(height: Dimensions.paddingSizeSmall),
                    ]),
                  ),
            ),
          ]);
        })),
      ),
    );
  }

  Widget _buildItemCard(BuildContext context, Item item) {
    double originalPrice = item.price ?? 0;
    double discountAmount = 0;
    if (item.discount != null && item.discount! > 0) {
      if (item.discountType == 'percent') {
        discountAmount = (originalPrice * item.discount!) / 100;
      } else {
        discountAmount = item.discount!;
      }
    }
    double finalPrice = originalPrice - discountAmount;

    return InkWell(
      /// tap anywhere on the card to view item details
      onTap: () => _openItemSheet(item),
      child: Container(
        padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
          boxShadow: [BoxShadow(offset: const Offset(0, 3), color: Colors.grey[Get.isDarkMode ? 700 : 200]!, blurRadius: 8)],
        ),
        child: Row(children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
            child: CustomImageWidget(image: item.imageFullUrl ?? '', height: 60, width: 60, fit: BoxFit.cover),
          ),
          const SizedBox(width: Dimensions.paddingSizeSmall),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Wrap(crossAxisAlignment: WrapCrossAlignment.center, children: [
              Text(
                item.name ?? '', textAlign: TextAlign.start,
                style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall),
                maxLines: 1, overflow: TextOverflow.ellipsis,
              ),
              SizedBox(width: Dimensions.paddingSizeExtraSmall),
              item.veg == 1 ? Image.asset(Images.vegIcon, width: 12) : item.veg == 0 ? Image.asset(Images.nonVegIcon, width: 12) : SizedBox.shrink(),
              SizedBox(width: item.imageFullUrl == null ? Dimensions.paddingSizeExtraSmall : 0),

              item.imageFullUrl == null ? item.discount! > 0 ? Text(
                '(${item.discount! > 0 ? '${item.discount}${item.discountType == 'percent' ? '%' : Get.find<SplashController>().configModel!.currencySymbol} ${'off'.tr}' : 'free_delivery'.tr})',
                style: robotoMedium.copyWith(color: Colors.green, fontSize: Dimensions.fontSizeExtraSmall),
              ) : const SizedBox() : const SizedBox(),
            ]),
            const SizedBox(height: Dimensions.paddingSizeExtraSmall),
            Row(children: [
              if (discountAmount > 0)
                Padding(
                  padding: const EdgeInsets.only(right: Dimensions.paddingSizeExtraSmall),
                  child: Text(
                    PriceConverterHelper.convertPrice(originalPrice),
                    style: robotoRegular.copyWith(
                      fontSize: Dimensions.fontSizeSmall,
                      color: Theme.of(context).hintColor,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                ),
              Text(PriceConverterHelper.convertPrice(finalPrice), style: robotoMedium.copyWith(color: Theme.of(context).primaryColor)),
            ]),
            const SizedBox(height: Dimensions.paddingSizeExtraSmall),
            Text('Stock: ${item.stock ?? 0}', style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).hintColor)),
          ])),
          const SizedBox(width: Dimensions.paddingSizeSmall),
          _buildTrailing(context, item),
        ]),
      ),
    );
  }

  /// Shows quantity controls (like the edit-order screen) when the item is already
  /// in the order, otherwise the add icon.
  Widget _buildTrailing(BuildContext context, Item item) {
    return GetBuilder<OrderEditController>(builder: (orderEditController) {
      final List<OrderDetailsModel> list = orderEditController.editOrderItemList ?? [];
      int cartIndex = -1;
      for (int i = 0; i < list.length; i++) {
        if (list[i].itemId == item.id) { cartIndex = i; break; }
      }
      final int cartQty = cartIndex != -1 ? (list[cartIndex].quantity ?? 0) : 0;

      if (cartQty > 0) {
        return Row(mainAxisSize: MainAxisSize.min, children: [
          QuantityButton(
            isIncrement: false,
            showRemoveIcon: cartQty == 1,
            onTap: () {
              if (cartQty > 1) {
                orderEditController.decreaseEditItemQuantity(cartIndex);
              } else if (list.length <= 1) {
                /// an order must always contain at least one item
                showCustomSnackBar('order_must_contain_at_least_one_item'.tr);
              } else {
                _showDeleteDialog(orderEditController, cartIndex);
              }
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeExtraSmall),
            child: Text('$cartQty', style: robotoMedium),
          ),
          QuantityButton(
            isIncrement: true,
            onTap: () => orderEditController.increaseEditItemQuantity(cartIndex),
          ),
        ]);
      }

      return InkWell(
        /// add icon: show details when the item has variations, otherwise add directly
        onTap: () => _onAddPressed(item),
        child: Container(
          height: 32, width: 32, alignment: Alignment.center,
          decoration: BoxDecoration(shape: BoxShape.circle, color: Theme.of(context).primaryColor),
          child: const Icon(Icons.add, color: Colors.white, size: 20),
        ),
      );
    });
  }

  void _showDeleteDialog(OrderEditController orderEditController, int cartIndex) {
    final module = Get.find<ProfileController>().profileModel?.stores?.first.module?.moduleType;
    final String titleKey = module  != 'food' ? 'are_you_sure_to_delete_this_food' : 'are_you_sure_to_delete_this_item';

    Get.dialog(ConfirmationDialogWidget(
      icon: Images.deleteDialogIcon,
      title: titleKey.tr,
      description: 'if_once_you_delete_this_item_this_will_remove_from_item_list'.tr,
      onYesPressed: () {
        Get.back();
        orderEditController.removeEditOrderItem(cartIndex);
      },
    ));
  }

  void _onAddPressed(Item item) {
    if (_hasVariation(item)) {
      _openItemSheet(item);
    } else {
      Get.find<OrderEditController>().addItemDirectly(item);
    }
  }

  bool _hasVariation(Item item) {
    return (item.foodVariations != null && item.foodVariations!.isNotEmpty)
        || (item.variations != null && item.variations!.isNotEmpty)
        || (item.choiceOptions != null && item.choiceOptions!.isNotEmpty);
  }

  void _openItemSheet(Item item) {
    Get.bottomSheet(
      ItemDetailsBottomSheetWidget(item: item),
      isScrollControlled: true, backgroundColor: Colors.transparent,
    );
  }

  void _onSearch(StoreController storeController) {
    if (_searchController.text.trim().isNotEmpty) {
      storeController.setCategoryForSearch(index: 0);
      storeController.getItemList(offset: '1', type: 'all', search: _searchController.text.trim(), categoryId: 0);
    } else {
      storeController.setCategoryForSearch(index: 0);
      storeController.getItemList(offset: '1', type: 'all', search: '', categoryId: 0);
    }
  }
}
