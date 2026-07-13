// This is a generated file - do not edit.
//
// Generated from service.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports
// ignore_for_file: unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use basicResponseDescriptor instead')
const BasicResponse$json = {
  '1': 'BasicResponse',
  '2': [
    {'1': 'success', '3': 1, '4': 1, '5': 8, '10': 'success'},
    {'1': 'errMsg', '3': 2, '4': 1, '5': 9, '10': 'errMsg'},
    {'1': 'code', '3': 3, '4': 1, '5': 5, '10': 'code'},
  ],
};

/// Descriptor for `BasicResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List basicResponseDescriptor = $convert.base64Decode(
    'Cg1CYXNpY1Jlc3BvbnNlEhgKB3N1Y2Nlc3MYASABKAhSB3N1Y2Nlc3MSFgoGZXJyTXNnGAIgAS'
    'gJUgZlcnJNc2cSEgoEY29kZRgDIAEoBVIEY29kZQ==');

@$core.Deprecated('Use generalResponseDescriptor instead')
const GeneralResponse$json = {
  '1': 'GeneralResponse',
  '2': [
    {
      '1': 'resp',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.cv_saas.BasicResponse',
      '10': 'resp'
    },
  ],
};

/// Descriptor for `GeneralResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List generalResponseDescriptor = $convert.base64Decode(
    'Cg9HZW5lcmFsUmVzcG9uc2USKgoEcmVzcBgBIAEoCzIWLmN2X3NhYXMuQmFzaWNSZXNwb25zZV'
    'IEcmVzcA==');

@$core.Deprecated('Use getVersionResponseDescriptor instead')
const GetVersionResponse$json = {
  '1': 'GetVersionResponse',
  '2': [
    {
      '1': 'resp',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.cv_saas.BasicResponse',
      '10': 'resp'
    },
    {'1': 'version', '3': 2, '4': 1, '5': 9, '10': 'version'},
  ],
};

/// Descriptor for `GetVersionResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getVersionResponseDescriptor = $convert.base64Decode(
    'ChJHZXRWZXJzaW9uUmVzcG9uc2USKgoEcmVzcBgBIAEoCzIWLmN2X3NhYXMuQmFzaWNSZXNwb2'
    '5zZVIEcmVzcBIYCgd2ZXJzaW9uGAIgASgJUgd2ZXJzaW9u');

@$core.Deprecated('Use getLockerMapResponseDescriptor instead')
const GetLockerMapResponse$json = {
  '1': 'GetLockerMapResponse',
  '2': [
    {
      '1': 'resp',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.cv_saas.BasicResponse',
      '10': 'resp'
    },
    {'1': 'lockers', '3': 2, '4': 3, '5': 13, '10': 'lockers'},
    {'1': 'num_lockers', '3': 3, '4': 1, '5': 13, '10': 'numLockers'},
  ],
};

/// Descriptor for `GetLockerMapResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getLockerMapResponseDescriptor = $convert.base64Decode(
    'ChRHZXRMb2NrZXJNYXBSZXNwb25zZRIqCgRyZXNwGAEgASgLMhYuY3Zfc2Fhcy5CYXNpY1Jlc3'
    'BvbnNlUgRyZXNwEhgKB2xvY2tlcnMYAiADKA1SB2xvY2tlcnMSHwoLbnVtX2xvY2tlcnMYAyAB'
    'KA1SCm51bUxvY2tlcnM=');

@$core.Deprecated('Use toggleBuzzerRequestDescriptor instead')
const ToggleBuzzerRequest$json = {
  '1': 'ToggleBuzzerRequest',
  '2': [
    {'1': 'duration_millis', '3': 1, '4': 1, '5': 13, '10': 'durationMillis'},
  ],
};

/// Descriptor for `ToggleBuzzerRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List toggleBuzzerRequestDescriptor = $convert.base64Decode(
    'ChNUb2dnbGVCdXp6ZXJSZXF1ZXN0EicKD2R1cmF0aW9uX21pbGxpcxgBIAEoDVIOZHVyYXRpb2'
    '5NaWxsaXM=');

@$core.Deprecated('Use lockRequestDescriptor instead')
const LockRequest$json = {
  '1': 'LockRequest',
  '2': [
    {'1': 'locker_num', '3': 1, '4': 1, '5': 13, '10': 'lockerNum'},
  ],
};

/// Descriptor for `LockRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List lockRequestDescriptor = $convert.base64Decode(
    'CgtMb2NrUmVxdWVzdBIdCgpsb2NrZXJfbnVtGAEgASgNUglsb2NrZXJOdW0=');

@$core.Deprecated('Use getRtcResponseDescriptor instead')
const GetRtcResponse$json = {
  '1': 'GetRtcResponse',
  '2': [
    {
      '1': 'resp',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.cv_saas.BasicResponse',
      '10': 'resp'
    },
    {'1': 'datetime', '3': 2, '4': 1, '5': 9, '10': 'datetime'},
  ],
};

/// Descriptor for `GetRtcResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getRtcResponseDescriptor = $convert.base64Decode(
    'Cg5HZXRSdGNSZXNwb25zZRIqCgRyZXNwGAEgASgLMhYuY3Zfc2Fhcy5CYXNpY1Jlc3BvbnNlUg'
    'RyZXNwEhoKCGRhdGV0aW1lGAIgASgJUghkYXRldGltZQ==');

@$core.Deprecated('Use setRtcRequestDescriptor instead')
const SetRtcRequest$json = {
  '1': 'SetRtcRequest',
  '2': [
    {'1': 'datetime', '3': 1, '4': 1, '5': 9, '10': 'datetime'},
  ],
};

/// Descriptor for `SetRtcRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List setRtcRequestDescriptor = $convert.base64Decode(
    'Cg1TZXRSdGNSZXF1ZXN0EhoKCGRhdGV0aW1lGAEgASgJUghkYXRldGltZQ==');

@$core.Deprecated('Use lcdClearLineRequestDescriptor instead')
const LcdClearLineRequest$json = {
  '1': 'LcdClearLineRequest',
  '2': [
    {'1': 'line_num', '3': 1, '4': 1, '5': 13, '10': 'lineNum'},
  ],
};

/// Descriptor for `LcdClearLineRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List lcdClearLineRequestDescriptor =
    $convert.base64Decode(
        'ChNMY2RDbGVhckxpbmVSZXF1ZXN0EhkKCGxpbmVfbnVtGAEgASgNUgdsaW5lTnVt');

@$core.Deprecated('Use lcdWriteDataRequestDescriptor instead')
const LcdWriteDataRequest$json = {
  '1': 'LcdWriteDataRequest',
  '2': [
    {'1': 'row', '3': 1, '4': 1, '5': 13, '10': 'row'},
    {'1': 'col', '3': 2, '4': 1, '5': 5, '10': 'col'},
    {'1': 'text', '3': 3, '4': 1, '5': 9, '10': 'text'},
  ],
};

/// Descriptor for `LcdWriteDataRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List lcdWriteDataRequestDescriptor = $convert.base64Decode(
    'ChNMY2RXcml0ZURhdGFSZXF1ZXN0EhAKA3JvdxgBIAEoDVIDcm93EhAKA2NvbBgCIAEoBVIDY2'
    '9sEhIKBHRleHQYAyABKAlSBHRleHQ=');

@$core.Deprecated('Use userAuditLogRequestDescriptor instead')
const UserAuditLogRequest$json = {
  '1': 'UserAuditLogRequest',
  '2': [
    {'1': 'version', '3': 1, '4': 1, '5': 13, '10': 'version'},
    {'1': 'code', '3': 2, '4': 1, '5': 13, '10': 'code'},
    {'1': 'level', '3': 3, '4': 1, '5': 9, '10': 'level'},
    {'1': 'description', '3': 4, '4': 1, '5': 9, '10': 'description'},
    {'1': 'priority', '3': 5, '4': 1, '5': 9, '10': 'priority'},
    {'1': 'app', '3': 6, '4': 1, '5': 9, '10': 'app'},
    {'1': 'parameters_json', '3': 7, '4': 1, '5': 9, '10': 'parametersJson'},
  ],
};

/// Descriptor for `UserAuditLogRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List userAuditLogRequestDescriptor = $convert.base64Decode(
    'ChNVc2VyQXVkaXRMb2dSZXF1ZXN0EhgKB3ZlcnNpb24YASABKA1SB3ZlcnNpb24SEgoEY29kZR'
    'gCIAEoDVIEY29kZRIUCgVsZXZlbBgDIAEoCVIFbGV2ZWwSIAoLZGVzY3JpcHRpb24YBCABKAlS'
    'C2Rlc2NyaXB0aW9uEhoKCHByaW9yaXR5GAUgASgJUghwcmlvcml0eRIQCgNhcHAYBiABKAlSA2'
    'FwcBInCg9wYXJhbWV0ZXJzX2pzb24YByABKAlSDnBhcmFtZXRlcnNKc29u');

@$core.Deprecated('Use getAuthTokenResponseDescriptor instead')
const GetAuthTokenResponse$json = {
  '1': 'GetAuthTokenResponse',
  '2': [
    {
      '1': 'resp',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.cv_saas.BasicResponse',
      '10': 'resp'
    },
    {'1': 'token', '3': 2, '4': 1, '5': 9, '10': 'token'},
  ],
};

/// Descriptor for `GetAuthTokenResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getAuthTokenResponseDescriptor = $convert.base64Decode(
    'ChRHZXRBdXRoVG9rZW5SZXNwb25zZRIqCgRyZXNwGAEgASgLMhYuY3Zfc2Fhcy5CYXNpY1Jlc3'
    'BvbnNlUgRyZXNwEhQKBXRva2VuGAIgASgJUgV0b2tlbg==');

@$core.Deprecated('Use sendSmsRequestDescriptor instead')
const SendSmsRequest$json = {
  '1': 'SendSmsRequest',
  '2': [
    {'1': 'cell_num', '3': 1, '4': 1, '5': 9, '10': 'cellNum'},
    {'1': 'msg', '3': 2, '4': 1, '5': 9, '10': 'msg'},
  ],
};

/// Descriptor for `SendSmsRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sendSmsRequestDescriptor = $convert.base64Decode(
    'Cg5TZW5kU21zUmVxdWVzdBIZCghjZWxsX251bRgBIAEoCVIHY2VsbE51bRIQCgNtc2cYAiABKA'
    'lSA21zZw==');

@$core.Deprecated('Use setLockerStateRequestDescriptor instead')
const SetLockerStateRequest$json = {
  '1': 'SetLockerStateRequest',
  '2': [
    {'1': 'locker_num', '3': 1, '4': 1, '5': 13, '10': 'lockerNum'},
    {'1': 'state', '3': 2, '4': 1, '5': 13, '10': 'state'},
  ],
};

/// Descriptor for `SetLockerStateRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List setLockerStateRequestDescriptor = $convert.base64Decode(
    'ChVTZXRMb2NrZXJTdGF0ZVJlcXVlc3QSHQoKbG9ja2VyX251bRgBIAEoDVIJbG9ja2VyTnVtEh'
    'QKBXN0YXRlGAIgASgNUgVzdGF0ZQ==');

@$core.Deprecated('Use lockerStateMessageDescriptor instead')
const LockerStateMessage$json = {
  '1': 'LockerStateMessage',
  '2': [
    {'1': 'state', '3': 1, '4': 1, '5': 13, '10': 'state'},
  ],
};

/// Descriptor for `LockerStateMessage`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List lockerStateMessageDescriptor = $convert
    .base64Decode('ChJMb2NrZXJTdGF0ZU1lc3NhZ2USFAoFc3RhdGUYASABKA1SBXN0YXRl');

@$core.Deprecated('Use lockerStateResponseMessageDescriptor instead')
const LockerStateResponseMessage$json = {
  '1': 'LockerStateResponseMessage',
  '2': [
    {'1': 'initialized', '3': 1, '4': 1, '5': 8, '10': 'initialized'},
    {
      '1': 'state',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.cv_saas.LockerStateMessage',
      '10': 'state'
    },
  ],
};

/// Descriptor for `LockerStateResponseMessage`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List lockerStateResponseMessageDescriptor =
    $convert.base64Decode(
        'ChpMb2NrZXJTdGF0ZVJlc3BvbnNlTWVzc2FnZRIgCgtpbml0aWFsaXplZBgBIAEoCFILaW5pdG'
        'lhbGl6ZWQSMQoFc3RhdGUYAiABKAsyGy5jdl9zYWFzLkxvY2tlclN0YXRlTWVzc2FnZVIFc3Rh'
        'dGU=');

@$core.Deprecated('Use setLedMessageDescriptor instead')
const SetLedMessage$json = {
  '1': 'SetLedMessage',
  '2': [
    {'1': 'locker_num', '3': 1, '4': 1, '5': 13, '10': 'lockerNum'},
    {'1': 'color', '3': 2, '4': 1, '5': 13, '10': 'color'},
  ],
};

/// Descriptor for `SetLedMessage`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List setLedMessageDescriptor = $convert.base64Decode(
    'Cg1TZXRMZWRNZXNzYWdlEh0KCmxvY2tlcl9udW0YASABKA1SCWxvY2tlck51bRIUCgVjb2xvch'
    'gCIAEoDVIFY29sb3I=');

@$core.Deprecated('Use getLockerStatesResponseDescriptor instead')
const GetLockerStatesResponse$json = {
  '1': 'GetLockerStatesResponse',
  '2': [
    {
      '1': 'resp',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.cv_saas.BasicResponse',
      '10': 'resp'
    },
    {'1': 'door_map', '3': 2, '4': 3, '5': 5, '10': 'doorMap'},
    {
      '1': 'locker_map',
      '3': 3,
      '4': 3,
      '5': 11,
      '6': '.cv_saas.LockerStateResponseMessage',
      '10': 'lockerMap'
    },
  ],
};

/// Descriptor for `GetLockerStatesResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getLockerStatesResponseDescriptor = $convert.base64Decode(
    'ChdHZXRMb2NrZXJTdGF0ZXNSZXNwb25zZRIqCgRyZXNwGAEgASgLMhYuY3Zfc2Fhcy5CYXNpY1'
    'Jlc3BvbnNlUgRyZXNwEhkKCGRvb3JfbWFwGAIgAygFUgdkb29yTWFwEkIKCmxvY2tlcl9tYXAY'
    'AyADKAsyIy5jdl9zYWFzLkxvY2tlclN0YXRlUmVzcG9uc2VNZXNzYWdlUglsb2NrZXJNYXA=');

@$core.Deprecated('Use getSlaveFirmwareResponseDescriptor instead')
const GetSlaveFirmwareResponse$json = {
  '1': 'GetSlaveFirmwareResponse',
  '2': [
    {
      '1': 'resp',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.cv_saas.BasicResponse',
      '10': 'resp'
    },
    {'1': 'firmware', '3': 2, '4': 3, '5': 9, '10': 'firmware'},
  ],
};

/// Descriptor for `GetSlaveFirmwareResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getSlaveFirmwareResponseDescriptor =
    $convert.base64Decode(
        'ChhHZXRTbGF2ZUZpcm13YXJlUmVzcG9uc2USKgoEcmVzcBgBIAEoCzIWLmN2X3NhYXMuQmFzaW'
        'NSZXNwb25zZVIEcmVzcBIaCghmaXJtd2FyZRgCIAMoCVIIZmlybXdhcmU=');

@$core.Deprecated('Use rebootRequestDescriptor instead')
const RebootRequest$json = {
  '1': 'RebootRequest',
  '2': [
    {'1': 'code', '3': 1, '4': 1, '5': 9, '10': 'code'},
  ],
};

/// Descriptor for `RebootRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List rebootRequestDescriptor =
    $convert.base64Decode('Cg1SZWJvb3RSZXF1ZXN0EhIKBGNvZGUYASABKAlSBGNvZGU=');

@$core.Deprecated('Use getProtocolVersionResponseDescriptor instead')
const GetProtocolVersionResponse$json = {
  '1': 'GetProtocolVersionResponse',
  '2': [
    {
      '1': 'resp',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.cv_saas.BasicResponse',
      '10': 'resp'
    },
    {'1': 'version', '3': 2, '4': 1, '5': 9, '10': 'version'},
  ],
};

/// Descriptor for `GetProtocolVersionResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getProtocolVersionResponseDescriptor =
    $convert.base64Decode(
        'ChpHZXRQcm90b2NvbFZlcnNpb25SZXNwb25zZRIqCgRyZXNwGAEgASgLMhYuY3Zfc2Fhcy5CYX'
        'NpY1Jlc3BvbnNlUgRyZXNwEhgKB3ZlcnNpb24YAiABKAlSB3ZlcnNpb24=');

@$core.Deprecated('Use mqttCommsIntegrationDescriptor instead')
const MqttCommsIntegration$json = {
  '1': 'MqttCommsIntegration',
  '2': [
    {'1': 'host', '3': 1, '4': 1, '5': 9, '10': 'host'},
    {'1': 'port', '3': 2, '4': 1, '5': 13, '10': 'port'},
  ],
};

/// Descriptor for `MqttCommsIntegration`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List mqttCommsIntegrationDescriptor = $convert.base64Decode(
    'ChRNcXR0Q29tbXNJbnRlZ3JhdGlvbhISCgRob3N0GAEgASgJUgRob3N0EhIKBHBvcnQYAiABKA'
    '1SBHBvcnQ=');

@$core.Deprecated('Use registerMqttIntegrationRequestDescriptor instead')
const RegisterMqttIntegrationRequest$json = {
  '1': 'RegisterMqttIntegrationRequest',
  '2': [
    {'1': 'name', '3': 1, '4': 1, '5': 9, '10': 'name'},
    {
      '1': 'integration',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.cv_saas.MqttCommsIntegration',
      '10': 'integration'
    },
  ],
};

/// Descriptor for `RegisterMqttIntegrationRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List registerMqttIntegrationRequestDescriptor =
    $convert.base64Decode(
        'Ch5SZWdpc3Rlck1xdHRJbnRlZ3JhdGlvblJlcXVlc3QSEgoEbmFtZRgBIAEoCVIEbmFtZRI/Cg'
        'tpbnRlZ3JhdGlvbhgCIAEoCzIdLmN2X3NhYXMuTXF0dENvbW1zSW50ZWdyYXRpb25SC2ludGVn'
        'cmF0aW9u');

@$core.Deprecated('Use registerMqttIntegrationResponseDescriptor instead')
const RegisterMqttIntegrationResponse$json = {
  '1': 'RegisterMqttIntegrationResponse',
  '2': [
    {
      '1': 'resp',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.cv_saas.BasicResponse',
      '10': 'resp'
    },
  ],
};

/// Descriptor for `RegisterMqttIntegrationResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List registerMqttIntegrationResponseDescriptor =
    $convert.base64Decode(
        'Ch9SZWdpc3Rlck1xdHRJbnRlZ3JhdGlvblJlc3BvbnNlEioKBHJlc3AYASABKAsyFi5jdl9zYW'
        'FzLkJhc2ljUmVzcG9uc2VSBHJlc3A=');

@$core.Deprecated('Use unregisterMqttIntegrationRequestDescriptor instead')
const UnregisterMqttIntegrationRequest$json = {
  '1': 'UnregisterMqttIntegrationRequest',
  '2': [
    {'1': 'name', '3': 1, '4': 1, '5': 9, '10': 'name'},
  ],
};

/// Descriptor for `UnregisterMqttIntegrationRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List unregisterMqttIntegrationRequestDescriptor =
    $convert.base64Decode(
        'CiBVbnJlZ2lzdGVyTXF0dEludGVncmF0aW9uUmVxdWVzdBISCgRuYW1lGAEgASgJUgRuYW1l');

@$core.Deprecated('Use kVPairItemDescriptor instead')
const KVPairItem$json = {
  '1': 'KVPairItem',
  '2': [
    {'1': 'k', '3': 1, '4': 1, '5': 9, '10': 'k'},
    {'1': 'v', '3': 2, '4': 1, '5': 9, '10': 'v'},
  ],
};

/// Descriptor for `KVPairItem`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List kVPairItemDescriptor = $convert
    .base64Decode('CgpLVlBhaXJJdGVtEgwKAWsYASABKAlSAWsSDAoBdhgCIAEoCVIBdg==');

@$core.Deprecated('Use integrationItemDescriptor instead')
const IntegrationItem$json = {
  '1': 'IntegrationItem',
  '2': [
    {'1': 'bind_addr', '3': 1, '4': 1, '5': 9, '10': 'bindAddr'},
    {'1': 'send_addr', '3': 2, '4': 1, '5': 9, '10': 'sendAddr'},
  ],
};

/// Descriptor for `IntegrationItem`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List integrationItemDescriptor = $convert.base64Decode(
    'Cg9JbnRlZ3JhdGlvbkl0ZW0SGwoJYmluZF9hZGRyGAEgASgJUghiaW5kQWRkchIbCglzZW5kX2'
    'FkZHIYAiABKAlSCHNlbmRBZGRy');

@$core.Deprecated('Use notificationMessageRequestDescriptor instead')
const NotificationMessageRequest$json = {
  '1': 'NotificationMessageRequest',
  '2': [
    {'1': 'msg_type', '3': 1, '4': 1, '5': 9, '10': 'msgType'},
    {
      '1': 'vals',
      '3': 2,
      '4': 3,
      '5': 11,
      '6': '.cv_saas.KVPairItem',
      '10': 'vals'
    },
    {
      '1': 'integration',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.cv_saas.IntegrationItem',
      '10': 'integration'
    },
  ],
};

/// Descriptor for `NotificationMessageRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List notificationMessageRequestDescriptor =
    $convert.base64Decode(
        'ChpOb3RpZmljYXRpb25NZXNzYWdlUmVxdWVzdBIZCghtc2dfdHlwZRgBIAEoCVIHbXNnVHlwZR'
        'InCgR2YWxzGAIgAygLMhMuY3Zfc2Fhcy5LVlBhaXJJdGVtUgR2YWxzEjoKC2ludGVncmF0aW9u'
        'GAMgASgLMhguY3Zfc2Fhcy5JbnRlZ3JhdGlvbkl0ZW1SC2ludGVncmF0aW9u');
