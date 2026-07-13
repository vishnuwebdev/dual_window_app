import 'package:grpc/grpc.dart';
import '../config/config_service.dart';
import '../utilities/logging.dart';

// Import generated protocol buffer files
// NOTE: These will be auto-generated from .proto files
// For now, using placeholder types that should be replaced with actual generated files

class CVMainClientService {
  late ClientChannel _channel;
  late String _bindAddress;

  CVMainClientService([String? bindAddress]) {
    final cfg = ConfigService();
    _bindAddress = bindAddress ?? cfg.lockerAddress;
    _initGrpcClient();
  }

  void _initGrpcClient() {
    logger.i('🔌 Initializing gRPC client at $_bindAddress...');
    try {
      final channelOptions = ChannelOptions(
        credentials: const ChannelCredentials.insecure(),
        codecRegistry: CodecRegistry(
          codecs: const [GzipCodec(), IdentityCodec()],
        ),
        idleTimeout: const Duration(seconds: 120),
      );

      final parts = _bindAddress.split(':');
      final host = parts[0];
      final port = int.parse(parts[1]);

      _channel = ClientChannel(
        host,
        port: port,
        options: channelOptions,
      );

      logger.i('✅ gRPC channel established to $host:$port');
    } catch (error, stack) {
      logger.e(
        '❌ Failed to initialize gRPC client',
        error: error,
        stackTrace: stack,
      );
      rethrow;
    }
  }

  /// Get backend version (health check)
  Future<String> getVersion() async {
    try {
      logger.d('📡 Requesting backend version...');
      // This will be implemented once protocol buffers are generated
      // For now, returning placeholder
      return '1.0.0-placeholder';
    } catch (e, stack) {
      logger.e('Failed to get version', error: e, stackTrace: stack);
      rethrow;
    }
  }

  /// Lightweight health check to determine if backend is reachable
  Future<bool> ping({Duration timeout = const Duration(seconds: 3)}) async {
    try {
      await getVersion().timeout(timeout);
      logger.d('✅ Backend is reachable');
      return true;
    } catch (_) {
      logger.w('⚠️ Backend is unreachable');
      return false;
    }
  }

  /// Unlock/open a locker compartment
  Future<LockerResponse> unlockLocker(int lockerNum) async {
    try {
      logger.i('🔓 Unlocking compartment $lockerNum...');
      // Implementation will be added with generated protocol buffers
      return LockerResponse(
        success: true,
        message: 'Compartment $lockerNum unlocked',
      );
    } catch (e, stack) {
      logger.e('Failed to unlock locker', error: e, stackTrace: stack);
      rethrow;
    }
  }

  /// Lock/close a locker compartment
  Future<LockerResponse> lockLocker(int lockerNum) async {
    try {
      logger.i('🔒 Locking compartment $lockerNum...');
      // Implementation will be added with generated protocol buffers
      return LockerResponse(
        success: true,
        message: 'Compartment $lockerNum locked',
      );
    } catch (e, stack) {
      logger.e('Failed to lock locker', error: e, stackTrace: stack);
      rethrow;
    }
  }

  /// Reinitialize with a new address
  Future<void> reinitialize(String newBindAddress) async {
    _bindAddress = newBindAddress;
    await dispose();
    _initGrpcClient();
  }

  /// Shutdown the gRPC channel
  Future<void> dispose() async {
    try {
      await _channel.shutdown();
      logger.i('🔌 gRPC channel shutdown');
    } catch (e) {
      logger.e('Error during shutdown', error: e);
    }
  }
}

/// Response model for locker operations
class LockerResponse {
  final bool success;
  final String message;
  final String? errorCode;

  LockerResponse({
    required this.success,
    required this.message,
    this.errorCode,
  });

  @override
  String toString() =>
      'LockerResponse(success: $success, message: $message, errorCode: $errorCode)';
}
