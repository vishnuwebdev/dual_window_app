import 'package:equatable/equatable.dart';

abstract class LockerEvent extends Equatable {
  const LockerEvent();

  @override
  List<Object?> get props => [];
}

class OpenCompartmentEvent extends LockerEvent {
  final int compartmentId;

  const OpenCompartmentEvent(this.compartmentId);

  @override
  List<Object?> get props => [compartmentId];
}

class CloseCompartmentEvent extends LockerEvent {
  final int compartmentId;

  const CloseCompartmentEvent(this.compartmentId);

  @override
  List<Object?> get props => [compartmentId];
}

class CheckBackendStatusEvent extends LockerEvent {
  const CheckBackendStatusEvent();
}

class UpdateLockerAddressEvent extends LockerEvent {
  final String address;

  const UpdateLockerAddressEvent(this.address);

  @override
  List<Object?> get props => [address];
}
