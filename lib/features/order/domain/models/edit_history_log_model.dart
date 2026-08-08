class EditHistoryLogModel {
  int? orderId;
  int? totalSize;
  String? limit;
  String? offset;
  List<EditLog>? editLogs;

  EditHistoryLogModel({this.orderId, this.totalSize, this.limit, this.offset, this.editLogs});

  EditHistoryLogModel.fromJson(Map<String, dynamic> json) {
    orderId = json['order_id'];
    totalSize = json['total_size'] != null ? int.tryParse(json['total_size'].toString()) : null;
    limit = json['limit']?.toString();
    offset = json['offset']?.toString();
    if (json['edit_logs'] != null) {
      editLogs = [];
      json['edit_logs'].forEach((v) => editLogs!.add(EditLog.fromJson(v)));
    }
  }
}

class EditLog {
  int? id;
  String? log;
  String? remark;
  String? editedBy;
  String? editedByLabel;
  String? createdAt;

  EditLog({this.id, this.log, this.remark, this.editedBy, this.editedByLabel, this.createdAt});

  EditLog.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    log = json['log'];
    remark = json['remark'];
    editedBy = json['edited_by'];
    editedByLabel = json['edited_by_label'];
    createdAt = json['created_at'];
  }
}
