import 'package:equatable/equatable.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

abstract class WebSocketState extends Equatable {
  const WebSocketState();

  @override
  List<Object?> get props => [];
}

class WebSocketInitial extends WebSocketState {}

class WebSocketLoading extends WebSocketState {}

class WebSocketLoadSuccess extends WebSocketState {
  final PagingController<int, dynamic> pagingController;

  const WebSocketLoadSuccess({required this.pagingController});

  @override
  List<Object?> get props => [pagingController];
}

class WebSocketLoadFailure extends WebSocketState {
  final String message;

  const WebSocketLoadFailure(this.message);

  @override
  List<Object?> get props => [message];
}

class WebSocketMessageReceived extends WebSocketState {
  final dynamic message;

  const WebSocketMessageReceived(this.message);

  @override
  List<Object?> get props => [message];
}

class WebSocketDisconnected extends WebSocketState {}

class WebSocketError extends WebSocketState {
  final String error;

  const WebSocketError(this.error);

  @override
  List<Object?> get props => [error];
}
