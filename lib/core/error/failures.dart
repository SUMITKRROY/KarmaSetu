sealed class Failure {
  final String message;
  const Failure(this.message);
}

class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Server failure']);
}

class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Cache failure']);
}
