import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart_store/features/auth/controllers/auth_controller.dart';
import 'package:sixam_mart_store/features/rental_module/provider/controllers/provider_controller.dart';
import 'package:sixam_mart_store/features/store/domain/models/item_model.dart';
import 'package:sixam_mart_store/util/dimensions.dart';
import 'package:sixam_mart_store/util/styles.dart';

/// Dropdown-style field for the reel "order now" item with a locally searchable
/// list. The item list and its loading state are owned by the caller.
class ReelItemSelectorWidget extends StatelessWidget {
  final List<Item> items;
  final int? selectedItemId;
  final bool isLoading;
  final ValueChanged<int?> onSelected;

  const ReelItemSelectorWidget({
    super.key,
    required this.items,
    required this.selectedItemId,
    required this.isLoading,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {

    bool isRental = Get.find<AuthController>().getModuleType() == 'rental';
    final Item? selected = selectedItemId == null
        ? null
        : items.cast<Item?>().firstWhere((i) => i?.id == selectedItemId, orElse: () => null);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border.all(color: Theme.of(context).disabledColor.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
        onTap: isLoading ? null : () => _openSearchSheet(context),
        child: Padding(
          padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
          child: Row(children: [
            Expanded(child: _buildFieldContent(context, selected, isRental)),
            const SizedBox(width: Dimensions.paddingSizeSmall),
            isLoading
                ? SizedBox(
                    height: 18, width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Theme.of(context).primaryColor),
                  )
                : Icon(Icons.arrow_drop_down, color: Theme.of(context).hintColor),
          ]),
        ),
      ),
    );
  }

  Widget _buildFieldContent(BuildContext context, Item? selected, bool? isRental) {
    if (isLoading) {
      return Text('loading'.tr, style: robotoRegular.copyWith(color: Theme.of(context).hintColor));
    }
    if (selected != null) {
      return Text(
        selected.name ?? '',
        maxLines: 1, overflow: TextOverflow.ellipsis,
        style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeDefault),
      );
    }
    return RichText(
      text: TextSpan(
        text: isRental == true ? 'Select_vehicle': 'select_item'.tr,
        style: robotoRegular.copyWith(color: Theme.of(context).hintColor),
        children: [
          TextSpan(text: ' *', style: robotoRegular.copyWith(color: Theme.of(context).colorScheme.error)),
        ],
      ),
    );
  }

  void _openSearchSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ItemSearchSheet(
        items: items,
        selectedItemId: selectedItemId,
        onSelected: onSelected,
      ),
    );
  }
}

class _ItemSearchSheet extends StatefulWidget {
  final List<Item> items;
  final int? selectedItemId;
  final ValueChanged<int?> onSelected;

  const _ItemSearchSheet({
    required this.items,
    required this.selectedItemId,
    required this.onSelected,
  });

  @override
  State<_ItemSearchSheet> createState() => _ItemSearchSheetState();
}

class _ItemSearchSheetState extends State<_ItemSearchSheet> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late List<Item> _filteredItems;

  @override
  void initState() {
    super.initState();
    _filteredItems = widget.items;

    final bool isRental = Get.find<AuthController>().getModuleType() == 'rental';
    if (isRental) {
      _scrollController.addListener(_onScroll);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
      final providerController = Get.find<ProviderController>();
      if (!providerController.isLoading && providerController.vehicleList != null && providerController.vehiclePageSize != null && providerController.vehiclePageSize! > 0) {
        int nextPage = (providerController.vehicleList!.length ~/ providerController.vehiclePageSize!) + 1;
        providerController.getVehicleList(offset: nextPage.toString(), search: _searchController.text.trim()).then((_) {
          setState(() {});
        });
      }
    }
  }

  void _onSearchChanged(String value) {
    final String query = value.trim().toLowerCase();
    setState(() {
      _filteredItems = query.isEmpty
          ? widget.items
          : widget.items.where((i) => (i.name ?? '').toLowerCase().contains(query)).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    bool isRental = Get.find<AuthController>().getModuleType() == 'rental';
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(Dimensions.radiusLarge)),
        ),
        padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
        child: Column(children: [
          Container(
            height: 4, width: 40,
            decoration: BoxDecoration(
              color: Theme.of(context).disabledColor.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: Dimensions.paddingSizeDefault),

          isRental ? const SizedBox.shrink() : TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            textInputAction: TextInputAction.search,
            style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeDefault),
            decoration: InputDecoration(
              hintText: 'search_item'.tr,
              hintStyle: robotoRegular.copyWith(color: Theme.of(context).hintColor),
              prefixIcon: Icon(Icons.search, color: Theme.of(context).hintColor),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeDefault),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                borderSide: BorderSide(color: Theme.of(context).disabledColor.withValues(alpha: 0.3)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                borderSide: BorderSide(color: Theme.of(context).disabledColor.withValues(alpha: 0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                borderSide: BorderSide(color: Theme.of(context).primaryColor),
              ),
            ),
          ),
          SizedBox(height: isRental ? 0 : Dimensions.paddingSizeDefault),

          Expanded(
            child: isRental
                ? GetBuilder<ProviderController>(builder: (providerController) {
                    return widget.items.isEmpty
                        ? Center(child: Text('no_vehicle_found'.tr, style: robotoRegular.copyWith(color: Theme.of(context).hintColor)))
                        : Stack(
                            children: [
                              ListView.separated(
                                controller: _scrollController,
                                itemCount: widget.items.length,
                                separatorBuilder: (context, index) => Divider(height: 1, color: Theme.of(context).disabledColor.withValues(alpha: 0.15)),
                                itemBuilder: (context, index) {
                                  final Item item = widget.items[index];
                                  final bool isSelected = item.id == widget.selectedItemId;
                                  return ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    title: Text(
                                      item.name ?? '',
                                      maxLines: 1, overflow: TextOverflow.ellipsis,
                                      style: robotoRegular.copyWith(
                                        fontSize: Dimensions.fontSizeDefault,
                                        color: isSelected ? Theme.of(context).primaryColor : Theme.of(context).textTheme.bodyLarge!.color,
                                      ),
                                    ),
                                    trailing: isSelected ? Icon(Icons.check_circle, color: Theme.of(context).primaryColor, size: 20) : null,
                                    onTap: () {
                                      widget.onSelected(item.id);
                                      Navigator.pop(context);
                                    },
                                  );
                                },
                              ),
                              if (providerController.isLoading)
                                Positioned(
                                  bottom: 0,
                                  left: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                                    color: Theme.of(context).cardColor,
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        color: Theme.of(context).primaryColor,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          );
                  })
                : _filteredItems.isEmpty
                    ? Center(child: Text('no_item_found'.tr, style: robotoRegular.copyWith(color: Theme.of(context).hintColor)))
                    : ListView.separated(
                        controller: _scrollController,
                        itemCount: _filteredItems.length,
                        separatorBuilder: (context, index) => Divider(height: 1, color: Theme.of(context).disabledColor.withValues(alpha: 0.15)),
                        itemBuilder: (context, index) {
                          final Item item = _filteredItems[index];
                          final bool isSelected = item.id == widget.selectedItemId;
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              item.name ?? '',
                              maxLines: 1, overflow: TextOverflow.ellipsis,
                              style: robotoRegular.copyWith(
                                fontSize: Dimensions.fontSizeDefault,
                                color: isSelected ? Theme.of(context).primaryColor : Theme.of(context).textTheme.bodyLarge!.color,
                              ),
                            ),
                            trailing: isSelected ? Icon(Icons.check_circle, color: Theme.of(context).primaryColor, size: 20) : null,
                            onTap: () {
                              widget.onSelected(item.id);
                              Navigator.pop(context);
                            },
                          );
                        },
                      ),
          ),
        ]),
      ),
    );
  }
}
