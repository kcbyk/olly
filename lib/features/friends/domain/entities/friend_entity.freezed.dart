// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'friend_entity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$FriendEntity {
  String get id => throw _privateConstructorUsedError;
  String get userId => throw _privateConstructorUsedError;
  String get friendId => throw _privateConstructorUsedError;
  String get friendUsername => throw _privateConstructorUsedError;
  String? get friendPhotoUrl => throw _privateConstructorUsedError;
  FriendStatus get status => throw _privateConstructorUsedError;
  bool get isOnline => throw _privateConstructorUsedError;
  DateTime? get lastSeen => throw _privateConstructorUsedError;
  DateTime? get createdAt => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $FriendEntityCopyWith<FriendEntity> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $FriendEntityCopyWith<$Res> {
  factory $FriendEntityCopyWith(
          FriendEntity value, $Res Function(FriendEntity) then) =
      _$FriendEntityCopyWithImpl<$Res, FriendEntity>;
  @useResult
  $Res call(
      {String id,
      String userId,
      String friendId,
      String friendUsername,
      String? friendPhotoUrl,
      FriendStatus status,
      bool isOnline,
      DateTime? lastSeen,
      DateTime? createdAt});
}

/// @nodoc
class _$FriendEntityCopyWithImpl<$Res, $Val extends FriendEntity>
    implements $FriendEntityCopyWith<$Res> {
  _$FriendEntityCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? friendId = null,
    Object? friendUsername = null,
    Object? friendPhotoUrl = freezed,
    Object? status = null,
    Object? isOnline = null,
    Object? lastSeen = freezed,
    Object? createdAt = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      friendId: null == friendId
          ? _value.friendId
          : friendId // ignore: cast_nullable_to_non_nullable
              as String,
      friendUsername: null == friendUsername
          ? _value.friendUsername
          : friendUsername // ignore: cast_nullable_to_non_nullable
              as String,
      friendPhotoUrl: freezed == friendPhotoUrl
          ? _value.friendPhotoUrl
          : friendPhotoUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as FriendStatus,
      isOnline: null == isOnline
          ? _value.isOnline
          : isOnline // ignore: cast_nullable_to_non_nullable
              as bool,
      lastSeen: freezed == lastSeen
          ? _value.lastSeen
          : lastSeen // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$FriendEntityImplCopyWith<$Res>
    implements $FriendEntityCopyWith<$Res> {
  factory _$$FriendEntityImplCopyWith(
          _$FriendEntityImpl value, $Res Function(_$FriendEntityImpl) then) =
      __$$FriendEntityImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String userId,
      String friendId,
      String friendUsername,
      String? friendPhotoUrl,
      FriendStatus status,
      bool isOnline,
      DateTime? lastSeen,
      DateTime? createdAt});
}

/// @nodoc
class __$$FriendEntityImplCopyWithImpl<$Res>
    extends _$FriendEntityCopyWithImpl<$Res, _$FriendEntityImpl>
    implements _$$FriendEntityImplCopyWith<$Res> {
  __$$FriendEntityImplCopyWithImpl(
      _$FriendEntityImpl _value, $Res Function(_$FriendEntityImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? friendId = null,
    Object? friendUsername = null,
    Object? friendPhotoUrl = freezed,
    Object? status = null,
    Object? isOnline = null,
    Object? lastSeen = freezed,
    Object? createdAt = freezed,
  }) {
    return _then(_$FriendEntityImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      friendId: null == friendId
          ? _value.friendId
          : friendId // ignore: cast_nullable_to_non_nullable
              as String,
      friendUsername: null == friendUsername
          ? _value.friendUsername
          : friendUsername // ignore: cast_nullable_to_non_nullable
              as String,
      friendPhotoUrl: freezed == friendPhotoUrl
          ? _value.friendPhotoUrl
          : friendPhotoUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as FriendStatus,
      isOnline: null == isOnline
          ? _value.isOnline
          : isOnline // ignore: cast_nullable_to_non_nullable
              as bool,
      lastSeen: freezed == lastSeen
          ? _value.lastSeen
          : lastSeen // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc

class _$FriendEntityImpl implements _FriendEntity {
  const _$FriendEntityImpl(
      {required this.id,
      required this.userId,
      required this.friendId,
      required this.friendUsername,
      this.friendPhotoUrl,
      this.status = FriendStatus.pending,
      this.isOnline = false,
      this.lastSeen,
      this.createdAt});

  @override
  final String id;
  @override
  final String userId;
  @override
  final String friendId;
  @override
  final String friendUsername;
  @override
  final String? friendPhotoUrl;
  @override
  @JsonKey()
  final FriendStatus status;
  @override
  @JsonKey()
  final bool isOnline;
  @override
  final DateTime? lastSeen;
  @override
  final DateTime? createdAt;

  @override
  String toString() {
    return 'FriendEntity(id: $id, userId: $userId, friendId: $friendId, friendUsername: $friendUsername, friendPhotoUrl: $friendPhotoUrl, status: $status, isOnline: $isOnline, lastSeen: $lastSeen, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$FriendEntityImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.friendId, friendId) ||
                other.friendId == friendId) &&
            (identical(other.friendUsername, friendUsername) ||
                other.friendUsername == friendUsername) &&
            (identical(other.friendPhotoUrl, friendPhotoUrl) ||
                other.friendPhotoUrl == friendPhotoUrl) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.isOnline, isOnline) ||
                other.isOnline == isOnline) &&
            (identical(other.lastSeen, lastSeen) ||
                other.lastSeen == lastSeen) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @override
  int get hashCode => Object.hash(runtimeType, id, userId, friendId,
      friendUsername, friendPhotoUrl, status, isOnline, lastSeen, createdAt);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$FriendEntityImplCopyWith<_$FriendEntityImpl> get copyWith =>
      __$$FriendEntityImplCopyWithImpl<_$FriendEntityImpl>(this, _$identity);
}

abstract class _FriendEntity implements FriendEntity {
  const factory _FriendEntity(
      {required final String id,
      required final String userId,
      required final String friendId,
      required final String friendUsername,
      final String? friendPhotoUrl,
      final FriendStatus status,
      final bool isOnline,
      final DateTime? lastSeen,
      final DateTime? createdAt}) = _$FriendEntityImpl;

  @override
  String get id;
  @override
  String get userId;
  @override
  String get friendId;
  @override
  String get friendUsername;
  @override
  String? get friendPhotoUrl;
  @override
  FriendStatus get status;
  @override
  bool get isOnline;
  @override
  DateTime? get lastSeen;
  @override
  DateTime? get createdAt;
  @override
  @JsonKey(ignore: true)
  _$$FriendEntityImplCopyWith<_$FriendEntityImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
