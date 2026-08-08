/// Body for PUT /api/v1/vendor/update-order (edit an existing order's items).
class EditOrderBodyModel {
  int? orderId;
  List<EditOrderCart>? carts;

  EditOrderBodyModel({this.orderId, this.carts});

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['order_id'] = orderId;
    if (carts != null) {
      data['carts'] = carts!.map((cart) => cart.toJson()).toList();
    }
    return data;
  }
}

class EditOrderCart {
  /// Present for existing order items, null for newly added items.
  int? orderDetailsId;
  int? itemId;
  String? itemType;
  int? quantity;

  /// Raw variation payload. Old-variation items use `[{type}]`; new food-variation
  /// items use `[{name, values: [{label}]}]`.
  List<Map<String, dynamic>>? variation;
  List<Map<String, dynamic>>? variant;
  List<int>? addOnIds;
  List<int>? addOnQtys;

  EditOrderCart({
    this.orderDetailsId,
    this.itemId,
    this.itemType,
    this.quantity,
    this.variation,
    this.variant,
    this.addOnIds,
    this.addOnQtys,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (orderDetailsId != null) {
      data['order_details_id'] = orderDetailsId;
    }
    data['item_id'] = itemId;
    data['item_type'] = itemType ?? 'item';
    data['quantity'] = quantity;
    data['variation'] = variation ?? [];
    data['variant'] = variant ?? [];
    data['add_on_ids'] = addOnIds ?? [];
    data['add_on_qtys'] = addOnQtys ?? [];
    return data;
  }
}
