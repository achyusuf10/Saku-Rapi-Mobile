import 'package:freezed_annotation/freezed_annotation.dart';

part 'data_state.freezed.dart';

@freezed
class DataState<T> with _$DataState<T> {
  const DataState._();

  const factory DataState.success({required T data}) = DataStateSuccess<T>;

  const factory DataState.error({
    required String message,
    Exception? exception,
    StackTrace? stackTrace,
    // Ubah namanya di sini agar tidak sama dengan constructor success
    dynamic errorData,
  }) = DataStateError<T>;

  bool isSuccess() {
    return this is DataStateSuccess<T>;
  }

  bool isError() {
    return this is DataStateError<T>;
  }

  T? dataSuccess() {
    if (this is DataStateSuccess<T>) {
      return (this as DataStateSuccess<T>).data;
    }
    return null;
  }

  (String, Exception?, StackTrace?, dynamic)? dataError() {
    if (this is DataStateError<T>) {
      return (
        (this as DataStateError<T>).message,
        (this as DataStateError<T>).exception,
        (this as DataStateError<T>).stackTrace,
        // Jangan lupa sesuaikan di sini juga
        (this as DataStateError<T>).errorData,
      );
    }
    return null;
  }
}
