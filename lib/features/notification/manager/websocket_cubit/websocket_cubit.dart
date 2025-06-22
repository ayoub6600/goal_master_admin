import 'dart:async';
import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

import 'websocket_state.dart';

class WebSocketCubit extends Cubit<WebSocketState> {
  final String socketUrl;
  late WebSocketChannel _channel;
  late PagingController<int, dynamic> _pagingController;
  StreamSubscription? _subscription;

  bool _isDisposed = false;

  PagingController<int, dynamic> get pagingController => _pagingController;

  WebSocketCubit(this.socketUrl) : super(WebSocketInitial()) {
    _pagingController = PagingController(firstPageKey: 1);
    _pagingController.addPageRequestListener(_fetchPage);
    connect();
    emit(WebSocketLoadSuccess(pagingController: _pagingController));
  }

  void connect() {
    try {
      _channel = WebSocketChannel.connect(Uri.parse(socketUrl));

      _subscription = _channel.stream.listen(
        (data) {
          try {
            final decoded = jsonDecode(data);

            if (_isDisposed) return;
            final current = _pagingController.itemList ?? [];
            _pagingController.itemList = [decoded, ...current];

            emit(WebSocketLoadSuccess(pagingController: _pagingController));
            emit(WebSocketMessageReceived(decoded));
          } catch (e) {
            emit(WebSocketError("Error decoding data: $e"));
          }
        },
        onError: (error) {
          emit(WebSocketError(error.toString()));
        },
        onDone: () {
          emit(WebSocketDisconnected());
        },
      );
    } catch (e) {
      emit(WebSocketError(e.toString()));
    }
  }

  Future<void> _fetchPage(int pageKey) async {
    // حاليًا مش فيه paging من backend -- بنتركها فاضية
  }

  void refresh() {
    if (_isDisposed) return;
    _pagingController.refresh();
    emit(WebSocketLoading());
  }

  void sendMessage(dynamic message) {
    try {
      _channel.sink.add(jsonEncode(message));
    } catch (e) {
      emit(WebSocketError(e.toString()));
    }
  }

  void disconnect() {
    _subscription?.cancel();
    _channel.sink.close();
    emit(WebSocketDisconnected());
  }

  @override
  Future<void> close() {
    _isDisposed = true;
    disconnect();
    _pagingController.dispose();
    return super.close();
  }
}
