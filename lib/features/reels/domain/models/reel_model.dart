class ReelsModel {
  int? totalSize;
  String? limit;
  String? offset;
  List<Reel>? reels;

  ReelsModel({
    this.totalSize,
    this.limit,
    this.offset,
    this.reels,
  });

  ReelsModel.fromJson(Map<String, dynamic> json) {
    totalSize = json['total_size'];
    limit = json['limit']?.toString();
    offset = json['offset']?.toString();
    if (json['reels'] != null) {
      reels = <Reel>[];
      json['reels'].forEach((v) {
        reels!.add(Reel.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['total_size'] = totalSize;
    data['limit'] = limit;
    data['offset'] = offset;
    if (reels != null) {
      data['reels'] = reels!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Reel {
  int? id;
  int? storeId;
  int? moduleId;
  String? moduleType;
  String? description;
  String? thumbnail;
  String? video;
  bool? isAlwaysVisible;
  String? startDate;
  String? endDate;
  bool? status;
  int? totalViews;
  int? totalLikes;
  int? totalStoreVisits;
  String? createdAt;
  String? updatedAt;
  String? thumbnailFullUrl;
  String? videoFullUrl;
  String? reelStatusLabel;
  bool? orderNowButton;
  int? itemId;
  int? productId;
  List<ReelTranslation>? translations;

  Reel({
    this.id,
    this.storeId,
    this.moduleId,
    this.moduleType,
    this.description,
    this.thumbnail,
    this.video,
    this.isAlwaysVisible,
    this.startDate,
    this.endDate,
    this.status,
    this.totalViews,
    this.totalLikes,
    this.totalStoreVisits,
    this.createdAt,
    this.updatedAt,
    this.thumbnailFullUrl,
    this.videoFullUrl,
    this.reelStatusLabel,
    this.orderNowButton,
    this.itemId,
    this.productId,
  });

  Reel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    storeId = json['store_id'];
    moduleId = json['module_id'];
    moduleType = json['module_type'];
    description = json['description'];
    thumbnail = json['thumbnail'];
    video = json['video'];
    isAlwaysVisible = json['is_always_visible'];
    startDate = json['start_date'];
    endDate = json['end_date'];
    status = json['status'];
    totalViews = json['total_views'] != null ? int.parse(json['total_views'].toString()) : 0;
    totalLikes = json['total_likes'] != null ? int.parse(json['total_likes'].toString()) : 0;
    totalStoreVisits = json['total_store_visits'] != null ? int.parse(json['total_store_visits'].toString()) : 0;
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    thumbnailFullUrl = json['thumbnail_full_url'];
    videoFullUrl = json['video_full_url'];
    reelStatusLabel = json['reel_status_label'];
    orderNowButton = json['order_now_button'] == true || json['order_now_button'] == 1 || json['order_now_button'] == '1';
    itemId = json['item_id'] ?? json['food_id'];
    productId = json['product_id'];
    if (json['translations'] != null) {
      translations = <ReelTranslation>[];
      json['translations'].forEach((v) {
        translations!.add(ReelTranslation.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['store_id'] = storeId;
    data['module_id'] = moduleId;
    data['module_type'] = moduleType;
    data['description'] = description;
    data['thumbnail'] = thumbnail;
    data['video'] = video;
    data['is_always_visible'] = isAlwaysVisible;
    data['start_date'] = startDate;
    data['end_date'] = endDate;
    data['status'] = status;
    data['total_views'] = totalViews;
    data['total_likes'] = totalLikes;
    data['total_store_visits'] = totalStoreVisits;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    data['thumbnail_full_url'] = thumbnailFullUrl;
    data['video_full_url'] = videoFullUrl;
    data['reel_status_label'] = reelStatusLabel;
    data['order_now_button'] = orderNowButton;
    data['item_id'] = itemId;
    data['product_id'] = productId;
    if (translations != null) {
      data['translations'] = translations!.map((v) {
        if (v != null) {
          return v.toJson();
        }
        return null;
      }).toList();
    }
    return data;
  }
}

class ReelTranslation {
  int? id;
  String? key;
  String? value;
  String? locale;

  ReelTranslation({
    this.id,
    this.key,
    this.value,
    this.locale,
  });

  ReelTranslation.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    key = json['key'];
    value = json['value'];
    locale = json['locale'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['key'] = key;
    data['value'] = value;
    data['locale'] = locale;
    return data;
  }
}
