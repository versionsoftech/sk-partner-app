import 'package:get/get.dart';
import 'package:sixam_mart_store/api/api_client.dart';
import 'package:sixam_mart_store/features/reels/domain/models/reel_model.dart';
import 'package:sixam_mart_store/features/store/domain/models/item_model.dart';
import 'package:sixam_mart_store/interface/repository_interface.dart';

abstract class ReelRepositoryInterface implements RepositoryInterface {
  Future<ReelsModel?> getReelsList(String offset, String status, String sortBy, {String? search});
  Future<Reel?> getReelDetails(int reelId);
  Future<Response> storeReel(Map<String, String> body, List<MultipartBody> files);
  Future<Response> updateReel(Map<String, String> body, List<MultipartBody> files);
  Future<Response> deleteReel(int reelId);
  Future<Response> changeReelStatus(int reelId, int status);
  Future<ItemModel?> getReelAssignableItems();
}
