// This is a generated file - do not edit.
//
// Generated from service.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

class BasicResponse extends $pb.GeneratedMessage {
  factory BasicResponse({
    $core.bool? success,
    $core.String? errMsg,
    $core.int? code,
  }) {
    final result = create();
    if (success != null) result.success = success;
    if (errMsg != null) result.errMsg = errMsg;
    if (code != null) result.code = code;
    return result;
  }

  BasicResponse._();

  factory BasicResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory BasicResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'BasicResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'cv_saas'),
      createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'success')
    ..aOS(2, _omitFieldNames ? '' : 'errMsg', protoName: 'errMsg')
    ..aI(3, _omitFieldNames ? '' : 'code')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BasicResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BasicResponse copyWith(void Function(BasicResponse) updates) =>
      super.copyWith((message) => updates(message as BasicResponse))
          as BasicResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static BasicResponse create() => BasicResponse._();
  @$core.override
  BasicResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static BasicResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<BasicResponse>(create);
  static BasicResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get success => $_getBF(0);
  @$pb.TagNumber(1)
  set success($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSuccess() => $_has(0);
  @$pb.TagNumber(1)
  void clearSuccess() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get errMsg => $_getSZ(1);
  @$pb.TagNumber(2)
  set errMsg($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasErrMsg() => $_has(1);
  @$pb.TagNumber(2)
  void clearErrMsg() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get code => $_getIZ(2);
  @$pb.TagNumber(3)
  set code($core.int value) => $_setSignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasCode() => $_has(2);
  @$pb.TagNumber(3)
  void clearCode() => $_clearField(3);
}

class GeneralResponse extends $pb.GeneratedMessage {
  factory GeneralResponse({
    BasicResponse? resp,
  }) {
    final result = create();
    if (resp != null) result.resp = resp;
    return result;
  }

  GeneralResponse._();

  factory GeneralResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GeneralResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GeneralResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'cv_saas'),
      createEmptyInstance: create)
    ..aOM<BasicResponse>(1, _omitFieldNames ? '' : 'resp',
        subBuilder: BasicResponse.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GeneralResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GeneralResponse copyWith(void Function(GeneralResponse) updates) =>
      super.copyWith((message) => updates(message as GeneralResponse))
          as GeneralResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GeneralResponse create() => GeneralResponse._();
  @$core.override
  GeneralResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static GeneralResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GeneralResponse>(create);
  static GeneralResponse? _defaultInstance;

  @$pb.TagNumber(1)
  BasicResponse get resp => $_getN(0);
  @$pb.TagNumber(1)
  set resp(BasicResponse value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasResp() => $_has(0);
  @$pb.TagNumber(1)
  void clearResp() => $_clearField(1);
  @$pb.TagNumber(1)
  BasicResponse ensureResp() => $_ensure(0);
}

class GetVersionResponse extends $pb.GeneratedMessage {
  factory GetVersionResponse({
    BasicResponse? resp,
    $core.String? version,
  }) {
    final result = create();
    if (resp != null) result.resp = resp;
    if (version != null) result.version = version;
    return result;
  }

  GetVersionResponse._();

  factory GetVersionResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GetVersionResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetVersionResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'cv_saas'),
      createEmptyInstance: create)
    ..aOM<BasicResponse>(1, _omitFieldNames ? '' : 'resp',
        subBuilder: BasicResponse.create)
    ..aOS(2, _omitFieldNames ? '' : 'version')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetVersionResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetVersionResponse copyWith(void Function(GetVersionResponse) updates) =>
      super.copyWith((message) => updates(message as GetVersionResponse))
          as GetVersionResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetVersionResponse create() => GetVersionResponse._();
  @$core.override
  GetVersionResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static GetVersionResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetVersionResponse>(create);
  static GetVersionResponse? _defaultInstance;

  @$pb.TagNumber(1)
  BasicResponse get resp => $_getN(0);
  @$pb.TagNumber(1)
  set resp(BasicResponse value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasResp() => $_has(0);
  @$pb.TagNumber(1)
  void clearResp() => $_clearField(1);
  @$pb.TagNumber(1)
  BasicResponse ensureResp() => $_ensure(0);

  /// will contain the software version number
  @$pb.TagNumber(2)
  $core.String get version => $_getSZ(1);
  @$pb.TagNumber(2)
  set version($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasVersion() => $_has(1);
  @$pb.TagNumber(2)
  void clearVersion() => $_clearField(2);
}

class GetLockerMapResponse extends $pb.GeneratedMessage {
  factory GetLockerMapResponse({
    BasicResponse? resp,
    $core.Iterable<$core.int>? lockers,
    $core.int? numLockers,
  }) {
    final result = create();
    if (resp != null) result.resp = resp;
    if (lockers != null) result.lockers.addAll(lockers);
    if (numLockers != null) result.numLockers = numLockers;
    return result;
  }

  GetLockerMapResponse._();

  factory GetLockerMapResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GetLockerMapResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetLockerMapResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'cv_saas'),
      createEmptyInstance: create)
    ..aOM<BasicResponse>(1, _omitFieldNames ? '' : 'resp',
        subBuilder: BasicResponse.create)
    ..p<$core.int>(2, _omitFieldNames ? '' : 'lockers', $pb.PbFieldType.KU3)
    ..aI(3, _omitFieldNames ? '' : 'numLockers', fieldType: $pb.PbFieldType.OU3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetLockerMapResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetLockerMapResponse copyWith(void Function(GetLockerMapResponse) updates) =>
      super.copyWith((message) => updates(message as GetLockerMapResponse))
          as GetLockerMapResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetLockerMapResponse create() => GetLockerMapResponse._();
  @$core.override
  GetLockerMapResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static GetLockerMapResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetLockerMapResponse>(create);
  static GetLockerMapResponse? _defaultInstance;

  @$pb.TagNumber(1)
  BasicResponse get resp => $_getN(0);
  @$pb.TagNumber(1)
  set resp(BasicResponse value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasResp() => $_has(0);
  @$pb.TagNumber(1)
  void clearResp() => $_clearField(1);
  @$pb.TagNumber(1)
  BasicResponse ensureResp() => $_ensure(0);

  /// an array of the number of lockers in each slave (not necessarily column since we've had products where
  /// multiple slaves are used in a single column eg. if a 10-locker column is required)
  @$pb.TagNumber(2)
  $pb.PbList<$core.int> get lockers => $_getList(1);

  /// the total number of lockers in the system. This is just the sum of all integers in the array
  @$pb.TagNumber(3)
  $core.int get numLockers => $_getIZ(2);
  @$pb.TagNumber(3)
  set numLockers($core.int value) => $_setUnsignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasNumLockers() => $_has(2);
  @$pb.TagNumber(3)
  void clearNumLockers() => $_clearField(3);
}

class ToggleBuzzerRequest extends $pb.GeneratedMessage {
  factory ToggleBuzzerRequest({
    $core.int? durationMillis,
  }) {
    final result = create();
    if (durationMillis != null) result.durationMillis = durationMillis;
    return result;
  }

  ToggleBuzzerRequest._();

  factory ToggleBuzzerRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ToggleBuzzerRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ToggleBuzzerRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'cv_saas'),
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'durationMillis',
        fieldType: $pb.PbFieldType.OU3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ToggleBuzzerRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ToggleBuzzerRequest copyWith(void Function(ToggleBuzzerRequest) updates) =>
      super.copyWith((message) => updates(message as ToggleBuzzerRequest))
          as ToggleBuzzerRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ToggleBuzzerRequest create() => ToggleBuzzerRequest._();
  @$core.override
  ToggleBuzzerRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ToggleBuzzerRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ToggleBuzzerRequest>(create);
  static ToggleBuzzerRequest? _defaultInstance;

  /// the number of millis for which the buzzer must be sounded
  @$pb.TagNumber(1)
  $core.int get durationMillis => $_getIZ(0);
  @$pb.TagNumber(1)
  set durationMillis($core.int value) => $_setUnsignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasDurationMillis() => $_has(0);
  @$pb.TagNumber(1)
  void clearDurationMillis() => $_clearField(1);
}

class LockRequest extends $pb.GeneratedMessage {
  factory LockRequest({
    $core.int? lockerNum,
  }) {
    final result = create();
    if (lockerNum != null) result.lockerNum = lockerNum;
    return result;
  }

  LockRequest._();

  factory LockRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory LockRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'LockRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'cv_saas'),
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'lockerNum', fieldType: $pb.PbFieldType.OU3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LockRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LockRequest copyWith(void Function(LockRequest) updates) =>
      super.copyWith((message) => updates(message as LockRequest))
          as LockRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static LockRequest create() => LockRequest._();
  @$core.override
  LockRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static LockRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<LockRequest>(create);
  static LockRequest? _defaultInstance;

  /// the locker number to locker. The first locker is always 1. The last locker can be determined by
  /// a call to get_locker_map()
  @$pb.TagNumber(1)
  $core.int get lockerNum => $_getIZ(0);
  @$pb.TagNumber(1)
  set lockerNum($core.int value) => $_setUnsignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasLockerNum() => $_has(0);
  @$pb.TagNumber(1)
  void clearLockerNum() => $_clearField(1);
}

class GetRtcResponse extends $pb.GeneratedMessage {
  factory GetRtcResponse({
    BasicResponse? resp,
    $core.String? datetime,
  }) {
    final result = create();
    if (resp != null) result.resp = resp;
    if (datetime != null) result.datetime = datetime;
    return result;
  }

  GetRtcResponse._();

  factory GetRtcResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GetRtcResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetRtcResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'cv_saas'),
      createEmptyInstance: create)
    ..aOM<BasicResponse>(1, _omitFieldNames ? '' : 'resp',
        subBuilder: BasicResponse.create)
    ..aOS(2, _omitFieldNames ? '' : 'datetime')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetRtcResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetRtcResponse copyWith(void Function(GetRtcResponse) updates) =>
      super.copyWith((message) => updates(message as GetRtcResponse))
          as GetRtcResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetRtcResponse create() => GetRtcResponse._();
  @$core.override
  GetRtcResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static GetRtcResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetRtcResponse>(create);
  static GetRtcResponse? _defaultInstance;

  @$pb.TagNumber(1)
  BasicResponse get resp => $_getN(0);
  @$pb.TagNumber(1)
  set resp(BasicResponse value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasResp() => $_has(0);
  @$pb.TagNumber(1)
  void clearResp() => $_clearField(1);
  @$pb.TagNumber(1)
  BasicResponse ensureResp() => $_ensure(0);

  /// the date+time in rfc8601/3399 format, with timezone information
  @$pb.TagNumber(2)
  $core.String get datetime => $_getSZ(1);
  @$pb.TagNumber(2)
  set datetime($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasDatetime() => $_has(1);
  @$pb.TagNumber(2)
  void clearDatetime() => $_clearField(2);
}

class SetRtcRequest extends $pb.GeneratedMessage {
  factory SetRtcRequest({
    $core.String? datetime,
  }) {
    final result = create();
    if (datetime != null) result.datetime = datetime;
    return result;
  }

  SetRtcRequest._();

  factory SetRtcRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SetRtcRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SetRtcRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'cv_saas'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'datetime')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetRtcRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetRtcRequest copyWith(void Function(SetRtcRequest) updates) =>
      super.copyWith((message) => updates(message as SetRtcRequest))
          as SetRtcRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SetRtcRequest create() => SetRtcRequest._();
  @$core.override
  SetRtcRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SetRtcRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SetRtcRequest>(create);
  static SetRtcRequest? _defaultInstance;

  /// the date+time in rfc8601/3399 format, with timezone information
  @$pb.TagNumber(1)
  $core.String get datetime => $_getSZ(0);
  @$pb.TagNumber(1)
  set datetime($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasDatetime() => $_has(0);
  @$pb.TagNumber(1)
  void clearDatetime() => $_clearField(1);
}

class LcdClearLineRequest extends $pb.GeneratedMessage {
  factory LcdClearLineRequest({
    $core.int? lineNum,
  }) {
    final result = create();
    if (lineNum != null) result.lineNum = lineNum;
    return result;
  }

  LcdClearLineRequest._();

  factory LcdClearLineRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory LcdClearLineRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'LcdClearLineRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'cv_saas'),
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'lineNum', fieldType: $pb.PbFieldType.OU3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LcdClearLineRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LcdClearLineRequest copyWith(void Function(LcdClearLineRequest) updates) =>
      super.copyWith((message) => updates(message as LcdClearLineRequest))
          as LcdClearLineRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static LcdClearLineRequest create() => LcdClearLineRequest._();
  @$core.override
  LcdClearLineRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static LcdClearLineRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<LcdClearLineRequest>(create);
  static LcdClearLineRequest? _defaultInstance;

  /// the number of the line to clear. Lines (rows) are 0-3, inclusive
  @$pb.TagNumber(1)
  $core.int get lineNum => $_getIZ(0);
  @$pb.TagNumber(1)
  set lineNum($core.int value) => $_setUnsignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasLineNum() => $_has(0);
  @$pb.TagNumber(1)
  void clearLineNum() => $_clearField(1);
}

class LcdWriteDataRequest extends $pb.GeneratedMessage {
  factory LcdWriteDataRequest({
    $core.int? row,
    $core.int? col,
    $core.String? text,
  }) {
    final result = create();
    if (row != null) result.row = row;
    if (col != null) result.col = col;
    if (text != null) result.text = text;
    return result;
  }

  LcdWriteDataRequest._();

  factory LcdWriteDataRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory LcdWriteDataRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'LcdWriteDataRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'cv_saas'),
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'row', fieldType: $pb.PbFieldType.OU3)
    ..aI(2, _omitFieldNames ? '' : 'col')
    ..aOS(3, _omitFieldNames ? '' : 'text')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LcdWriteDataRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LcdWriteDataRequest copyWith(void Function(LcdWriteDataRequest) updates) =>
      super.copyWith((message) => updates(message as LcdWriteDataRequest))
          as LcdWriteDataRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static LcdWriteDataRequest create() => LcdWriteDataRequest._();
  @$core.override
  LcdWriteDataRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static LcdWriteDataRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<LcdWriteDataRequest>(create);
  static LcdWriteDataRequest? _defaultInstance;

  /// 0-3
  @$pb.TagNumber(1)
  $core.int get row => $_getIZ(0);
  @$pb.TagNumber(1)
  set row($core.int value) => $_setUnsignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasRow() => $_has(0);
  @$pb.TagNumber(1)
  void clearRow() => $_clearField(1);

  /// 0-19
  @$pb.TagNumber(2)
  $core.int get col => $_getIZ(1);
  @$pb.TagNumber(2)
  set col($core.int value) => $_setSignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasCol() => $_has(1);
  @$pb.TagNumber(2)
  void clearCol() => $_clearField(2);

  /// data to write (no more than 20 chars if starting from column 0)
  @$pb.TagNumber(3)
  $core.String get text => $_getSZ(2);
  @$pb.TagNumber(3)
  set text($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasText() => $_has(2);
  @$pb.TagNumber(3)
  void clearText() => $_clearField(3);
}

class UserAuditLogRequest extends $pb.GeneratedMessage {
  factory UserAuditLogRequest({
    $core.int? version,
    $core.int? code,
    $core.String? level,
    $core.String? description,
    $core.String? priority,
    $core.String? app,
    $core.String? parametersJson,
  }) {
    final result = create();
    if (version != null) result.version = version;
    if (code != null) result.code = code;
    if (level != null) result.level = level;
    if (description != null) result.description = description;
    if (priority != null) result.priority = priority;
    if (app != null) result.app = app;
    if (parametersJson != null) result.parametersJson = parametersJson;
    return result;
  }

  UserAuditLogRequest._();

  factory UserAuditLogRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory UserAuditLogRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'UserAuditLogRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'cv_saas'),
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'version', fieldType: $pb.PbFieldType.OU3)
    ..aI(2, _omitFieldNames ? '' : 'code', fieldType: $pb.PbFieldType.OU3)
    ..aOS(3, _omitFieldNames ? '' : 'level')
    ..aOS(4, _omitFieldNames ? '' : 'description')
    ..aOS(5, _omitFieldNames ? '' : 'priority')
    ..aOS(6, _omitFieldNames ? '' : 'app')
    ..aOS(7, _omitFieldNames ? '' : 'parametersJson')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UserAuditLogRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UserAuditLogRequest copyWith(void Function(UserAuditLogRequest) updates) =>
      super.copyWith((message) => updates(message as UserAuditLogRequest))
          as UserAuditLogRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static UserAuditLogRequest create() => UserAuditLogRequest._();
  @$core.override
  UserAuditLogRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static UserAuditLogRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<UserAuditLogRequest>(create);
  static UserAuditLogRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get version => $_getIZ(0);
  @$pb.TagNumber(1)
  set version($core.int value) => $_setUnsignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasVersion() => $_has(0);
  @$pb.TagNumber(1)
  void clearVersion() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get code => $_getIZ(1);
  @$pb.TagNumber(2)
  set code($core.int value) => $_setUnsignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasCode() => $_has(1);
  @$pb.TagNumber(2)
  void clearCode() => $_clearField(2);

  /// *
  /// Valid values are "info", "warning", "error", "fatal" only. All other values will result in an error.
  @$pb.TagNumber(3)
  $core.String get level => $_getSZ(2);
  @$pb.TagNumber(3)
  set level($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasLevel() => $_has(2);
  @$pb.TagNumber(3)
  void clearLevel() => $_clearField(3);

  /// *
  /// The error message, no more than 1024 bytes
  @$pb.TagNumber(4)
  $core.String get description => $_getSZ(3);
  @$pb.TagNumber(4)
  set description($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasDescription() => $_has(3);
  @$pb.TagNumber(4)
  void clearDescription() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get priority => $_getSZ(4);
  @$pb.TagNumber(5)
  set priority($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasPriority() => $_has(4);
  @$pb.TagNumber(5)
  void clearPriority() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get app => $_getSZ(5);
  @$pb.TagNumber(6)
  set app($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasApp() => $_has(5);
  @$pb.TagNumber(6)
  void clearApp() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.String get parametersJson => $_getSZ(6);
  @$pb.TagNumber(7)
  set parametersJson($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasParametersJson() => $_has(6);
  @$pb.TagNumber(7)
  void clearParametersJson() => $_clearField(7);
}

class GetAuthTokenResponse extends $pb.GeneratedMessage {
  factory GetAuthTokenResponse({
    BasicResponse? resp,
    $core.String? token,
  }) {
    final result = create();
    if (resp != null) result.resp = resp;
    if (token != null) result.token = token;
    return result;
  }

  GetAuthTokenResponse._();

  factory GetAuthTokenResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GetAuthTokenResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetAuthTokenResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'cv_saas'),
      createEmptyInstance: create)
    ..aOM<BasicResponse>(1, _omitFieldNames ? '' : 'resp',
        subBuilder: BasicResponse.create)
    ..aOS(2, _omitFieldNames ? '' : 'token')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetAuthTokenResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetAuthTokenResponse copyWith(void Function(GetAuthTokenResponse) updates) =>
      super.copyWith((message) => updates(message as GetAuthTokenResponse))
          as GetAuthTokenResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetAuthTokenResponse create() => GetAuthTokenResponse._();
  @$core.override
  GetAuthTokenResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static GetAuthTokenResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetAuthTokenResponse>(create);
  static GetAuthTokenResponse? _defaultInstance;

  @$pb.TagNumber(1)
  BasicResponse get resp => $_getN(0);
  @$pb.TagNumber(1)
  set resp(BasicResponse value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasResp() => $_has(0);
  @$pb.TagNumber(1)
  void clearResp() => $_clearField(1);
  @$pb.TagNumber(1)
  BasicResponse ensureResp() => $_ensure(0);

  /// *
  /// Gives access to a copy of the JWT token used for authentication by this app.
  /// This allows the client to access VG APIs if required. An empty string i.e. ""
  /// in a success response means no token is currently available
  @$pb.TagNumber(2)
  $core.String get token => $_getSZ(1);
  @$pb.TagNumber(2)
  set token($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasToken() => $_has(1);
  @$pb.TagNumber(2)
  void clearToken() => $_clearField(2);
}

class SendSmsRequest extends $pb.GeneratedMessage {
  factory SendSmsRequest({
    $core.String? cellNum,
    $core.String? msg,
  }) {
    final result = create();
    if (cellNum != null) result.cellNum = cellNum;
    if (msg != null) result.msg = msg;
    return result;
  }

  SendSmsRequest._();

  factory SendSmsRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SendSmsRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SendSmsRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'cv_saas'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'cellNum')
    ..aOS(2, _omitFieldNames ? '' : 'msg')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SendSmsRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SendSmsRequest copyWith(void Function(SendSmsRequest) updates) =>
      super.copyWith((message) => updates(message as SendSmsRequest))
          as SendSmsRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SendSmsRequest create() => SendSmsRequest._();
  @$core.override
  SendSmsRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SendSmsRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SendSmsRequest>(create);
  static SendSmsRequest? _defaultInstance;

  /// cellphone number
  @$pb.TagNumber(1)
  $core.String get cellNum => $_getSZ(0);
  @$pb.TagNumber(1)
  set cellNum($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasCellNum() => $_has(0);
  @$pb.TagNumber(1)
  void clearCellNum() => $_clearField(1);

  /// sms data to send
  @$pb.TagNumber(2)
  $core.String get msg => $_getSZ(1);
  @$pb.TagNumber(2)
  set msg($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasMsg() => $_has(1);
  @$pb.TagNumber(2)
  void clearMsg() => $_clearField(2);
}

class SetLockerStateRequest extends $pb.GeneratedMessage {
  factory SetLockerStateRequest({
    $core.int? lockerNum,
    $core.int? state,
  }) {
    final result = create();
    if (lockerNum != null) result.lockerNum = lockerNum;
    if (state != null) result.state = state;
    return result;
  }

  SetLockerStateRequest._();

  factory SetLockerStateRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SetLockerStateRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SetLockerStateRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'cv_saas'),
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'lockerNum', fieldType: $pb.PbFieldType.OU3)
    ..aI(2, _omitFieldNames ? '' : 'state', fieldType: $pb.PbFieldType.OU3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetLockerStateRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetLockerStateRequest copyWith(
          void Function(SetLockerStateRequest) updates) =>
      super.copyWith((message) => updates(message as SetLockerStateRequest))
          as SetLockerStateRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SetLockerStateRequest create() => SetLockerStateRequest._();
  @$core.override
  SetLockerStateRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SetLockerStateRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SetLockerStateRequest>(create);
  static SetLockerStateRequest? _defaultInstance;

  /// *
  /// the locker to access. The first locker is 1
  @$pb.TagNumber(1)
  $core.int get lockerNum => $_getIZ(0);
  @$pb.TagNumber(1)
  set lockerNum($core.int value) => $_setUnsignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasLockerNum() => $_has(0);
  @$pb.TagNumber(1)
  void clearLockerNum() => $_clearField(1);

  /// *
  /// the state to set the locker to. Valid values are:
  /// LS_OPEN = 0
  /// LS_LOCKED = 1
  /// LS_READY_OPEN = 2
  @$pb.TagNumber(2)
  $core.int get state => $_getIZ(1);
  @$pb.TagNumber(2)
  set state($core.int value) => $_setUnsignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasState() => $_has(1);
  @$pb.TagNumber(2)
  void clearState() => $_clearField(2);
}

class LockerStateMessage extends $pb.GeneratedMessage {
  factory LockerStateMessage({
    $core.int? state,
  }) {
    final result = create();
    if (state != null) result.state = state;
    return result;
  }

  LockerStateMessage._();

  factory LockerStateMessage.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory LockerStateMessage.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'LockerStateMessage',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'cv_saas'),
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'state', fieldType: $pb.PbFieldType.OU3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LockerStateMessage clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LockerStateMessage copyWith(void Function(LockerStateMessage) updates) =>
      super.copyWith((message) => updates(message as LockerStateMessage))
          as LockerStateMessage;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static LockerStateMessage create() => LockerStateMessage._();
  @$core.override
  LockerStateMessage createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static LockerStateMessage getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<LockerStateMessage>(create);
  static LockerStateMessage? _defaultInstance;

  /// *
  ///  See comment in SetLockerStateRequest
  @$pb.TagNumber(1)
  $core.int get state => $_getIZ(0);
  @$pb.TagNumber(1)
  set state($core.int value) => $_setUnsignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasState() => $_has(0);
  @$pb.TagNumber(1)
  void clearState() => $_clearField(1);
}

class LockerStateResponseMessage extends $pb.GeneratedMessage {
  factory LockerStateResponseMessage({
    $core.bool? initialized,
    LockerStateMessage? state,
  }) {
    final result = create();
    if (initialized != null) result.initialized = initialized;
    if (state != null) result.state = state;
    return result;
  }

  LockerStateResponseMessage._();

  factory LockerStateResponseMessage.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory LockerStateResponseMessage.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'LockerStateResponseMessage',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'cv_saas'),
      createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'initialized')
    ..aOM<LockerStateMessage>(2, _omitFieldNames ? '' : 'state',
        subBuilder: LockerStateMessage.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LockerStateResponseMessage clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LockerStateResponseMessage copyWith(
          void Function(LockerStateResponseMessage) updates) =>
      super.copyWith(
              (message) => updates(message as LockerStateResponseMessage))
          as LockerStateResponseMessage;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static LockerStateResponseMessage create() => LockerStateResponseMessage._();
  @$core.override
  LockerStateResponseMessage createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static LockerStateResponseMessage getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<LockerStateResponseMessage>(create);
  static LockerStateResponseMessage? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get initialized => $_getBF(0);
  @$pb.TagNumber(1)
  set initialized($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasInitialized() => $_has(0);
  @$pb.TagNumber(1)
  void clearInitialized() => $_clearField(1);

  @$pb.TagNumber(2)
  LockerStateMessage get state => $_getN(1);
  @$pb.TagNumber(2)
  set state(LockerStateMessage value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasState() => $_has(1);
  @$pb.TagNumber(2)
  void clearState() => $_clearField(2);
  @$pb.TagNumber(2)
  LockerStateMessage ensureState() => $_ensure(1);
}

class SetLedMessage extends $pb.GeneratedMessage {
  factory SetLedMessage({
    $core.int? lockerNum,
    $core.int? color,
  }) {
    final result = create();
    if (lockerNum != null) result.lockerNum = lockerNum;
    if (color != null) result.color = color;
    return result;
  }

  SetLedMessage._();

  factory SetLedMessage.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SetLedMessage.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SetLedMessage',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'cv_saas'),
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'lockerNum', fieldType: $pb.PbFieldType.OU3)
    ..aI(2, _omitFieldNames ? '' : 'color', fieldType: $pb.PbFieldType.OU3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetLedMessage clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetLedMessage copyWith(void Function(SetLedMessage) updates) =>
      super.copyWith((message) => updates(message as SetLedMessage))
          as SetLedMessage;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SetLedMessage create() => SetLedMessage._();
  @$core.override
  SetLedMessage createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SetLedMessage getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SetLedMessage>(create);
  static SetLedMessage? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get lockerNum => $_getIZ(0);
  @$pb.TagNumber(1)
  set lockerNum($core.int value) => $_setUnsignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasLockerNum() => $_has(0);
  @$pb.TagNumber(1)
  void clearLockerNum() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get color => $_getIZ(1);
  @$pb.TagNumber(2)
  set color($core.int value) => $_setUnsignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasColor() => $_has(1);
  @$pb.TagNumber(2)
  void clearColor() => $_clearField(2);
}

class GetLockerStatesResponse extends $pb.GeneratedMessage {
  factory GetLockerStatesResponse({
    BasicResponse? resp,
    $core.Iterable<$core.int>? doorMap,
    $core.Iterable<LockerStateResponseMessage>? lockerMap,
  }) {
    final result = create();
    if (resp != null) result.resp = resp;
    if (doorMap != null) result.doorMap.addAll(doorMap);
    if (lockerMap != null) result.lockerMap.addAll(lockerMap);
    return result;
  }

  GetLockerStatesResponse._();

  factory GetLockerStatesResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GetLockerStatesResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetLockerStatesResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'cv_saas'),
      createEmptyInstance: create)
    ..aOM<BasicResponse>(1, _omitFieldNames ? '' : 'resp',
        subBuilder: BasicResponse.create)
    ..p<$core.int>(2, _omitFieldNames ? '' : 'doorMap', $pb.PbFieldType.K3)
    ..pPM<LockerStateResponseMessage>(3, _omitFieldNames ? '' : 'lockerMap',
        subBuilder: LockerStateResponseMessage.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetLockerStatesResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetLockerStatesResponse copyWith(
          void Function(GetLockerStatesResponse) updates) =>
      super.copyWith((message) => updates(message as GetLockerStatesResponse))
          as GetLockerStatesResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetLockerStatesResponse create() => GetLockerStatesResponse._();
  @$core.override
  GetLockerStatesResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static GetLockerStatesResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetLockerStatesResponse>(create);
  static GetLockerStatesResponse? _defaultInstance;

  @$pb.TagNumber(1)
  BasicResponse get resp => $_getN(0);
  @$pb.TagNumber(1)
  set resp(BasicResponse value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasResp() => $_has(0);
  @$pb.TagNumber(1)
  void clearResp() => $_clearField(1);
  @$pb.TagNumber(1)
  BasicResponse ensureResp() => $_ensure(0);

  /// an array of integers where -1 means not initialized, 0 means closed, 1 means open.
  /// each number is for 1 locker (eg. if there are 20 lockers, there will be 20 items
  /// in the array)
  @$pb.TagNumber(2)
  $pb.PbList<$core.int> get doorMap => $_getList(1);

  /// each item is for 1 locker (eg. if there are 20 lockers, there will be 20 items
  /// in the array)
  @$pb.TagNumber(3)
  $pb.PbList<LockerStateResponseMessage> get lockerMap => $_getList(2);
}

class GetSlaveFirmwareResponse extends $pb.GeneratedMessage {
  factory GetSlaveFirmwareResponse({
    BasicResponse? resp,
    $core.Iterable<$core.String>? firmware,
  }) {
    final result = create();
    if (resp != null) result.resp = resp;
    if (firmware != null) result.firmware.addAll(firmware);
    return result;
  }

  GetSlaveFirmwareResponse._();

  factory GetSlaveFirmwareResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GetSlaveFirmwareResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetSlaveFirmwareResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'cv_saas'),
      createEmptyInstance: create)
    ..aOM<BasicResponse>(1, _omitFieldNames ? '' : 'resp',
        subBuilder: BasicResponse.create)
    ..pPS(2, _omitFieldNames ? '' : 'firmware')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetSlaveFirmwareResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetSlaveFirmwareResponse copyWith(
          void Function(GetSlaveFirmwareResponse) updates) =>
      super.copyWith((message) => updates(message as GetSlaveFirmwareResponse))
          as GetSlaveFirmwareResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetSlaveFirmwareResponse create() => GetSlaveFirmwareResponse._();
  @$core.override
  GetSlaveFirmwareResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static GetSlaveFirmwareResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetSlaveFirmwareResponse>(create);
  static GetSlaveFirmwareResponse? _defaultInstance;

  @$pb.TagNumber(1)
  BasicResponse get resp => $_getN(0);
  @$pb.TagNumber(1)
  set resp(BasicResponse value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasResp() => $_has(0);
  @$pb.TagNumber(1)
  void clearResp() => $_clearField(1);
  @$pb.TagNumber(1)
  BasicResponse ensureResp() => $_ensure(0);

  @$pb.TagNumber(2)
  $pb.PbList<$core.String> get firmware => $_getList(1);
}

class RebootRequest extends $pb.GeneratedMessage {
  factory RebootRequest({
    $core.String? code,
  }) {
    final result = create();
    if (code != null) result.code = code;
    return result;
  }

  RebootRequest._();

  factory RebootRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory RebootRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RebootRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'cv_saas'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'code')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RebootRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RebootRequest copyWith(void Function(RebootRequest) updates) =>
      super.copyWith((message) => updates(message as RebootRequest))
          as RebootRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RebootRequest create() => RebootRequest._();
  @$core.override
  RebootRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static RebootRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RebootRequest>(create);
  static RebootRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get code => $_getSZ(0);
  @$pb.TagNumber(1)
  set code($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasCode() => $_has(0);
  @$pb.TagNumber(1)
  void clearCode() => $_clearField(1);
}

/// returns protocol response information
class GetProtocolVersionResponse extends $pb.GeneratedMessage {
  factory GetProtocolVersionResponse({
    BasicResponse? resp,
    $core.String? version,
  }) {
    final result = create();
    if (resp != null) result.resp = resp;
    if (version != null) result.version = version;
    return result;
  }

  GetProtocolVersionResponse._();

  factory GetProtocolVersionResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GetProtocolVersionResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetProtocolVersionResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'cv_saas'),
      createEmptyInstance: create)
    ..aOM<BasicResponse>(1, _omitFieldNames ? '' : 'resp',
        subBuilder: BasicResponse.create)
    ..aOS(2, _omitFieldNames ? '' : 'version')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetProtocolVersionResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetProtocolVersionResponse copyWith(
          void Function(GetProtocolVersionResponse) updates) =>
      super.copyWith(
              (message) => updates(message as GetProtocolVersionResponse))
          as GetProtocolVersionResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetProtocolVersionResponse create() => GetProtocolVersionResponse._();
  @$core.override
  GetProtocolVersionResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static GetProtocolVersionResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetProtocolVersionResponse>(create);
  static GetProtocolVersionResponse? _defaultInstance;

  @$pb.TagNumber(1)
  BasicResponse get resp => $_getN(0);
  @$pb.TagNumber(1)
  set resp(BasicResponse value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasResp() => $_has(0);
  @$pb.TagNumber(1)
  void clearResp() => $_clearField(1);
  @$pb.TagNumber(1)
  BasicResponse ensureResp() => $_ensure(0);

  /// the protocol version
  @$pb.TagNumber(2)
  $core.String get version => $_getSZ(1);
  @$pb.TagNumber(2)
  set version($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasVersion() => $_has(1);
  @$pb.TagNumber(2)
  void clearVersion() => $_clearField(2);
}

/// the communications channel for registering a mqtt integration
class MqttCommsIntegration extends $pb.GeneratedMessage {
  factory MqttCommsIntegration({
    $core.String? host,
    $core.int? port,
  }) {
    final result = create();
    if (host != null) result.host = host;
    if (port != null) result.port = port;
    return result;
  }

  MqttCommsIntegration._();

  factory MqttCommsIntegration.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory MqttCommsIntegration.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'MqttCommsIntegration',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'cv_saas'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'host')
    ..aI(2, _omitFieldNames ? '' : 'port', fieldType: $pb.PbFieldType.OU3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MqttCommsIntegration clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MqttCommsIntegration copyWith(void Function(MqttCommsIntegration) updates) =>
      super.copyWith((message) => updates(message as MqttCommsIntegration))
          as MqttCommsIntegration;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static MqttCommsIntegration create() => MqttCommsIntegration._();
  @$core.override
  MqttCommsIntegration createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static MqttCommsIntegration getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<MqttCommsIntegration>(create);
  static MqttCommsIntegration? _defaultInstance;

  /// the host to which messages must be sent
  @$pb.TagNumber(1)
  $core.String get host => $_getSZ(0);
  @$pb.TagNumber(1)
  set host($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasHost() => $_has(0);
  @$pb.TagNumber(1)
  void clearHost() => $_clearField(1);

  /// the port to which messages must be sent
  @$pb.TagNumber(2)
  $core.int get port => $_getIZ(1);
  @$pb.TagNumber(2)
  set port($core.int value) => $_setUnsignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasPort() => $_has(1);
  @$pb.TagNumber(2)
  void clearPort() => $_clearField(2);
}

/// used to register an external integration with the mqtt service
class RegisterMqttIntegrationRequest extends $pb.GeneratedMessage {
  factory RegisterMqttIntegrationRequest({
    $core.String? name,
    MqttCommsIntegration? integration,
  }) {
    final result = create();
    if (name != null) result.name = name;
    if (integration != null) result.integration = integration;
    return result;
  }

  RegisterMqttIntegrationRequest._();

  factory RegisterMqttIntegrationRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory RegisterMqttIntegrationRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RegisterMqttIntegrationRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'cv_saas'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'name')
    ..aOM<MqttCommsIntegration>(2, _omitFieldNames ? '' : 'integration',
        subBuilder: MqttCommsIntegration.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RegisterMqttIntegrationRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RegisterMqttIntegrationRequest copyWith(
          void Function(RegisterMqttIntegrationRequest) updates) =>
      super.copyWith(
              (message) => updates(message as RegisterMqttIntegrationRequest))
          as RegisterMqttIntegrationRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RegisterMqttIntegrationRequest create() =>
      RegisterMqttIntegrationRequest._();
  @$core.override
  RegisterMqttIntegrationRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static RegisterMqttIntegrationRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RegisterMqttIntegrationRequest>(create);
  static RegisterMqttIntegrationRequest? _defaultInstance;

  /// the name of the integration
  @$pb.TagNumber(1)
  $core.String get name => $_getSZ(0);
  @$pb.TagNumber(1)
  set name($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasName() => $_has(0);
  @$pb.TagNumber(1)
  void clearName() => $_clearField(1);

  /// integration details (see message definition for more)
  @$pb.TagNumber(2)
  MqttCommsIntegration get integration => $_getN(1);
  @$pb.TagNumber(2)
  set integration(MqttCommsIntegration value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasIntegration() => $_has(1);
  @$pb.TagNumber(2)
  void clearIntegration() => $_clearField(2);
  @$pb.TagNumber(2)
  MqttCommsIntegration ensureIntegration() => $_ensure(1);
}

/// basic response message after registering a mqtt integration
class RegisterMqttIntegrationResponse extends $pb.GeneratedMessage {
  factory RegisterMqttIntegrationResponse({
    BasicResponse? resp,
  }) {
    final result = create();
    if (resp != null) result.resp = resp;
    return result;
  }

  RegisterMqttIntegrationResponse._();

  factory RegisterMqttIntegrationResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory RegisterMqttIntegrationResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RegisterMqttIntegrationResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'cv_saas'),
      createEmptyInstance: create)
    ..aOM<BasicResponse>(1, _omitFieldNames ? '' : 'resp',
        subBuilder: BasicResponse.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RegisterMqttIntegrationResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RegisterMqttIntegrationResponse copyWith(
          void Function(RegisterMqttIntegrationResponse) updates) =>
      super.copyWith(
              (message) => updates(message as RegisterMqttIntegrationResponse))
          as RegisterMqttIntegrationResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RegisterMqttIntegrationResponse create() =>
      RegisterMqttIntegrationResponse._();
  @$core.override
  RegisterMqttIntegrationResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static RegisterMqttIntegrationResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RegisterMqttIntegrationResponse>(
          create);
  static RegisterMqttIntegrationResponse? _defaultInstance;

  @$pb.TagNumber(1)
  BasicResponse get resp => $_getN(0);
  @$pb.TagNumber(1)
  set resp(BasicResponse value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasResp() => $_has(0);
  @$pb.TagNumber(1)
  void clearResp() => $_clearField(1);
  @$pb.TagNumber(1)
  BasicResponse ensureResp() => $_ensure(0);
}

/// message to unregister an integration
class UnregisterMqttIntegrationRequest extends $pb.GeneratedMessage {
  factory UnregisterMqttIntegrationRequest({
    $core.String? name,
  }) {
    final result = create();
    if (name != null) result.name = name;
    return result;
  }

  UnregisterMqttIntegrationRequest._();

  factory UnregisterMqttIntegrationRequest.fromBuffer(
          $core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory UnregisterMqttIntegrationRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'UnregisterMqttIntegrationRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'cv_saas'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'name')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UnregisterMqttIntegrationRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UnregisterMqttIntegrationRequest copyWith(
          void Function(UnregisterMqttIntegrationRequest) updates) =>
      super.copyWith(
              (message) => updates(message as UnregisterMqttIntegrationRequest))
          as UnregisterMqttIntegrationRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static UnregisterMqttIntegrationRequest create() =>
      UnregisterMqttIntegrationRequest._();
  @$core.override
  UnregisterMqttIntegrationRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static UnregisterMqttIntegrationRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<UnregisterMqttIntegrationRequest>(
          create);
  static UnregisterMqttIntegrationRequest? _defaultInstance;

  /// the name of the integration, specified when registering
  @$pb.TagNumber(1)
  $core.String get name => $_getSZ(0);
  @$pb.TagNumber(1)
  set name($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasName() => $_has(0);
  @$pb.TagNumber(1)
  void clearName() => $_clearField(1);
}

class KVPairItem extends $pb.GeneratedMessage {
  factory KVPairItem({
    $core.String? k,
    $core.String? v,
  }) {
    final result = create();
    if (k != null) result.k = k;
    if (v != null) result.v = v;
    return result;
  }

  KVPairItem._();

  factory KVPairItem.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory KVPairItem.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'KVPairItem',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'cv_saas'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'k')
    ..aOS(2, _omitFieldNames ? '' : 'v')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  KVPairItem clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  KVPairItem copyWith(void Function(KVPairItem) updates) =>
      super.copyWith((message) => updates(message as KVPairItem)) as KVPairItem;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static KVPairItem create() => KVPairItem._();
  @$core.override
  KVPairItem createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static KVPairItem getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<KVPairItem>(create);
  static KVPairItem? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get k => $_getSZ(0);
  @$pb.TagNumber(1)
  set k($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasK() => $_has(0);
  @$pb.TagNumber(1)
  void clearK() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get v => $_getSZ(1);
  @$pb.TagNumber(2)
  set v($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasV() => $_has(1);
  @$pb.TagNumber(2)
  void clearV() => $_clearField(2);
}

class IntegrationItem extends $pb.GeneratedMessage {
  factory IntegrationItem({
    $core.String? bindAddr,
    $core.String? sendAddr,
  }) {
    final result = create();
    if (bindAddr != null) result.bindAddr = bindAddr;
    if (sendAddr != null) result.sendAddr = sendAddr;
    return result;
  }

  IntegrationItem._();

  factory IntegrationItem.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory IntegrationItem.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'IntegrationItem',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'cv_saas'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'bindAddr')
    ..aOS(2, _omitFieldNames ? '' : 'sendAddr')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  IntegrationItem clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  IntegrationItem copyWith(void Function(IntegrationItem) updates) =>
      super.copyWith((message) => updates(message as IntegrationItem))
          as IntegrationItem;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static IntegrationItem create() => IntegrationItem._();
  @$core.override
  IntegrationItem createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static IntegrationItem getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<IntegrationItem>(create);
  static IntegrationItem? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get bindAddr => $_getSZ(0);
  @$pb.TagNumber(1)
  set bindAddr($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasBindAddr() => $_has(0);
  @$pb.TagNumber(1)
  void clearBindAddr() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get sendAddr => $_getSZ(1);
  @$pb.TagNumber(2)
  set sendAddr($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasSendAddr() => $_has(1);
  @$pb.TagNumber(2)
  void clearSendAddr() => $_clearField(2);
}

/// a notification message
class NotificationMessageRequest extends $pb.GeneratedMessage {
  factory NotificationMessageRequest({
    $core.String? msgType,
    $core.Iterable<KVPairItem>? vals,
    IntegrationItem? integration,
  }) {
    final result = create();
    if (msgType != null) result.msgType = msgType;
    if (vals != null) result.vals.addAll(vals);
    if (integration != null) result.integration = integration;
    return result;
  }

  NotificationMessageRequest._();

  factory NotificationMessageRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory NotificationMessageRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'NotificationMessageRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'cv_saas'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'msgType')
    ..pPM<KVPairItem>(2, _omitFieldNames ? '' : 'vals',
        subBuilder: KVPairItem.create)
    ..aOM<IntegrationItem>(3, _omitFieldNames ? '' : 'integration',
        subBuilder: IntegrationItem.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  NotificationMessageRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  NotificationMessageRequest copyWith(
          void Function(NotificationMessageRequest) updates) =>
      super.copyWith(
              (message) => updates(message as NotificationMessageRequest))
          as NotificationMessageRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static NotificationMessageRequest create() => NotificationMessageRequest._();
  @$core.override
  NotificationMessageRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static NotificationMessageRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<NotificationMessageRequest>(create);
  static NotificationMessageRequest? _defaultInstance;

  /// the type of notification message
  @$pb.TagNumber(1)
  $core.String get msgType => $_getSZ(0);
  @$pb.TagNumber(1)
  set msgType($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasMsgType() => $_has(0);
  @$pb.TagNumber(1)
  void clearMsgType() => $_clearField(1);

  @$pb.TagNumber(2)
  $pb.PbList<KVPairItem> get vals => $_getList(1);

  /// if specified, the address to which the message must be sent.
  @$pb.TagNumber(3)
  IntegrationItem get integration => $_getN(2);
  @$pb.TagNumber(3)
  set integration(IntegrationItem value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasIntegration() => $_has(2);
  @$pb.TagNumber(3)
  void clearIntegration() => $_clearField(3);
  @$pb.TagNumber(3)
  IntegrationItem ensureIntegration() => $_ensure(2);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
