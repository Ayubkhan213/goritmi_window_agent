abstract class BaseApiServices {
  Future<dynamic> getGetApiResponse({required String url});
  Future<dynamic> getPostApiResponse({required String url, dynamic body});
}
