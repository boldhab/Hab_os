import 'failure.dart';

class ErrorHandler {
  static Failure handle(dynamic error) {
    if (error is Failure) return error;
    return ServerFailure(error.toString());
  }
}
