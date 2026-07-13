import 'package:equatable/equatable.dart';

abstract class LockerState extends Equatable {
  const LockerState();

  @override
  List<Object?> get props => [];
}

class LockerInitial extends LockerState {
  const LockerInitial();
}

class LockerLoading extends LockerState {
  final String message;

  const LockerLoading({this.message = 'Processing...'});

  @override
  List<Object?> get props => [message];
}

class LockerSuccess extends LockerState {
  final String message;
  final bool isOpen;
  final int? compartmentId;

  const LockerSuccess({
    required this.message,
    this.isOpen = false,
    this.compartmentId,
  });

  @override
  List<Object?> get props => [message, isOpen, compartmentId];
}

class LockerError extends LockerState {
  final String message;
  final int? compartmentId;

  const LockerError({required this.message, this.compartmentId});

  @override
  List<Object?> get props => [message, compartmentId];
}

class BackendOnline extends LockerState {
  final String version;

  const BackendOnline(this.version);

  @override
  List<Object?> get props => [version];
}

class BackendOffline extends LockerState {
  const BackendOffline();
}
