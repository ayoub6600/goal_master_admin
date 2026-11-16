import 'package:flutter/foundation.dart';
import 'package:goal_master_admin/core/databases/api/dio_consumer.dart';
import 'package:goal_master_admin/core/databases/api/end_points.dart';
import 'package:goal_master_admin/core/services/service_locator.dart';
import 'package:goal_master_admin/features/notification/data/model/notification_response.dart';
import 'package:goal_master_admin/utils/notification_identity.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

/// Receives and forwards real-time notification events. Deliberately does
/// NOT display anything itself — [NotificationCubit] owns that, since it is
/// the one place with the richer title/body/big-picture/navigation payload
/// and the persisted dedup gate. A socket event that also got shown here,
/// unconditionally, on top of the cubit's own display, was one real event
/// producing two visible system notifications.
class NotificationSocketService {
  // Nullable rather than `late`: only assigned once `initialize()` actually
  // connects, and `dispose()` must be safe to call whether or not it did
  // (e.g. a cubit closed before the socket was ever started).
  IO.Socket? _socket;
  final int userId;
  final void Function(NotificationItem notification) onNotificationReceived;
  bool _isConnected = false;

  /// Whether the live channel is up and registered for this user.
  bool get isConnected => _isConnected;

  /// Fetches the signed socket pass. Injectable for tests; defaults to the
  /// API.
  final Future<Map<String, dynamic>?> Function() _passProvider;
  bool _disposed = false;

  NotificationSocketService({
    required this.userId,
    required this.onNotificationReceived,
    Future<Map<String, dynamic>?> Function()? passProvider,
  }) : _passProvider = passProvider ?? _fetchPass;

  static Future<Map<String, dynamic>?> _fetchPass() async {
    try {
      final res = await getIt<DioConsumer>().get(EndPoints.socketToken);
      final data = res is Map ? res['data'] : null;
      return data is Map ? Map<String, dynamic>.from(data) : null;
    } catch (_) {
      return null;
    }
  }

  /// The socket joins a user's room only with a pass the server signed for
  /// that user — it used to take any id it was given, so anyone could listen
  /// to anyone's notifications. Asked for on every (re)connect, so an expired
  /// pass is never reused. Until the server confirms, [isConnected] stays
  /// false and the cubit keeps polling.
  Future<void> _register(IO.Socket socket) async {
    final pass = await _passProvider();
    if (_disposed || pass == null) return;
    socket.emit('register', pass);
  }

  void initialize() {
    _connectToSocket();
  }

  void _connectToSocket() {
    // Local, non-nullable reference: avoids repeated `!`/`?` noise below
    // while still leaving `_socket` itself nullable for `dispose()`.
    final socket = IO.io('https://socket.goalmaster.aljidartech.com', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
      'reconnection': true,
      'reconnectionAttempts': 5,
      'reconnectionDelay': 2000,
    });
    _socket = socket;

    socket.on('connect', (_) => _register(socket));
    socket.on('registered', (_) => _isConnected = true);
    socket.on('register_error', (_) => _isConnected = false);

    socket.on('notification', (data) {
      try {
        final payload = _normalizeNotificationPayload(data);
        final notification = NotificationItem.fromJson(payload);

        // Forwarded unconditionally — including a (re)connect replay of the
        // latest notification, which happens on every app restart.
        // `onNotificationReceived` (NotificationCubit) is the one place
        // that decides whether this id has already been shown and, if not,
        // shows and displays it. Deciding twice — once here, once there —
        // is exactly how one event produced two visible alerts before.
        onNotificationReceived(notification);
      } catch (e) {
        debugPrint('❌ Error parsing notification: $e');
      }
    });

    socket.on('disconnect', (_) {
      debugPrint('❌ Disconnected from socket');
      _isConnected = false;
    });

    socket.on('connect_error', (err) {
      debugPrint('⚠️ Socket connection error: $err');
    });

    socket.on('connect_timeout', (_) {
      debugPrint('⏰ Socket connection timeout');
    });
  }

  Map<String, dynamic> _normalizeNotificationPayload(dynamic raw) {
    if (raw is Map<String, dynamic> && raw.containsKey('data')) {
      return raw;
    }

    final map = (raw as Map).cast<String, dynamic>();
    final messageData = (map['message'] as Map?)?.cast<String, dynamic>() ??
        <String, dynamic>{};

    return {
      // A stable id (shared with the FCM/database copy of the same event
      // where the backend payload allows it) rather than a random one per
      // delivery — otherwise a socket + FCM delivery of the same event can
      // never be recognized as the same event by NotificationDedupStore.
      'id': NotificationIdentity.resolve(messageData),
      'type': 'socket_notification',
      'notifiable_type': 'socket',
      'notifiable_id': userId,
      'read_at': null,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
      'data': {
        'message': messageData['message']?.toString() ??
            messageData['msg']?.toString() ??
            map['sender']?.toString() ??
            'إشعار جديد',
        'id': _extractBookingId(messageData['id']),
        'booking_id': _extractBookingId(messageData['booking_id']) ??
            _extractBookingId(messageData['id']),
        'type': messageData['type']?.toString(),
      },
    };
  }

  int? _extractBookingId(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is Map) {
      final id = value['id'];
      if (id is int) return id;
      return int.tryParse(id?.toString() ?? '');
    }
    return int.tryParse(value.toString());
  }

  void dispose() {
    _disposed = true;
    _socket?.dispose();
  }
}
