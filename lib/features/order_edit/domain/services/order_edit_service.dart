import 'package:sixam_mart_store/common/models/response_model.dart';
import 'package:sixam_mart_store/features/order/domain/models/order_details_model.dart';
import 'package:sixam_mart_store/features/order_edit/domain/models/edit_order_body_model.dart';
import 'package:sixam_mart_store/features/order_edit/domain/repositories/order_edit_repository_interface.dart';
import 'package:sixam_mart_store/features/order_edit/domain/services/order_edit_service_interface.dart';
import 'package:sixam_mart_store/features/store/domain/models/item_model.dart';
import 'package:sixam_mart_store/helper/price_converter_helper.dart';

class OrderEditService implements OrderEditServiceInterface {
  final OrderEditRepositoryInterface orderEditRepositoryInterface;
  OrderEditService({required this.orderEditRepositoryInterface});

  /// Copies the loaded order items into a working list so edits are discarded if
  /// the user cancels. Each item is a fresh object (so quantity changes don't touch
  /// the original), but variation / add-on references are shared — they are never
  /// mutated in place, only replaced wholesale. Avoids a JSON round-trip that would
  /// lose the food-variation data. Every item is marked editable.
  @override
  List<OrderDetailsModel> prepareEditList(List<OrderDetailsModel>? source) {
    List<OrderDetailsModel> list = [];
    if (source != null) {
      for (OrderDetailsModel item in source) {
        list.add(OrderDetailsModel(
          id: item.id,
          itemId: item.itemId,
          orderId: item.orderId,
          price: item.price,
          itemDetails: item.itemDetails,
          variation: item.variation != null ? List<Variation>.from(item.variation!) : null,
          foodVariation: item.foodVariation != null ? List<FoodVariation>.from(item.foodVariation!) : null,
          addOns: item.addOns != null ? List<AddOn>.from(item.addOns!) : null,
          discountOnItem: item.discountOnItem,
          discountType: item.discountType,
          quantity: item.quantity,
          taxAmount: item.taxAmount,
          variant: item.variant,
          createdAt: item.createdAt,
          updatedAt: item.updatedAt,
          itemCampaignId: item.itemCampaignId,
          totalAddOnPrice: item.totalAddOnPrice,
          isEditable: true,
        ));
      }
    }
    return list;
  }

  /// Builds an order item for an item that has no variation (quick add).
  @override
  OrderDetailsModel buildDirectItem(Item item) {
    double price = item.price ?? 0;
    double? discount = (item.storeDiscount == 0 || item.storeDiscount == null) ? item.discount : item.storeDiscount;
    String? discountType = (item.storeDiscount == 0 || item.storeDiscount == null) ? item.discountType : 'percent';
    double discounted = PriceConverterHelper.convertWithDiscount(price, discount, discountType) ?? price;

    return OrderDetailsModel(
      itemId: item.id, price: discounted, quantity: 1, itemDetails: item,
      variation: [], foodVariation: [], addOns: [], totalAddOnPrice: 0, isEditable: true,
    );
  }

  @override
  EditOrderBodyModel buildEditBody(int orderId, List<OrderDetailsModel> items) {
    return EditOrderBodyModel(
      orderId: orderId,
      carts: items.map((item) => _buildEditCart(item)).toList(),
    );
  }

  /// Converts a working item into the cart payload expected by the edit-order API.
  /// New food-variation items send `[{name, values: [{label}]}]`; old-variation
  /// items send the flat `[{type}]` form (also mirrored into `variant`).
  EditOrderCart _buildEditCart(OrderDetailsModel item) {
    List<Map<String, dynamic>> variation = [];
    List<Map<String, dynamic>> variant = [];

    if (item.foodVariation != null && item.foodVariation!.isNotEmpty) {
      for (FoodVariation foodVariation in item.foodVariation!) {
        variation.add({
          'name': foodVariation.name,
          'values': (foodVariation.variationValues ?? []).map((value) => {'label': value.level}).toList(),
        });
      }
    } else if (item.variation != null && item.variation!.isNotEmpty) {
      for (Variation value in item.variation!) {
        variation.add({'type': value.type});
        variant.add({'type': value.type});
      }
    }

    List<int> addOnIds = [];
    List<int> addOnQtys = [];
    if (item.addOns != null) {
      for (AddOn addOn in item.addOns!) {
        int? addOnId = addOn.id;
        if (addOnId == null && item.itemDetails?.addOns != null) {
          for (AddOns availableAddOn in item.itemDetails!.addOns!) {
            if (availableAddOn.name == addOn.name) {
              addOnId = availableAddOn.id;
              break;
            }
          }
        }
        if (addOnId != null) {
          addOnIds.add(addOnId);
          addOnQtys.add(addOn.quantity ?? 1);
        }
      }
    }

    return EditOrderCart(
      orderDetailsId: item.id, itemId: item.itemId, itemType: 'item', quantity: item.quantity,
      variation: variation, variant: variant, addOnIds: addOnIds, addOnQtys: addOnQtys,
    );
  }

  @override
  Future<ResponseModel> updateOrder(Map<String, dynamic> body) async {
    return await orderEditRepositoryInterface.updateOrder(body);
  }
}
