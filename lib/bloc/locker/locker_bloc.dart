import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/config/config_service.dart';
import '../../core/services/locker_service.dart';
import '../../core/utilities/logging.dart';
import 'locker_event.dart';
import 'locker_state.dart';

class LockerBloc extends Bloc<LockerEvent, LockerState> {
  final LockerService _lockerService;
  final ConfigService _configService;

  LockerBloc({
    required LockerService lockerService,
    required ConfigService configService,
  })  : _lockerService = lockerService,
        _configService = configService,
        super(const LockerInitial()) {
    on<OpenCompartmentEvent>(_onOpenCompartment);
    on<CloseCompartmentEvent>(_onCloseCompartment);
    on<CheckBackendStatusEvent>(_onCheckBackendStatus);
    on<UpdateLockerAddressEvent>(_onUpdateLockerAddress);
  }

  Future<void> _onOpenCompartment(
    OpenCompartmentEvent event,
    Emitter<LockerState> emit,
  ) async {
    emit(const LockerLoading(message: 'Opening compartment...'));
    
    try {
      final result = await _lockerService.openCompartment(event.compartmentId);
      
      if (result.success) {
        emit(LockerSuccess(
          message: result.message,
          isOpen: true,
          compartmentId: event.compartmentId,
        ));
      } else {
        emit(LockerError(
          message: result.message,
          compartmentId: event.compartmentId,
        ));
      }
    } catch (e) {
      logger.e('Error in _onOpenCompartment: $e');
      emit(LockerError(
        message: 'Unexpected error: $e',
        compartmentId: event.compartmentId,
      ));
    }
  }

  Future<void> _onCloseCompartment(
    CloseCompartmentEvent event,
    Emitter<LockerState> emit,
  ) async {
    emit(const LockerLoading(message: 'Closing compartment...'));
    
    try {
      final result = await _lockerService.closeCompartment(event.compartmentId);
      
      if (result.success) {
        emit(LockerSuccess(
          message: result.message,
          isOpen: false,
          compartmentId: event.compartmentId,
        ));
      } else {
        emit(LockerError(
          message: result.message,
          compartmentId: event.compartmentId,
        ));
      }
    } catch (e) {
      logger.e('Error in _onCloseCompartment: $e');
      emit(LockerError(
        message: 'Unexpected error: $e',
        compartmentId: event.compartmentId,
      ));
    }
  }

  Future<void> _onCheckBackendStatus(
    CheckBackendStatusEvent event,
    Emitter<LockerState> emit,
  ) async {
    try {
      final isOnline = await _lockerService.isBackendReachable();
      
      if (isOnline) {
        emit(const BackendOnline('1.0.0'));
      } else {
        emit(const BackendOffline());
      }
    } catch (e) {
      logger.e('Error checking backend status: $e');
      emit(const BackendOffline());
    }
  }

  Future<void> _onUpdateLockerAddress(
    UpdateLockerAddressEvent event,
    Emitter<LockerState> emit,
  ) async {
    try {
      await _configService.setLockerAddress(event.address);
      emit(LockerSuccess(
        message: 'Locker address updated to ${event.address}',
      ));
    } catch (e) {
      logger.e('Error updating locker address: $e');
      emit(LockerError(message: 'Failed to update address: $e'));
    }
  }
}
