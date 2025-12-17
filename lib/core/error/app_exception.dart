// ignore_for_file: use_super_parameters

class AppException implements Exception {
  final String message;
  final String prefix;
  AppException({required this.message, required this.prefix});
  @override
  String toString() {
    return '$message $prefix';
  }
}

class FetchDataException extends AppException {
  FetchDataException({required message})
    : super(message: message, prefix: 'Error During Communication');
}

class BadRequestException extends AppException {
  BadRequestException({required String message})
    : super(message: message, prefix: 'Invalid request');
}

class UnauthoriseException extends AppException {
  UnauthoriseException({required String message})
    : super(message: message, prefix: 'Unauthorised request');
}

class NotFoundException extends AppException {
  NotFoundException({required String message})
    : super(message: message, prefix: 'Resource Not Found');
}

class ServerException extends AppException {
  ServerException({required String message})
    : super(message: message, prefix: 'Server Error');
}

class ServiceUnavailableException extends AppException {
  ServiceUnavailableException({required String message})
    : super(message: message, prefix: 'Service Unavailable');
}

// class TimeoutException extends AppException {
//   TimeoutException({required String message})
//       : super(message: message, prefix: 'Request Timeout');
// }

class UnauthorisedException extends AppException {
  UnauthorisedException({required String message})
    : super(message: message, prefix: 'Unauthorised Request');
}

class ForbiddenException extends AppException {
  ForbiddenException({required String message})
    : super(message: message, prefix: 'Forbidden Request');
}

class ConflictException extends AppException {
  ConflictException({required String message})
    : super(message: message, prefix: 'Conflict Occurred');
}

class OfflineException extends AppException {
  OfflineException({required String message})
    : super(message: message, prefix: 'No Internet Connection');
}

class BadGatewayException extends AppException {
  BadGatewayException({required String message})
    : super(message: message, prefix: 'Bad Gateway');
}

class GatewayTimeoutException extends AppException {
  GatewayTimeoutException({required String message})
    : super(message: message, prefix: 'Gateway Timeout');
}

class UnsupportedMediaTypeException extends AppException {
  UnsupportedMediaTypeException({required String message})
    : super(message: message, prefix: 'Unsupported Media Type');
}

class RequestEntityTooLargeException extends AppException {
  RequestEntityTooLargeException({required String message})
    : super(message: message, prefix: 'Request Entity Too Large');
}

class PreconditionFailedException extends AppException {
  PreconditionFailedException({required String message})
    : super(message: message, prefix: 'Precondition Failed');
}

class PaymentRequiredException extends AppException {
  PaymentRequiredException({required String message})
    : super(message: message, prefix: 'Payment Required');
}

class TooManyRequestsException extends AppException {
  TooManyRequestsException({required String message})
    : super(message: message, prefix: 'Too Many Requests');
}
