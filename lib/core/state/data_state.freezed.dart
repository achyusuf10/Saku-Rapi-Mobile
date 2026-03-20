// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'data_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$DataState<T> {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DataState<T>);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'DataState<$T>()';
}


}

/// @nodoc
class $DataStateCopyWith<T,$Res>  {
$DataStateCopyWith(DataState<T> _, $Res Function(DataState<T>) __);
}


/// Adds pattern-matching-related methods to [DataState].
extension DataStatePatterns<T> on DataState<T> {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( DataStateSuccess<T> value)?  success,TResult Function( DataStateError<T> value)?  error,required TResult orElse(),}){
final _that = this;
switch (_that) {
case DataStateSuccess() when success != null:
return success(_that);case DataStateError() when error != null:
return error(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( DataStateSuccess<T> value)  success,required TResult Function( DataStateError<T> value)  error,}){
final _that = this;
switch (_that) {
case DataStateSuccess():
return success(_that);case DataStateError():
return error(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( DataStateSuccess<T> value)?  success,TResult? Function( DataStateError<T> value)?  error,}){
final _that = this;
switch (_that) {
case DataStateSuccess() when success != null:
return success(_that);case DataStateError() when error != null:
return error(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( T data)?  success,TResult Function( String message,  Exception? exception,  StackTrace? stackTrace,  dynamic errorData)?  error,required TResult orElse(),}) {final _that = this;
switch (_that) {
case DataStateSuccess() when success != null:
return success(_that.data);case DataStateError() when error != null:
return error(_that.message,_that.exception,_that.stackTrace,_that.errorData);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( T data)  success,required TResult Function( String message,  Exception? exception,  StackTrace? stackTrace,  dynamic errorData)  error,}) {final _that = this;
switch (_that) {
case DataStateSuccess():
return success(_that.data);case DataStateError():
return error(_that.message,_that.exception,_that.stackTrace,_that.errorData);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( T data)?  success,TResult? Function( String message,  Exception? exception,  StackTrace? stackTrace,  dynamic errorData)?  error,}) {final _that = this;
switch (_that) {
case DataStateSuccess() when success != null:
return success(_that.data);case DataStateError() when error != null:
return error(_that.message,_that.exception,_that.stackTrace,_that.errorData);case _:
  return null;

}
}

}

/// @nodoc


class DataStateSuccess<T> extends DataState<T> {
  const DataStateSuccess({required this.data}): super._();
  

 final  T data;

/// Create a copy of DataState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DataStateSuccessCopyWith<T, DataStateSuccess<T>> get copyWith => _$DataStateSuccessCopyWithImpl<T, DataStateSuccess<T>>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DataStateSuccess<T>&&const DeepCollectionEquality().equals(other.data, data));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(data));

@override
String toString() {
  return 'DataState<$T>.success(data: $data)';
}


}

/// @nodoc
abstract mixin class $DataStateSuccessCopyWith<T,$Res> implements $DataStateCopyWith<T, $Res> {
  factory $DataStateSuccessCopyWith(DataStateSuccess<T> value, $Res Function(DataStateSuccess<T>) _then) = _$DataStateSuccessCopyWithImpl;
@useResult
$Res call({
 T data
});




}
/// @nodoc
class _$DataStateSuccessCopyWithImpl<T,$Res>
    implements $DataStateSuccessCopyWith<T, $Res> {
  _$DataStateSuccessCopyWithImpl(this._self, this._then);

  final DataStateSuccess<T> _self;
  final $Res Function(DataStateSuccess<T>) _then;

/// Create a copy of DataState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? data = freezed,}) {
  return _then(DataStateSuccess<T>(
data: freezed == data ? _self.data : data // ignore: cast_nullable_to_non_nullable
as T,
  ));
}


}

/// @nodoc


class DataStateError<T> extends DataState<T> {
  const DataStateError({required this.message, this.exception, this.stackTrace, this.errorData}): super._();
  

 final  String message;
 final  Exception? exception;
 final  StackTrace? stackTrace;
// Ubah namanya di sini agar tidak sama dengan constructor success
 final  dynamic errorData;

/// Create a copy of DataState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DataStateErrorCopyWith<T, DataStateError<T>> get copyWith => _$DataStateErrorCopyWithImpl<T, DataStateError<T>>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DataStateError<T>&&(identical(other.message, message) || other.message == message)&&(identical(other.exception, exception) || other.exception == exception)&&(identical(other.stackTrace, stackTrace) || other.stackTrace == stackTrace)&&const DeepCollectionEquality().equals(other.errorData, errorData));
}


@override
int get hashCode => Object.hash(runtimeType,message,exception,stackTrace,const DeepCollectionEquality().hash(errorData));

@override
String toString() {
  return 'DataState<$T>.error(message: $message, exception: $exception, stackTrace: $stackTrace, errorData: $errorData)';
}


}

/// @nodoc
abstract mixin class $DataStateErrorCopyWith<T,$Res> implements $DataStateCopyWith<T, $Res> {
  factory $DataStateErrorCopyWith(DataStateError<T> value, $Res Function(DataStateError<T>) _then) = _$DataStateErrorCopyWithImpl;
@useResult
$Res call({
 String message, Exception? exception, StackTrace? stackTrace, dynamic errorData
});




}
/// @nodoc
class _$DataStateErrorCopyWithImpl<T,$Res>
    implements $DataStateErrorCopyWith<T, $Res> {
  _$DataStateErrorCopyWithImpl(this._self, this._then);

  final DataStateError<T> _self;
  final $Res Function(DataStateError<T>) _then;

/// Create a copy of DataState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,Object? exception = freezed,Object? stackTrace = freezed,Object? errorData = freezed,}) {
  return _then(DataStateError<T>(
message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,exception: freezed == exception ? _self.exception : exception // ignore: cast_nullable_to_non_nullable
as Exception?,stackTrace: freezed == stackTrace ? _self.stackTrace : stackTrace // ignore: cast_nullable_to_non_nullable
as StackTrace?,errorData: freezed == errorData ? _self.errorData : errorData // ignore: cast_nullable_to_non_nullable
as dynamic,
  ));
}


}

// dart format on
