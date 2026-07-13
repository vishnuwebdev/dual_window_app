// This is a generated file - do not edit.
//
// Generated from service.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:async' as $async;
import 'dart:core' as $core;

import 'package:grpc/service_api.dart' as $grpc;
import 'package:protobuf/protobuf.dart' as $pb;
import 'package:protobuf/well_known_types/google/protobuf/empty.pb.dart' as $0;

import 'service.pb.dart' as $1;

export 'service.pb.dart';

@$pb.GrpcServiceName('cv_saas.CommsService')
class CommsServiceClient extends $grpc.Client {
  /// The hostname for this service.
  static const $core.String defaultHost = '';

  /// OAuth scopes needed for the client.
  static const $core.List<$core.String> oauthScopes = [
    '',
  ];

  CommsServiceClient(super.channel, {super.options, super.interceptors});

  /// gets software version number
  $grpc.ResponseFuture<$1.GetVersionResponse> get_version(
    $0.Empty request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$get_version, request, options: options);
  }

  /// turns buzzer on for a user specified duration
  $grpc.ResponseFuture<$1.GeneralResponse> toggle_buzzer(
    $1.ToggleBuzzerRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$toggle_buzzer, request, options: options);
  }

  /// locks the specified locker
  $grpc.ResponseFuture<$1.GeneralResponse> lock_locker(
    $1.LockRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$lock_locker, request, options: options);
  }

  /// unlocks the specified locker
  $grpc.ResponseFuture<$1.GeneralResponse> unlock_locker(
    $1.LockRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$unlock_locker, request, options: options);
  }

  /// retrieves the date and time from the device
  $grpc.ResponseFuture<$1.GetRtcResponse> get_rtc(
    $0.Empty request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$get_rtc, request, options: options);
  }

  /// sets the date and time on the device. Note that this is periodically synced
  /// automatically to UTC, so it is not recommended this endpoint be used directly
  $grpc.ResponseFuture<$1.GeneralResponse> set_rtc(
    $1.SetRtcRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$set_rtc, request, options: options);
  }

  /// the the entire LCD screen. This is for the LCD screen connected to the master board only.
  $grpc.ResponseFuture<$1.GeneralResponse> lcd_clear_screen(
    $0.Empty request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$lcd_clear_screen, request, options: options);
  }

  /// clears the specified line of the LCD screen. This is for the LCD screen connected to the master board only.
  $grpc.ResponseFuture<$1.GeneralResponse> lcd_clear_line(
    $1.LcdClearLineRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$lcd_clear_line, request, options: options);
  }

  /// writes some data to the LCD screen. This is for the LCD screen connected to the master board only.
  $grpc.ResponseFuture<$1.GeneralResponse> lcd_write_data(
    $1.LcdWriteDataRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$lcd_write_data, request, options: options);
  }

  /// retrieves the mapping for the unit
  $grpc.ResponseFuture<$1.GetLockerMapResponse> get_locker_map(
    $0.Empty request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$get_locker_map, request, options: options);
  }

  /// Triggers a duress as per the user's request. For instance, the user may enter a special code on the
  /// keypad to have this duress triggered. The underlying action is hardware specific. For instance, on a
  /// RPI, this typically activates a GPIO pin. The hardware specific integration is handled by a different
  /// application via an integration layer and can be made to do just about anything (eg. we could send a
  /// message to a rabbit server or call a webhook or something if that's required)
  $grpc.ResponseFuture<$1.GeneralResponse> trigger_user_duress(
    $0.Empty request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$trigger_user_duress, request, options: options);
  }

  /// Allows higher level user applications to take advantage of the vaultgroup auditing facility.
  /// User log messages will be mixed in which vaultgroup messages, but in a private code range allowing
  /// for easy filtering. It is not required that this endpoint be used. User's are free to have their own
  /// logging facilities independent of VG.
  $grpc.ResponseFuture<$1.GeneralResponse> user_audit(
    $1.UserAuditLogRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$user_audit, request, options: options);
  }

  /// Submits an SMS for transmission. This will be transmitted via the VG server
  $grpc.ResponseFuture<$1.GeneralResponse> send_sms(
    $1.SendSmsRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$send_sms, request, options: options);
  }

  /// retrieves the authentication token used to log in to VG services
  $grpc.ResponseFuture<$1.GetAuthTokenResponse> get_auth_token(
    $0.Empty request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$get_auth_token, request, options: options);
  }

  /// a command to set the state on slave boards running dsv or similar firmware.
  /// this command is NOT available on regular slaves. dsv slaves included modified
  /// logic such that the door lock button can be used as a door open+lock button to
  /// repeatedly access a locker without further keypad input from the user. On
  /// completion of this cycle, the user cancels the operation from something like
  /// the keypad.
  $grpc.ResponseFuture<$1.GeneralResponse> set_locker_state(
    $1.SetLockerStateRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$set_locker_state, request, options: options);
  }

  /// a simple endpoint that can be called to see if the server is operational
  $grpc.ResponseFuture<$1.GeneralResponse> ping(
    $0.Empty request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$ping, request, options: options);
  }

  /// returns the states for every door (open/close based on the door switch) and
  /// lock (locked/unlocked)
  $grpc.ResponseFuture<$1.GetLockerStatesResponse> get_locker_states(
    $0.Empty request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$get_locker_states, request, options: options);
  }

  /// returns the version number for each slave board. The system will
  /// not start if the wrong slaves and/or locks have been configured
  $grpc.ResponseFuture<$1.GetSlaveFirmwareResponse> get_slave_firmware(
    $0.Empty request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$get_slave_firmware, request, options: options);
  }

  $grpc.ResponseFuture<$1.GeneralResponse> set_led(
    $1.SetLedMessage request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$set_led, request, options: options);
  }

  /// reboots the entire system. For the reboot to work, a valid code must be provided.
  /// the reboot is handled by an external application/script. That script validates
  /// the code
  $grpc.ResponseFuture<$1.GeneralResponse> reboot(
    $1.RebootRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$reboot, request, options: options);
  }

  /// retrieves the version of the grpc protocol. Can be used to determine which
  /// functions are available. Available as of 1.0.1
  $grpc.ResponseFuture<$1.GetProtocolVersionResponse> get_protocol_version(
    $0.Empty request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$get_protocol_version, request, options: options);
  }

  /// Used to register an mqtt integration by an external app. Available as of
  /// 1.0.2
  $grpc.ResponseFuture<$1.RegisterMqttIntegrationResponse>
      register_mqtt_integration(
    $1.RegisterMqttIntegrationRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$register_mqtt_integration, request,
        options: options);
  }

  /// Used to unregister an mqtt integration by an external app. Available as of
  /// 1.0.2
  $grpc.ResponseFuture<$1.RegisterMqttIntegrationResponse>
      unregister_mqtt_integration(
    $1.UnregisterMqttIntegrationRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$unregister_mqtt_integration, request,
        options: options);
  }

  /// allows a third party app to send a non-vg notification message.
  $grpc.ResponseFuture<$1.BasicResponse> send_notification(
    $1.NotificationMessageRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$send_notification, request, options: options);
  }

  // method descriptors

  static final _$get_version =
      $grpc.ClientMethod<$0.Empty, $1.GetVersionResponse>(
          '/cv_saas.CommsService/get_version',
          ($0.Empty value) => value.writeToBuffer(),
          $1.GetVersionResponse.fromBuffer);
  static final _$toggle_buzzer =
      $grpc.ClientMethod<$1.ToggleBuzzerRequest, $1.GeneralResponse>(
          '/cv_saas.CommsService/toggle_buzzer',
          ($1.ToggleBuzzerRequest value) => value.writeToBuffer(),
          $1.GeneralResponse.fromBuffer);
  static final _$lock_locker =
      $grpc.ClientMethod<$1.LockRequest, $1.GeneralResponse>(
          '/cv_saas.CommsService/lock_locker',
          ($1.LockRequest value) => value.writeToBuffer(),
          $1.GeneralResponse.fromBuffer);
  static final _$unlock_locker =
      $grpc.ClientMethod<$1.LockRequest, $1.GeneralResponse>(
          '/cv_saas.CommsService/unlock_locker',
          ($1.LockRequest value) => value.writeToBuffer(),
          $1.GeneralResponse.fromBuffer);
  static final _$get_rtc = $grpc.ClientMethod<$0.Empty, $1.GetRtcResponse>(
      '/cv_saas.CommsService/get_rtc',
      ($0.Empty value) => value.writeToBuffer(),
      $1.GetRtcResponse.fromBuffer);
  static final _$set_rtc =
      $grpc.ClientMethod<$1.SetRtcRequest, $1.GeneralResponse>(
          '/cv_saas.CommsService/set_rtc',
          ($1.SetRtcRequest value) => value.writeToBuffer(),
          $1.GeneralResponse.fromBuffer);
  static final _$lcd_clear_screen =
      $grpc.ClientMethod<$0.Empty, $1.GeneralResponse>(
          '/cv_saas.CommsService/lcd_clear_screen',
          ($0.Empty value) => value.writeToBuffer(),
          $1.GeneralResponse.fromBuffer);
  static final _$lcd_clear_line =
      $grpc.ClientMethod<$1.LcdClearLineRequest, $1.GeneralResponse>(
          '/cv_saas.CommsService/lcd_clear_line',
          ($1.LcdClearLineRequest value) => value.writeToBuffer(),
          $1.GeneralResponse.fromBuffer);
  static final _$lcd_write_data =
      $grpc.ClientMethod<$1.LcdWriteDataRequest, $1.GeneralResponse>(
          '/cv_saas.CommsService/lcd_write_data',
          ($1.LcdWriteDataRequest value) => value.writeToBuffer(),
          $1.GeneralResponse.fromBuffer);
  static final _$get_locker_map =
      $grpc.ClientMethod<$0.Empty, $1.GetLockerMapResponse>(
          '/cv_saas.CommsService/get_locker_map',
          ($0.Empty value) => value.writeToBuffer(),
          $1.GetLockerMapResponse.fromBuffer);
  static final _$trigger_user_duress =
      $grpc.ClientMethod<$0.Empty, $1.GeneralResponse>(
          '/cv_saas.CommsService/trigger_user_duress',
          ($0.Empty value) => value.writeToBuffer(),
          $1.GeneralResponse.fromBuffer);
  static final _$user_audit =
      $grpc.ClientMethod<$1.UserAuditLogRequest, $1.GeneralResponse>(
          '/cv_saas.CommsService/user_audit',
          ($1.UserAuditLogRequest value) => value.writeToBuffer(),
          $1.GeneralResponse.fromBuffer);
  static final _$send_sms =
      $grpc.ClientMethod<$1.SendSmsRequest, $1.GeneralResponse>(
          '/cv_saas.CommsService/send_sms',
          ($1.SendSmsRequest value) => value.writeToBuffer(),
          $1.GeneralResponse.fromBuffer);
  static final _$get_auth_token =
      $grpc.ClientMethod<$0.Empty, $1.GetAuthTokenResponse>(
          '/cv_saas.CommsService/get_auth_token',
          ($0.Empty value) => value.writeToBuffer(),
          $1.GetAuthTokenResponse.fromBuffer);
  static final _$set_locker_state =
      $grpc.ClientMethod<$1.SetLockerStateRequest, $1.GeneralResponse>(
          '/cv_saas.CommsService/set_locker_state',
          ($1.SetLockerStateRequest value) => value.writeToBuffer(),
          $1.GeneralResponse.fromBuffer);
  static final _$ping = $grpc.ClientMethod<$0.Empty, $1.GeneralResponse>(
      '/cv_saas.CommsService/ping',
      ($0.Empty value) => value.writeToBuffer(),
      $1.GeneralResponse.fromBuffer);
  static final _$get_locker_states =
      $grpc.ClientMethod<$0.Empty, $1.GetLockerStatesResponse>(
          '/cv_saas.CommsService/get_locker_states',
          ($0.Empty value) => value.writeToBuffer(),
          $1.GetLockerStatesResponse.fromBuffer);
  static final _$get_slave_firmware =
      $grpc.ClientMethod<$0.Empty, $1.GetSlaveFirmwareResponse>(
          '/cv_saas.CommsService/get_slave_firmware',
          ($0.Empty value) => value.writeToBuffer(),
          $1.GetSlaveFirmwareResponse.fromBuffer);
  static final _$set_led =
      $grpc.ClientMethod<$1.SetLedMessage, $1.GeneralResponse>(
          '/cv_saas.CommsService/set_led',
          ($1.SetLedMessage value) => value.writeToBuffer(),
          $1.GeneralResponse.fromBuffer);
  static final _$reboot =
      $grpc.ClientMethod<$1.RebootRequest, $1.GeneralResponse>(
          '/cv_saas.CommsService/reboot',
          ($1.RebootRequest value) => value.writeToBuffer(),
          $1.GeneralResponse.fromBuffer);
  static final _$get_protocol_version =
      $grpc.ClientMethod<$0.Empty, $1.GetProtocolVersionResponse>(
          '/cv_saas.CommsService/get_protocol_version',
          ($0.Empty value) => value.writeToBuffer(),
          $1.GetProtocolVersionResponse.fromBuffer);
  static final _$register_mqtt_integration = $grpc.ClientMethod<
          $1.RegisterMqttIntegrationRequest,
          $1.RegisterMqttIntegrationResponse>(
      '/cv_saas.CommsService/register_mqtt_integration',
      ($1.RegisterMqttIntegrationRequest value) => value.writeToBuffer(),
      $1.RegisterMqttIntegrationResponse.fromBuffer);
  static final _$unregister_mqtt_integration = $grpc.ClientMethod<
          $1.UnregisterMqttIntegrationRequest,
          $1.RegisterMqttIntegrationResponse>(
      '/cv_saas.CommsService/unregister_mqtt_integration',
      ($1.UnregisterMqttIntegrationRequest value) => value.writeToBuffer(),
      $1.RegisterMqttIntegrationResponse.fromBuffer);
  static final _$send_notification =
      $grpc.ClientMethod<$1.NotificationMessageRequest, $1.BasicResponse>(
          '/cv_saas.CommsService/send_notification',
          ($1.NotificationMessageRequest value) => value.writeToBuffer(),
          $1.BasicResponse.fromBuffer);
}

@$pb.GrpcServiceName('cv_saas.CommsService')
abstract class CommsServiceBase extends $grpc.Service {
  $core.String get $name => 'cv_saas.CommsService';

  CommsServiceBase() {
    $addMethod($grpc.ServiceMethod<$0.Empty, $1.GetVersionResponse>(
        'get_version',
        get_version_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.Empty.fromBuffer(value),
        ($1.GetVersionResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$1.ToggleBuzzerRequest, $1.GeneralResponse>(
        'toggle_buzzer',
        toggle_buzzer_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $1.ToggleBuzzerRequest.fromBuffer(value),
        ($1.GeneralResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$1.LockRequest, $1.GeneralResponse>(
        'lock_locker',
        lock_locker_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $1.LockRequest.fromBuffer(value),
        ($1.GeneralResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$1.LockRequest, $1.GeneralResponse>(
        'unlock_locker',
        unlock_locker_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $1.LockRequest.fromBuffer(value),
        ($1.GeneralResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.Empty, $1.GetRtcResponse>(
        'get_rtc',
        get_rtc_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.Empty.fromBuffer(value),
        ($1.GetRtcResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$1.SetRtcRequest, $1.GeneralResponse>(
        'set_rtc',
        set_rtc_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $1.SetRtcRequest.fromBuffer(value),
        ($1.GeneralResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.Empty, $1.GeneralResponse>(
        'lcd_clear_screen',
        lcd_clear_screen_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.Empty.fromBuffer(value),
        ($1.GeneralResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$1.LcdClearLineRequest, $1.GeneralResponse>(
        'lcd_clear_line',
        lcd_clear_line_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $1.LcdClearLineRequest.fromBuffer(value),
        ($1.GeneralResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$1.LcdWriteDataRequest, $1.GeneralResponse>(
        'lcd_write_data',
        lcd_write_data_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $1.LcdWriteDataRequest.fromBuffer(value),
        ($1.GeneralResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.Empty, $1.GetLockerMapResponse>(
        'get_locker_map',
        get_locker_map_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.Empty.fromBuffer(value),
        ($1.GetLockerMapResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.Empty, $1.GeneralResponse>(
        'trigger_user_duress',
        trigger_user_duress_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.Empty.fromBuffer(value),
        ($1.GeneralResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$1.UserAuditLogRequest, $1.GeneralResponse>(
        'user_audit',
        user_audit_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $1.UserAuditLogRequest.fromBuffer(value),
        ($1.GeneralResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$1.SendSmsRequest, $1.GeneralResponse>(
        'send_sms',
        send_sms_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $1.SendSmsRequest.fromBuffer(value),
        ($1.GeneralResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.Empty, $1.GetAuthTokenResponse>(
        'get_auth_token',
        get_auth_token_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.Empty.fromBuffer(value),
        ($1.GetAuthTokenResponse value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$1.SetLockerStateRequest, $1.GeneralResponse>(
            'set_locker_state',
            set_locker_state_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $1.SetLockerStateRequest.fromBuffer(value),
            ($1.GeneralResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.Empty, $1.GeneralResponse>(
        'ping',
        ping_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.Empty.fromBuffer(value),
        ($1.GeneralResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.Empty, $1.GetLockerStatesResponse>(
        'get_locker_states',
        get_locker_states_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.Empty.fromBuffer(value),
        ($1.GetLockerStatesResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.Empty, $1.GetSlaveFirmwareResponse>(
        'get_slave_firmware',
        get_slave_firmware_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.Empty.fromBuffer(value),
        ($1.GetSlaveFirmwareResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$1.SetLedMessage, $1.GeneralResponse>(
        'set_led',
        set_led_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $1.SetLedMessage.fromBuffer(value),
        ($1.GeneralResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$1.RebootRequest, $1.GeneralResponse>(
        'reboot',
        reboot_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $1.RebootRequest.fromBuffer(value),
        ($1.GeneralResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.Empty, $1.GetProtocolVersionResponse>(
        'get_protocol_version',
        get_protocol_version_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.Empty.fromBuffer(value),
        ($1.GetProtocolVersionResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$1.RegisterMqttIntegrationRequest,
            $1.RegisterMqttIntegrationResponse>(
        'register_mqtt_integration',
        register_mqtt_integration_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $1.RegisterMqttIntegrationRequest.fromBuffer(value),
        ($1.RegisterMqttIntegrationResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$1.UnregisterMqttIntegrationRequest,
            $1.RegisterMqttIntegrationResponse>(
        'unregister_mqtt_integration',
        unregister_mqtt_integration_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $1.UnregisterMqttIntegrationRequest.fromBuffer(value),
        ($1.RegisterMqttIntegrationResponse value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$1.NotificationMessageRequest, $1.BasicResponse>(
            'send_notification',
            send_notification_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $1.NotificationMessageRequest.fromBuffer(value),
            ($1.BasicResponse value) => value.writeToBuffer()));
  }

  $async.Future<$1.GetVersionResponse> get_version_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.Empty> $request) async {
    return get_version($call, await $request);
  }

  $async.Future<$1.GetVersionResponse> get_version(
      $grpc.ServiceCall call, $0.Empty request);

  $async.Future<$1.GeneralResponse> toggle_buzzer_Pre($grpc.ServiceCall $call,
      $async.Future<$1.ToggleBuzzerRequest> $request) async {
    return toggle_buzzer($call, await $request);
  }

  $async.Future<$1.GeneralResponse> toggle_buzzer(
      $grpc.ServiceCall call, $1.ToggleBuzzerRequest request);

  $async.Future<$1.GeneralResponse> lock_locker_Pre(
      $grpc.ServiceCall $call, $async.Future<$1.LockRequest> $request) async {
    return lock_locker($call, await $request);
  }

  $async.Future<$1.GeneralResponse> lock_locker(
      $grpc.ServiceCall call, $1.LockRequest request);

  $async.Future<$1.GeneralResponse> unlock_locker_Pre(
      $grpc.ServiceCall $call, $async.Future<$1.LockRequest> $request) async {
    return unlock_locker($call, await $request);
  }

  $async.Future<$1.GeneralResponse> unlock_locker(
      $grpc.ServiceCall call, $1.LockRequest request);

  $async.Future<$1.GetRtcResponse> get_rtc_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.Empty> $request) async {
    return get_rtc($call, await $request);
  }

  $async.Future<$1.GetRtcResponse> get_rtc(
      $grpc.ServiceCall call, $0.Empty request);

  $async.Future<$1.GeneralResponse> set_rtc_Pre(
      $grpc.ServiceCall $call, $async.Future<$1.SetRtcRequest> $request) async {
    return set_rtc($call, await $request);
  }

  $async.Future<$1.GeneralResponse> set_rtc(
      $grpc.ServiceCall call, $1.SetRtcRequest request);

  $async.Future<$1.GeneralResponse> lcd_clear_screen_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.Empty> $request) async {
    return lcd_clear_screen($call, await $request);
  }

  $async.Future<$1.GeneralResponse> lcd_clear_screen(
      $grpc.ServiceCall call, $0.Empty request);

  $async.Future<$1.GeneralResponse> lcd_clear_line_Pre($grpc.ServiceCall $call,
      $async.Future<$1.LcdClearLineRequest> $request) async {
    return lcd_clear_line($call, await $request);
  }

  $async.Future<$1.GeneralResponse> lcd_clear_line(
      $grpc.ServiceCall call, $1.LcdClearLineRequest request);

  $async.Future<$1.GeneralResponse> lcd_write_data_Pre($grpc.ServiceCall $call,
      $async.Future<$1.LcdWriteDataRequest> $request) async {
    return lcd_write_data($call, await $request);
  }

  $async.Future<$1.GeneralResponse> lcd_write_data(
      $grpc.ServiceCall call, $1.LcdWriteDataRequest request);

  $async.Future<$1.GetLockerMapResponse> get_locker_map_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.Empty> $request) async {
    return get_locker_map($call, await $request);
  }

  $async.Future<$1.GetLockerMapResponse> get_locker_map(
      $grpc.ServiceCall call, $0.Empty request);

  $async.Future<$1.GeneralResponse> trigger_user_duress_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.Empty> $request) async {
    return trigger_user_duress($call, await $request);
  }

  $async.Future<$1.GeneralResponse> trigger_user_duress(
      $grpc.ServiceCall call, $0.Empty request);

  $async.Future<$1.GeneralResponse> user_audit_Pre($grpc.ServiceCall $call,
      $async.Future<$1.UserAuditLogRequest> $request) async {
    return user_audit($call, await $request);
  }

  $async.Future<$1.GeneralResponse> user_audit(
      $grpc.ServiceCall call, $1.UserAuditLogRequest request);

  $async.Future<$1.GeneralResponse> send_sms_Pre($grpc.ServiceCall $call,
      $async.Future<$1.SendSmsRequest> $request) async {
    return send_sms($call, await $request);
  }

  $async.Future<$1.GeneralResponse> send_sms(
      $grpc.ServiceCall call, $1.SendSmsRequest request);

  $async.Future<$1.GetAuthTokenResponse> get_auth_token_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.Empty> $request) async {
    return get_auth_token($call, await $request);
  }

  $async.Future<$1.GetAuthTokenResponse> get_auth_token(
      $grpc.ServiceCall call, $0.Empty request);

  $async.Future<$1.GeneralResponse> set_locker_state_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$1.SetLockerStateRequest> $request) async {
    return set_locker_state($call, await $request);
  }

  $async.Future<$1.GeneralResponse> set_locker_state(
      $grpc.ServiceCall call, $1.SetLockerStateRequest request);

  $async.Future<$1.GeneralResponse> ping_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.Empty> $request) async {
    return ping($call, await $request);
  }

  $async.Future<$1.GeneralResponse> ping(
      $grpc.ServiceCall call, $0.Empty request);

  $async.Future<$1.GetLockerStatesResponse> get_locker_states_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.Empty> $request) async {
    return get_locker_states($call, await $request);
  }

  $async.Future<$1.GetLockerStatesResponse> get_locker_states(
      $grpc.ServiceCall call, $0.Empty request);

  $async.Future<$1.GetSlaveFirmwareResponse> get_slave_firmware_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.Empty> $request) async {
    return get_slave_firmware($call, await $request);
  }

  $async.Future<$1.GetSlaveFirmwareResponse> get_slave_firmware(
      $grpc.ServiceCall call, $0.Empty request);

  $async.Future<$1.GeneralResponse> set_led_Pre(
      $grpc.ServiceCall $call, $async.Future<$1.SetLedMessage> $request) async {
    return set_led($call, await $request);
  }

  $async.Future<$1.GeneralResponse> set_led(
      $grpc.ServiceCall call, $1.SetLedMessage request);

  $async.Future<$1.GeneralResponse> reboot_Pre(
      $grpc.ServiceCall $call, $async.Future<$1.RebootRequest> $request) async {
    return reboot($call, await $request);
  }

  $async.Future<$1.GeneralResponse> reboot(
      $grpc.ServiceCall call, $1.RebootRequest request);

  $async.Future<$1.GetProtocolVersionResponse> get_protocol_version_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.Empty> $request) async {
    return get_protocol_version($call, await $request);
  }

  $async.Future<$1.GetProtocolVersionResponse> get_protocol_version(
      $grpc.ServiceCall call, $0.Empty request);

  $async.Future<$1.RegisterMqttIntegrationResponse>
      register_mqtt_integration_Pre($grpc.ServiceCall $call,
          $async.Future<$1.RegisterMqttIntegrationRequest> $request) async {
    return register_mqtt_integration($call, await $request);
  }

  $async.Future<$1.RegisterMqttIntegrationResponse> register_mqtt_integration(
      $grpc.ServiceCall call, $1.RegisterMqttIntegrationRequest request);

  $async.Future<$1.RegisterMqttIntegrationResponse>
      unregister_mqtt_integration_Pre($grpc.ServiceCall $call,
          $async.Future<$1.UnregisterMqttIntegrationRequest> $request) async {
    return unregister_mqtt_integration($call, await $request);
  }

  $async.Future<$1.RegisterMqttIntegrationResponse> unregister_mqtt_integration(
      $grpc.ServiceCall call, $1.UnregisterMqttIntegrationRequest request);

  $async.Future<$1.BasicResponse> send_notification_Pre($grpc.ServiceCall $call,
      $async.Future<$1.NotificationMessageRequest> $request) async {
    return send_notification($call, await $request);
  }

  $async.Future<$1.BasicResponse> send_notification(
      $grpc.ServiceCall call, $1.NotificationMessageRequest request);
}
