/// Minimal async state holder shared by all providers. Avoids pulling in a
/// heavier state library while keeping loading / data / error explicit.
enum ViewStatus { idle, loading, success, error }

class ViewState<T> {
  const ViewState._(this.status, this.data, this.error);

  const ViewState.idle() : this._(ViewStatus.idle, null, null);
  const ViewState.loading() : this._(ViewStatus.loading, null, null);
  const ViewState.success(T data) : this._(ViewStatus.success, data, null);
  const ViewState.error(String error) : this._(ViewStatus.error, null, error);

  final ViewStatus status;
  final T? data;
  final String? error;

  bool get isLoading => status == ViewStatus.loading;
  bool get isSuccess => status == ViewStatus.success;
  bool get isError => status == ViewStatus.error;
}
