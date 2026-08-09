/// Base exception for Boxx failures.
class BoxxException implements Exception {
  const BoxxException(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() => '$runtimeType: $message';
}

/// The Boxx instance was configured with incompatible or unsafe options.
class BoxxConfigurationException extends BoxxException {
  const BoxxConfigurationException(super.message);
}

/// An encryption or decryption operation failed.
class BoxxEncryptionException extends BoxxException {
  const BoxxEncryptionException(super.message, {super.cause});
}

/// A stored record is malformed, corrupted, or uses an unexpected format.
class BoxxCorruptDataException extends BoxxException {
  const BoxxCorruptDataException(super.message, {super.cause});
}

/// A storage operation failed.
class BoxxStorageException extends BoxxException {
  const BoxxStorageException(this.operation, Object cause)
    : super('Storage operation "$operation" failed', cause: cause);

  final String operation;
}

/// A value could not be returned as the requested generic type.
class BoxxTypeMismatchException extends BoxxException {
  const BoxxTypeMismatchException({
    required this.expectedType,
    required this.actualType,
  }) : super('Expected $expectedType but found $actualType');

  final String expectedType;
  final String actualType;
}

/// An operation was attempted after [Boxx.dispose].
class BoxxDisposedException extends BoxxException {
  const BoxxDisposedException() : super('This Boxx instance has been disposed');
}

/// Structured, value-free diagnostic information for support integrations.
class BoxxDiagnosticEvent {
  BoxxDiagnosticEvent({
    required this.operation,
    required this.error,
    required this.stackTrace,
  }) : timestamp = DateTime.now().toUtc();

  final String operation;
  final Object error;
  final StackTrace stackTrace;
  final DateTime timestamp;
}

/// Receives operational failures without exposing stored keys or values.
typedef BoxxDiagnostics = void Function(BoxxDiagnosticEvent event);
