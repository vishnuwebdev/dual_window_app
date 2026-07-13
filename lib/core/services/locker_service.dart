import '../api/cvmain_client.dart';
import '../utilities/logging.dart';

class LockerService {
  final CVMainClientService _grpcClient;

  LockerService(this._grpcClient);

  /// Open a compartment
  Future<LockerResult> openCompartment(int compartmentId) async {
    try {
      logger.i('📭 Opening compartment $compartmentId...');
      final response = await _grpcClient.unlockLocker(compartmentId);

      if (response.success) {
        logger.i('✅ Compartment $compartmentId opened successfully');
        return LockerResult(success: true, message: 'Compartment opened');
      } else {
        logger.w('⚠️ Failed to open compartment: ${response.message}');
        return LockerResult(success: false, message: response.message);
      }
    } catch (e) {
      logger.e('❌ Error opening compartment: $e');
      return LockerResult(success: false, message: 'Hardware error: $e');
    }
  }

  /// Close a compartment
  Future<LockerResult> closeCompartment(int compartmentId) async {
    try {
      logger.i('🔒 Closing compartment $compartmentId...');
      final response = await _grpcClient.lockLocker(compartmentId);

      if (response.success) {
        logger.i('✅ Compartment $compartmentId closed successfully');
        return LockerResult(success: true, message: 'Compartment closed');
      } else {
        logger.w('⚠️ Failed to close compartment: ${response.message}');
        return LockerResult(success: false, message: response.message);
      }
    } catch (e) {
      logger.e('❌ Error closing compartment: $e');
      return LockerResult(success: false, message: 'Hardware error: $e');
    }
  }

  /// Check if backend is reachable
  Future<bool> isBackendReachable() async {
    try {
      return await _grpcClient.ping();
    } catch (e) {
      logger.e('Backend unreachable: $e');
      return false;
    }
  }
}

/// Result model for locker operations
class LockerResult {
  final bool success;
  final String message;

  LockerResult({required this.success, required this.message});

  @override
  String toString() => 'LockerResult(success: $success, message: $message)';
}
