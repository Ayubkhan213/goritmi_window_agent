import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:tenx_global_agent/core/error/app_exception.dart';
import 'package:tenx_global_agent/core/services/api_services/base_api_services.dart'
    show BaseApiServices;

class NetworkApiServices extends BaseApiServices {
  @override
  Future getGetApiResponse({required String url}) async {
    dynamic responseJson;

    try {
      var response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 15));
      responseJson = returnResponse(response);
    } on TimeoutException {
      throw FetchDataException(
        message: 'Connection timed out. Please try again.',
      );
    } on SocketException {
      throw FetchDataException(message: 'No Internet Connection');
    }

    return responseJson;
  }

  @override
  Future getPostApiResponse({required String url, body}) async {
    print(body);
    dynamic responseJson;
    try {
      var response = await http
          .post(
            Uri.parse(url),
            headers: {"Content-Type": "application/json"},
            body: body,
          )
          .timeout(const Duration(seconds: 15));
      responseJson = returnResponse(response);
    } on SocketException {
      throw FetchDataException(message: 'No Internet Connection');
    }
    return responseJson;
  }

  dynamic returnResponse(http.Response response) {
    switch (response.statusCode) {
      // ✅ 2xx: Success
      case 200:
        return jsonDecode(response.body);
      case 201:
        return jsonDecode(response.body); // Created
      case 204:
        return null; // No Content

      // ❌ 4xx: Client Errors
      case 400:
        throw BadRequestException(
          message: 'Bad Request: ${response.reasonPhrase}',
        );
      case 401:
        throw UnauthorisedException(
          message: 'Unauthorized: ${response.reasonPhrase}',
        );

      case 402:
        throw PaymentRequiredException(
          message: 'Payment Required: ${response.reasonPhrase}',
        );
      case 403:
        throw ForbiddenException(
          message: 'Forbidden: ${response.reasonPhrase}',
        );
      case 404:
        throw NotFoundException(message: 'Not Found: ${response.reasonPhrase}');
      case 409:
        throw ConflictException(message: 'Conflict: ${response.reasonPhrase}');
      case 412:
        throw PreconditionFailedException(
          message: 'Precondition Failed: ${response.reasonPhrase}',
        );
      case 415:
        throw UnsupportedMediaTypeException(
          message: 'Unsupported Media Type: ${response.reasonPhrase}',
        );
      case 429:
        throw TooManyRequestsException(
          message: 'Too Many Requests: ${response.reasonPhrase}',
        );

      // ❌ 5xx: Server Errors
      case 500:
        throw ServerException(
          message: 'Internal Server Error: ${response.reasonPhrase}',
        );
      case 502:
        throw BadGatewayException(
          message: 'Bad Gateway: ${response.reasonPhrase}',
        );
      case 503:
        throw ServiceUnavailableException(
          message: 'Service Unavailable: ${response.reasonPhrase}',
        );
      case 504:
        throw GatewayTimeoutException(
          message: 'Gateway Timeout: ${response.reasonPhrase}',
        );

      // ➕ Redirection or unknown codes
      case 301:
        throw FetchDataException(
          message: 'Resource Moved Permanently: ${response.reasonPhrase}',
        );

      default:
        throw FetchDataException(
          message:
              'Error occurred during communication with server. Status code: ${response.statusCode}',
        );
    }
  }
}
