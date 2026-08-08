class VehicleListModel {
  int? totalSize;
  String? limit;
  String? offset;
  List<Vehicles>? vehicles;

  VehicleListModel({this.totalSize, this.limit, this.offset, this.vehicles});

  VehicleListModel.fromJson(Map<String, dynamic> json) {
    totalSize = json['total_size'];
    limit = json['limit']?.toString();
    offset = json['offset']?.toString();
    if (json['vehicles'] != null) {
      vehicles = [];
      json['vehicles'].forEach((v) {
        vehicles!.add(Vehicles.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['total_size'] = totalSize;
    data['limit'] = limit;
    data['offset'] = offset;
    if (vehicles != null) {
      data['vehicles'] = vehicles!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Vehicles {
  int? id;
  String? name;
  String? description;
  String? thumbnailFullUrl;
  int? status;

  Vehicles({
    this.id,
    this.name,
    this.description,
    this.thumbnailFullUrl,
    this.status,
  });

  Vehicles.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    description = json['description'];
    thumbnailFullUrl = json['thumbnail_full_url'] ?? json['image_full_url'];
    status = json['status'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    data['description'] = description;
    data['thumbnail_full_url'] = thumbnailFullUrl;
    data['status'] = status;
    return data;
  }
}
