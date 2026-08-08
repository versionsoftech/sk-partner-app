import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart_store/common/widgets/custom_button_widget.dart';
import 'package:sixam_mart_store/common/widgets/custom_image_widget.dart';
import 'package:sixam_mart_store/common/widgets/custom_snackbar_widget.dart';
import 'package:sixam_mart_store/features/order/domain/models/order_details_model.dart';
import 'package:sixam_mart_store/features/order_edit/controllers/order_edit_controller.dart';
import 'package:sixam_mart_store/features/store/domain/models/item_model.dart';
import 'package:sixam_mart_store/helper/price_converter_helper.dart';
import 'package:sixam_mart_store/util/dimensions.dart';
import 'package:sixam_mart_store/util/styles.dart';

/// Item details + variation / add-on selection sheet shown when adding a new item
/// to an order, or editing an item already in the order ([orderDetails] +
/// [editIndex] set). Supports both the new `foodVariations` system and the old
/// `variations`/choice-option system. Variation validation mirrors stackfood.
class ItemDetailsBottomSheetWidget extends StatefulWidget {
  final Item item;
  final OrderDetailsModel? orderDetails;
  final int? editIndex;
  const ItemDetailsBottomSheetWidget({super.key, required this.item, this.orderDetails, this.editIndex});

  @override
  State<ItemDetailsBottomSheetWidget> createState() => _ItemDetailsBottomSheetWidgetState();
}

class _ItemDetailsBottomSheetWidgetState extends State<ItemDetailsBottomSheetWidget> {
  late final bool _isNewVariation;
  late final List<FoodVariation> _foodVariations;
  late final List<List<bool>> _foodSelected;

  late final List<Variation> _variations;
  late final List<ChoiceOptions> _choiceOptions;
  late final List<int> _selectedChoiceIndex;
  int _selectedVariationIndex = 0;

  late final List<AddOns> _addOns;
  late final List<bool> _addOnSelected;
  late final List<int> _addOnQty;

  int _quantity = 1;

  /// In add mode, the index of an order line whose item + variation matches the
  /// current selection (so we update its quantity instead of adding a duplicate).
  int _matchedIndex = -1;

  @override
  void initState() {
    super.initState();
    _foodVariations = widget.item.foodVariations ?? [];
    _isNewVariation = _foodVariations.isNotEmpty;
    _foodSelected = _foodVariations.map((fv) => List<bool>.filled(fv.variationValues?.length ?? 0, false)).toList();

    _variations = widget.item.variations ?? [];
    _choiceOptions = widget.item.choiceOptions ?? [];
    _selectedChoiceIndex = List<int>.filled(_choiceOptions.length, 0);

    _addOns = widget.item.addOns ?? [];
    _addOnSelected = List<bool>.filled(_addOns.length, false);
    _addOnQty = List<int>.filled(_addOns.length, 1);

    if(widget.orderDetails != null) _prefillFromOrderItem(widget.orderDetails!);
    _updateMatch();
  }

  bool get _isEditMode => widget.editIndex != null;
  bool get _showUpdate => _isEditMode || _matchedIndex != -1;

  /// Pre-selects the variations / add-ons / quantity of an item already in the order.
  void _prefillFromOrderItem(OrderDetailsModel orderItem) {
    _quantity = orderItem.quantity ?? 1;

    if(_isNewVariation) {
      /// an existing item may store its selected values either as foodVariation
      /// (a line added in this edit session) or as a flat variation list of level
      /// names (a line loaded back from the order API) — handle both.
      final Set<String> selectedLevels = {};
      for(final fv in orderItem.foodVariation ?? []) {
        for(final v in fv.variationValues ?? []) {
          if(v.level != null) selectedLevels.add(v.level!);
        }
      }
      for(final v in orderItem.variation ?? []) {
        if(v.type != null) selectedLevels.add(v.type!);
      }
      for(int i = 0; i < _foodVariations.length; i++) {
        for(int j = 0; j < _foodSelected[i].length; j++) {
          final String? level = _foodVariations[i].variationValues?[j].level;
          _foodSelected[i][j] = level != null && selectedLevels.contains(level);
        }
      }
    } else {
      final Variation? selectedVar = (orderItem.variation != null && orderItem.variation!.isNotEmpty) ? orderItem.variation!.first : null;
      if(selectedVar != null) {
        if(_choiceOptions.isNotEmpty) {
          final List<String> parts = (selectedVar.type ?? '').split('-');
          for(int i = 0; i < _choiceOptions.length && i < parts.length; i++) {
            final int idx = (_choiceOptions[i].options ?? []).indexOf(parts[i]);
            if(idx >= 0) _selectedChoiceIndex[i] = idx;
          }
        } else if(_variations.isNotEmpty) {
          final int idx = _variations.indexWhere((v) => v.type == selectedVar.type);
          if(idx >= 0) _selectedVariationIndex = idx;
        }
      }
    }

    final List<AddOn> selectedAddOns = orderItem.addOns ?? [];
    for(int i = 0; i < _addOns.length; i++) {
      _addOnSelected[i] = false;
      _addOnQty[i] = 1;
      for(final sel in selectedAddOns) {
        if(sel.name == _addOns[i].name) {
          _addOnSelected[i] = true;
          _addOnQty[i] = sel.quantity ?? 1;
          break;
        }
      }
    }
  }

  /// Recomputes whether the current selection is exactly the same variation as an
  /// existing order line (add mode only). Only an exact match counts — selecting
  /// fewer or different values is treated as a new combination (Add). On an exact
  /// match the line's quantity is used; otherwise the quantity stays initial.
  void _updateMatch() {
    if(_isEditMode) return;
    final List<OrderDetailsModel> list = Get.find<OrderEditController>().editOrderItemList ?? [];
    final Set<String> current = _selectedVariationSet();
    int found = -1;
    if(current.isNotEmpty) {
      for(int i = 0; i < list.length; i++) {
        if(list[i].itemId != widget.item.id) continue;
        final Set<String> lineSet = _lineVariationSet(list[i]);
        if(lineSet.length == current.length && current.every(lineSet.contains)) {
          found = i;
          break;
        }
      }
    }
    if(found != _matchedIndex) {
      _matchedIndex = found;
      if(found != -1) {
        /// same variation already in the order — mirror its quantity / add-ons
        _prefillFromOrderItem(list[found]);
      } else {
        /// a different / partial selection — start a fresh quantity
        _quantity = 1;
      }
    }
  }

  /// Set of the currently selected variation values (by level / type name).
  Set<String> _selectedVariationSet() {
    Set<String> set = {};
    if(_isNewVariation) {
      for(int i = 0; i < _foodVariations.length; i++) {
        for(int j = 0; j < (_foodVariations[i].variationValues?.length ?? 0); j++) {
          if(_foodSelected[i][j]) set.add(_foodVariations[i].variationValues![j].level ?? '');
        }
      }
    } else {
      final Variation? matched = _getMatchedVariation();
      if(matched != null) set.add(matched.type ?? '');
    }
    return set;
  }

  /// Set of an order line's variation values (handles both representations).
  Set<String> _lineVariationSet(OrderDetailsModel line) {
    Set<String> set = {};
    for(final fv in line.foodVariation ?? []) {
      for(final v in fv.variationValues ?? []) {
        if(v.level != null) set.add(v.level!);
      }
    }
    for(final v in line.variation ?? []) {
      if(v.type != null) set.add(v.type!);
    }
    return set;
  }

  @override
  Widget build(BuildContext context) {
    final double basePrice = widget.item.price ?? 0;
    final double discountedBase = _getDiscountedBasePrice();

    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(Dimensions.radiusExtraLarge), topRight: Radius.circular(Dimensions.radiusExtraLarge)),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [

        Padding(
          padding: const EdgeInsets.only(top: Dimensions.paddingSizeSmall),
          child: Container(height: 4, width: 40, decoration: BoxDecoration(color: Theme.of(context).disabledColor.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(10))),
        ),

        Flexible(child: SingleChildScrollView(
          padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
          physics: const BouncingScrollPhysics(),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

            /// Header: image + name + rating + price
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                child: CustomImageWidget(image: widget.item.imageFullUrl ?? '', height: 80, width: 80, fit: BoxFit.cover),
              ),
              const SizedBox(width: Dimensions.paddingSizeSmall),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(widget.item.name ?? '', style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeLarge), maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: Dimensions.paddingSizeExtraSmall),

                if((widget.item.avgRating ?? 0) > 0) Row(children: [
                  Icon(Icons.star, size: 16, color: Theme.of(context).primaryColor),
                  const SizedBox(width: 2),
                  Text('${widget.item.avgRating!.toStringAsFixed(1)} (${widget.item.ratingCount ?? 0})', style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).hintColor)),
                ]),
                const SizedBox(height: Dimensions.paddingSizeExtraSmall),

                Wrap(crossAxisAlignment: WrapCrossAlignment.center, children: [
                  if(basePrice > discountedBase) ...[
                    Text(PriceConverterHelper.convertPrice(basePrice), style: robotoRegular.copyWith(color: Theme.of(context).hintColor, decoration: TextDecoration.lineThrough)),
                    const SizedBox(width: Dimensions.paddingSizeExtraSmall),
                  ],
                  Text(PriceConverterHelper.convertPrice(discountedBase), style: robotoBold.copyWith(color: Theme.of(context).primaryColor, fontSize: Dimensions.fontSizeLarge)),
                ]),
              ])),

              if(widget.item.veg != null) _vegBadge(context),
            ]),

            /// Description
            if(widget.item.description != null && widget.item.description!.isNotEmpty) ...[
              const SizedBox(height: Dimensions.paddingSizeDefault),
              Text('description'.tr, style: robotoMedium),
              const SizedBox(height: Dimensions.paddingSizeExtraSmall),
              Text(widget.item.description!, style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).hintColor)),
            ],

            /// Nutrition
            if(widget.item.nutrition != null && widget.item.nutrition!.isNotEmpty) ...[
              const SizedBox(height: Dimensions.paddingSizeDefault),
              Text('nutrition_details'.tr, style: robotoMedium),
              const SizedBox(height: Dimensions.paddingSizeExtraSmall),
              Text(widget.item.nutrition!.join(', '), style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).hintColor)),
            ],

            /// Allergies
            if(widget.item.allergies != null && widget.item.allergies!.isNotEmpty) ...[
              const SizedBox(height: Dimensions.paddingSizeDefault),
              Text('allergic_ingredients'.tr, style: robotoMedium),
              const SizedBox(height: Dimensions.paddingSizeExtraSmall),
              Text(widget.item.allergies!.join(', '), style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).hintColor)),
            ],

            /// Variations
            if(_isNewVariation) ..._buildFoodVariations(context)
            else ..._buildOldVariations(context),

            /// Add-ons
            if(_addOns.isNotEmpty) ..._buildAddOns(context),

          ]),
        )),

        /// Footer: total + quantity + add to cart
        Container(
          padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            boxShadow: [BoxShadow(color: Colors.grey[Get.isDarkMode ? 800 : 300]!, blurRadius: 10)],
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('total'.tr, style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeLarge)),
              Text(PriceConverterHelper.convertPrice(_getTotalPrice()), style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeLarge, color: Theme.of(context).primaryColor)),
            ]),
            const SizedBox(height: Dimensions.paddingSizeSmall),

            Row(children: [
              _quantityButton(context, Icons.remove, () {
                if(_quantity > 1) setState(() => _quantity--);
              }),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
                child: Text(_quantity.toString(), style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeLarge)),
              ),
              _quantityButton(context, Icons.add, () => setState(() => _quantity++), filled: true),
              const SizedBox(width: Dimensions.paddingSizeDefault),
              Expanded(child: CustomButtonWidget(
                buttonText: _showUpdate ? 'update'.tr : 'add_to_cart'.tr, height: 45, width: 200,
                onPressed: _showUpdate ? _onUpdate : _onAddToCart,
              )),
            ]),
          ]),
        ),
      ]),
    );
  }

  Widget _vegBadge(BuildContext context) {
    final bool isVeg = widget.item.veg == 1;
    final Color color = isVeg ? Colors.green : Theme.of(context).colorScheme.error;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeExtraSmall, vertical: 2),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(Dimensions.radiusSmall), border: Border.all(color: color, width: 1)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.circle, size: 8, color: color),
        const SizedBox(width: Dimensions.paddingSizeExtraSmall),
        Text(isVeg ? 'veg'.tr : 'non_veg'.tr, style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeExtraSmall, color: color)),
      ]),
    );
  }

  /// ----- New (food) variation system -----

  List<Widget> _buildFoodVariations(BuildContext context) {
    List<Widget> widgets = [];
    for(int i = 0; i < _foodVariations.length; i++) {
      final FoodVariation foodVariation = _foodVariations[i];
      final bool isMulti = foodVariation.type == 'multi';
      final bool isRequired = _isRequired(foodVariation.required);
      final int min = int.tryParse(foodVariation.min ?? '') ?? 0;
      final int max = int.tryParse(foodVariation.max ?? '') ?? 0;
      final int selectedCount = _foodSelected[i].where((s) => s).length;
      final bool completed = isRequired && (isMulti ? (min > 0 ? min : 1) : 1) <= selectedCount;

      widgets.add(Container(
        padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
        margin: const EdgeInsets.only(top: Dimensions.paddingSizeDefault),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
          color: isRequired ? (completed ? Theme.of(context).primaryColor.withValues(alpha: 0.05) : Theme.of(context).hintColor.withValues(alpha: 0.05)) : Colors.transparent,
          border: Border.all(width: 1, color: isRequired ? (completed ? Theme.of(context).primaryColor.withValues(alpha: 0.3) : Theme.of(context).hintColor.withValues(alpha: 0.1)) : Colors.transparent),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Flexible(child: Text(foodVariation.name ?? '', style: robotoBold, maxLines: 1, overflow: TextOverflow.ellipsis)),
            _statusBadge(context, isRequired: isRequired, completed: completed),
          ]),
          const SizedBox(height: 2),
          Text(
            isMulti ? '${'select_minimum'.tr} $min ${'and_up_to'.tr} $max ${'options'.tr}' : 'select_one'.tr,
            style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeExtraSmall, color: Theme.of(context).hintColor),
          ),
          const SizedBox(height: Dimensions.paddingSizeExtraSmall),

          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            itemCount: foodVariation.variationValues?.length ?? 0,
            itemBuilder: (context, j) {
              final VariationValue value = foodVariation.variationValues![j];
              return _selectableRow(
                context,
                selected: _foodSelected[i][j],
                isMulti: isMulti,
                title: value.level ?? '',
                price: double.tryParse(value.optionPrice ?? '0') ?? 0,
                onTap: () => _onFoodVariationTap(i, j, isMulti, max),
              );
            },
          ),
        ]),
      ));
    }
    return widgets;
  }

  Widget _statusBadge(BuildContext context, {required bool isRequired, required bool completed}) {
    final String text = isRequired ? (completed ? 'completed'.tr : 'required'.tr) : 'optional'.tr;
    final Color color = isRequired ? (completed ? Theme.of(context).primaryColor : Theme.of(context).colorScheme.error) : Theme.of(context).hintColor;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall, vertical: 2),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(Dimensions.radiusSmall), color: color.withValues(alpha: 0.1)),
      child: Text(text, style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeExtraSmall, color: color)),
    );
  }

  /// ----- Old (choice-option) variation system -----

  List<Widget> _buildOldVariations(BuildContext context) {
    List<Widget> widgets = [];
    if(_choiceOptions.isNotEmpty) {
      print('DEBUG: Building choice options, count: ${_choiceOptions.length}');
      for(int i = 0; i < _choiceOptions.length; i++) {
        final ChoiceOptions choice = _choiceOptions[i];
        print('DEBUG: Choice $i: title=${choice.title}, options=${choice.options}');
        widgets.add(_oldVariationHeader(context, choice.title ?? ''));
        for(int j = 0; j < (choice.options?.length ?? 0); j++) {
          widgets.add(_selectableRow(
            context,
            selected: _selectedChoiceIndex[i] == j,
            isMulti: false,
            title: choice.options![j],
            price: null,
            onTap: () {
              print('DEBUG: Selected choice $i, index $j: ${choice.options![j]}');
              setState(() { _selectedChoiceIndex[i] = j; _updateMatch(); });
            },
          ));
        }
      }
    } else if(_variations.isNotEmpty) {
      widgets.add(_oldVariationHeader(context, 'variations'.tr));
      for(int i = 0; i < _variations.length; i++) {
        widgets.add(_selectableRow(
          context,
          selected: _selectedVariationIndex == i,
          isMulti: false,
          title: _variations[i].type ?? '',
          price: _variations[i].price,
          onTap: () => setState(() { _selectedVariationIndex = i; _updateMatch(); }),
        ));
      }
    }
    return widgets;
  }

  Widget _oldVariationHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(top: Dimensions.paddingSizeDefault, bottom: Dimensions.paddingSizeExtraSmall),
      child: Row(children: [
        Flexible(child: Text(title, style: robotoBold, maxLines: 1, overflow: TextOverflow.ellipsis)),
        const SizedBox(width: Dimensions.paddingSizeSmall),
        _statusBadge(context, isRequired: true, completed: true),
        const Spacer(),
        Text('select_one'.tr, style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeExtraSmall, color: Theme.of(context).hintColor)),
      ]),
    );
  }

  /// ----- Add-ons -----

  List<Widget> _buildAddOns(BuildContext context) {
    List<Widget> widgets = [Padding(
      padding: const EdgeInsets.only(top: Dimensions.paddingSizeDefault, bottom: Dimensions.paddingSizeExtraSmall),
      child: Row(children: [
        Text('addons'.tr, style: robotoBold),
        const SizedBox(width: Dimensions.paddingSizeSmall),
        _statusBadge(context, isRequired: false, completed: false),
      ]),
    )];
    for(int i = 0; i < _addOns.length; i++) {
      final AddOns addOn = _addOns[i];
      widgets.add(Padding(
        padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeExtraSmall),
        child: Row(children: [
          InkWell(
            onTap: () => setState(() => _addOnSelected[i] = !_addOnSelected[i]),
            child: Icon(
              _addOnSelected[i] ? Icons.check_box : Icons.check_box_outline_blank,
              color: _addOnSelected[i] ? Theme.of(context).primaryColor : Theme.of(context).disabledColor, size: 22,
            ),
          ),
          const SizedBox(width: Dimensions.paddingSizeSmall),
          Expanded(child: Text(addOn.name ?? '', style: robotoRegular)),
          Text((addOn.price ?? 0) > 0 ? '+ ${PriceConverterHelper.convertPrice(addOn.price)}' : 'free'.tr, style: robotoRegular.copyWith(color: Theme.of(context).primaryColor)),

          if(_addOnSelected[i]) Padding(
            padding: const EdgeInsets.only(left: Dimensions.paddingSizeSmall),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              _quantityButton(context, Icons.remove, () {
                if(_addOnQty[i] > 1) setState(() => _addOnQty[i]--);
              }, small: true),
              Padding(padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall), child: Text(_addOnQty[i].toString(), style: robotoMedium)),
              _quantityButton(context, Icons.add, () => setState(() => _addOnQty[i]++), small: true, filled: true),
            ]),
          ),
        ]),
      ));
    }
    return widgets;
  }

  Widget _selectableRow(BuildContext context, {required bool selected, required bool isMulti, required String title, double? price, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeExtraSmall),
        child: Row(children: [
          Icon(
            isMulti
                ? (selected ? Icons.check_box : Icons.check_box_outline_blank)
                : (selected ? Icons.radio_button_checked : Icons.radio_button_off),
            color: selected ? Theme.of(context).primaryColor : Theme.of(context).disabledColor, size: 22,
          ),
          const SizedBox(width: Dimensions.paddingSizeSmall),
          Expanded(child: Text(title, style: selected ? robotoMedium : robotoRegular)),
          if(price != null && price > 0) Text('+ ${PriceConverterHelper.convertPrice(price)}', style: robotoRegular.copyWith(color: Theme.of(context).primaryColor)),
        ]),
      ),
    );
  }

  Widget _quantityButton(BuildContext context, IconData icon, VoidCallback onTap, {bool filled = false, bool small = false}) {
    final double size = small ? 24 : 30;
    return InkWell(
      onTap: onTap,
      child: Container(
        height: size, width: size, alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: filled ? Theme.of(context).primaryColor : Theme.of(context).hintColor.withValues(alpha: 0.15),
        ),
        child: Icon(icon, size: small ? 16 : 18, color: filled ? Colors.white : Theme.of(context).textTheme.bodyLarge!.color),
      ),
    );
  }

  void _onFoodVariationTap(int i, int j, bool isMulti, int max) {
    setState(() {
      if(isMulti) {
        if(!_foodSelected[i][j]) {
          final int selectedCount = _foodSelected[i].where((s) => s).length;
          if(max > 0 && selectedCount >= max) return;
        }
        _foodSelected[i][j] = !_foodSelected[i][j];
      } else {
        /// single select: tapping the already-selected option unselects it
        final bool wasSelected = _foodSelected[i][j];
        for(int k = 0; k < _foodSelected[i].length; k++) {
          _foodSelected[i][k] = false;
        }
        if(!wasSelected) _foodSelected[i][j] = true;
      }
      _updateMatch();
    });
  }

  bool _isRequired(String? required) {
    return required == 'on' || required == '1' || required == 'true' || required == 'yes';
  }

  double _getDiscountedBasePrice() {
    final double price = widget.item.price ?? 0;
    final double? discount = (widget.item.storeDiscount == 0 || widget.item.storeDiscount == null) ? widget.item.discount : widget.item.storeDiscount;
    final String? discountType = (widget.item.storeDiscount == 0 || widget.item.storeDiscount == null) ? widget.item.discountType : 'percent';
    return PriceConverterHelper.convertWithDiscount(price, discount, discountType) ?? price;
  }

  double _getUnitPrice() {
    final double discounted = _getDiscountedBasePrice();
    if(_isNewVariation) {
      double variationSum = 0;
      for(int i = 0; i < _foodVariations.length; i++) {
        for(int j = 0; j < (_foodVariations[i].variationValues?.length ?? 0); j++) {
          if(_foodSelected[i][j]) {
            variationSum += double.tryParse(_foodVariations[i].variationValues![j].optionPrice ?? '0') ?? 0;
          }
        }
      }
      return discounted + variationSum;
    } else {
      final Variation? matched = _getMatchedVariation();
      return matched?.price ?? discounted;
    }
  }

  double _getAddOnTotal() {
    double sum = 0;
    for(int i = 0; i < _addOns.length; i++) {
      if(_addOnSelected[i]) sum += (_addOns[i].price ?? 0) * _addOnQty[i];
    }
    return sum;
  }

  double _getTotalPrice() => (_getUnitPrice() + _getAddOnTotal()) * _quantity;

  Variation? _getMatchedVariation() {
    if(_variations.isEmpty) return null;
    if(_choiceOptions.isNotEmpty) {
      List<String> selected = [];
      for(int i = 0; i < _choiceOptions.length; i++) {
        final options = _choiceOptions[i].options ?? [];
        if(_selectedChoiceIndex[i] < options.length) {
          String option = options[_selectedChoiceIndex[i]].trim().replaceAll(' ', '');
          selected.add(option);
        }
      }
      final String type = selected.join('-');
      for(final variation in _variations) {
        if(variation.type == type) return variation;
      }
      return null;
    } else {
      if(_selectedVariationIndex < _variations.length) return _variations[_selectedVariationIndex];
      return null;
    }
  }

  /// Validates the selected variations the same way stackfood does (required /
  /// min / max). Returns false and shows a snackbar when invalid.
  bool _validate() {
    if(_isNewVariation) {
      for(int i = 0; i < _foodVariations.length; i++) {
        final FoodVariation fv = _foodVariations[i];
        final bool isMulti = fv.type == 'multi';
        final bool isRequired = _isRequired(fv.required);
        final int min = int.tryParse(fv.min ?? '') ?? 0;
        final int max = int.tryParse(fv.max ?? '') ?? 0;
        final int selectedCount = _foodSelected[i].where((s) => s).length;

        if(!isMulti && isRequired && selectedCount == 0) {
          showCustomSnackBar('${'choose_a_variation_from'.tr} ${fv.name}');
          return false;
        } else if(isMulti && (isRequired || selectedCount > 0) && selectedCount < min) {
          showCustomSnackBar('${'you_need_to_select_minimum'.tr} $min ${'to_maximum'.tr} $max ${'options_from'.tr} ${fv.name} ${'variation'.tr}');
          return false;
        }
      }
    } else if(_variations.isNotEmpty && _getMatchedVariation() == null) {
      showCustomSnackBar('please_select_required_variations'.tr);
      return false;
    }
    return true;
  }

  /// Builds the order item from the current selections. [id] / [itemId] are kept
  /// when editing an existing item so the backend updates that line.
  OrderDetailsModel _buildSelectedItem({int? id, int? itemId}) {
    List<Variation>? variationList;
    List<FoodVariation>? foodVariationList;

    if(_isNewVariation) {
      foodVariationList = [];
      for(int i = 0; i < _foodVariations.length; i++) {
        List<VariationValue> selectedValues = [];
        for(int j = 0; j < (_foodVariations[i].variationValues?.length ?? 0); j++) {
          if(_foodSelected[i][j]) selectedValues.add(_foodVariations[i].variationValues![j]);
        }
        if(selectedValues.isNotEmpty) {
          foodVariationList.add(FoodVariation(
            name: _foodVariations[i].name, type: _foodVariations[i].type, min: _foodVariations[i].min,
            max: _foodVariations[i].max, required: _foodVariations[i].required, variationValues: selectedValues,
          ));
        }
      }
    } else {
      final Variation? matched = _getMatchedVariation();
      if(matched != null) {
        variationList = [Variation(type: matched.type, price: matched.price, stock: matched.stock)];
      }
    }

    List<AddOn> selectedAddOns = [];
    for(int i = 0; i < _addOns.length; i++) {
      if(_addOnSelected[i]) {
        selectedAddOns.add(AddOn(id: _addOns[i].id, name: _addOns[i].name, price: _addOns[i].price, quantity: _addOnQty[i]));
      }
    }

    return OrderDetailsModel(
      id: id,
      itemId: itemId ?? widget.item.id,
      price: _getUnitPrice(),
      quantity: _quantity,
      itemDetails: widget.item,
      variation: variationList,
      foodVariation: foodVariationList,
      addOns: selectedAddOns,
      totalAddOnPrice: _getAddOnTotal(),
      isEditable: true,
    );
  }

  void _onAddToCart() {
    if(!_validate()) return;
    Get.find<OrderEditController>().addItemToEditOrder(_buildSelectedItem());
    Get.back();
    Get.back();
    showCustomSnackBar('item_added_to_cart'.tr, isError: false);
  }

  void _onUpdate() {
    if(!_validate()) return;
    final OrderEditController controller = Get.find<OrderEditController>();

    if(_isEditMode) {
      /// editing an existing line opened from the edit-order screen
      controller.updateEditItem(
        widget.editIndex!,
        _buildSelectedItem(id: widget.orderDetails!.id, itemId: widget.orderDetails!.itemId),
      );
      Get.back();
    } else {
      /// the selection matched a line already in the order — update its quantity
      /// instead of adding a duplicate line
      final OrderDetailsModel matched = (controller.editOrderItemList ?? [])[_matchedIndex];
      controller.updateEditItem(_matchedIndex, _buildSelectedItem(id: matched.id, itemId: matched.itemId));
      Get.back();
      Get.back();
    }
    showCustomSnackBar('item_updated'.tr, isError: false);
  }
}
