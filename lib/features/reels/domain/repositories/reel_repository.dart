import 'package:sixam_mart_store/api/api_client.dart';
import 'package:sixam_mart_store/features/reels/domain/models/reel_model.dart';
import 'package:sixam_mart_store/features/reels/domain/repositories/reel_repository_interface.dart';
import 'package:sixam_mart_store/features/store/domain/models/item_model.dart';
import 'package:sixam_mart_store/util/app_constants.dart';
import 'package:get/get.dart';

class ReelRepository implements ReelRepositoryInterface {
  final ApiClient apiClient;
  ReelRepository({required this.apiClient});

  @override
  Future add(value) {
    throw UnimplementedError();
  }

  @override
  Future delete(int? id) {
    throw UnimplementedError();
  }

  @override
  Future get(int? id) {
    throw UnimplementedError();
  }

  @override
  Future getList() {
    throw UnimplementedError();
  }

  @override
  Future update(Map<String, dynamic> body) {
    throw UnimplementedError();
  }

  @override
  Future<ReelsModel?> getReelsList(String offset, String status, String sortBy, {String? search}) async {
    String url = '${AppConstants.getReelsUri}?offset=$offset&limit=10&status=$status&sort_by=$sortBy';
    if (search != null && search.isNotEmpty) {
      url += '&search=$search';
    }
    Response response = await apiClient.getData(url);
    if (response.statusCode == 200) {
      return ReelsModel.fromJson(response.body);
    }
    return null;
  }

  @override
  Future<Reel?> getReelDetails(int reelId) async {
    String url = '${AppConstants.reelDetailsUri}?reel_id=$reelId';
    Response response = await apiClient.getData(url);
    if (response.statusCode == 200) {
      return Reel.fromJson(response.body);
    }
    return null;
  }

  @override
  Future<Response> storeReel(Map<String, String> body, List<MultipartBody> files) async {
    return await apiClient.postMultipartData(AppConstants.addReelUri, body, files, handleError: false);
  }

  @override
  Future<Response> updateReel(Map<String, String> body, List<MultipartBody> files) async {
    return await apiClient.postMultipartData(AppConstants.updateReelUri, body, files);
  }

  @override
  Future<Response> deleteReel(int reelId) async {
    return await apiClient.postData(
      '${AppConstants.deleteReelUri}?reel_id=$reelId', {'_method': 'DELETE'},
    );
  }

  @override
  Future<Response> changeReelStatus(int reelId, int status) async {
    return await apiClient.postData(
      '${AppConstants.changeReelStatusUri}?reel_id=$reelId&status=$status', {'_method': 'PUT',},
    );
  }

  @override
  Future<ItemModel?> getReelAssignableItems() async {
    Response response = await apiClient.getData('${AppConstants.itemListUri}?offset=1&limit=999999&type=all&search=');
    if (response.statusCode == 200) {
      return ItemModel.fromJson(response.body);
    }
    return null;
  }
}
