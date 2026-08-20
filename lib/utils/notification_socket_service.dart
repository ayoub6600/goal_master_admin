import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:goal_master_admin/features/notification/data/model/notification_response.dart';
import 'package:goal_master_admin/main.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class NotificationSocketService {
  final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  late IO.Socket _socket;
  final int userId;
  final void Function(NotificationItem notification) onNotificationReceived;
  bool _isConnected = false;

  NotificationSocketService({
    required this.userId,
    required this.onNotificationReceived,
  });

  void initialize() {
    _initializeLocalNotifications();
    _connectToSocket();
  }

  void _initializeLocalNotifications() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await flutterLocalNotificationsPlugin.initialize(initSettings);
  }

  void _connectToSocket() {
    _socket = IO.io('https://socket.goalmasters.online', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
      'reconnection': true,
      'reconnectionAttempts': 5,
      'reconnectionDelay': 2000,
    });

    _socket.on('connect', (_) {
      print('✅ Connected to socket');
      if (!_isConnected) {
        _socket.emit('register', userId);
        _isConnected = true;
      }
    });

    _socket.on('notification', (data) {
      try {
        final payload = _normalizeNotificationPayload(data);
        final notification = NotificationItem.fromJson(payload);
        _showNotification(notification.data.message, '📢 إشعار جديد');
        onNotificationReceived(notification);
      } catch (e) {
        print('❌ Error parsing notification: $e');
      }
    });

    _socket.on('disconnect', (_) {
      print('❌ Disconnected from socket');
      _isConnected = false;
    });

    _socket.on('connect_error', (err) {
      print('⚠️ Socket connection error: $err');
    });

    _socket.on('connect_timeout', (_) {
      print('⏰ Socket connection timeout');
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
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
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

  Future<void> _showNotification(String title, String body) async {
    const androidDetails = AndroidNotificationDetails(
      'admin_channel',
      'إشعارات المشرف',
      channelDescription: 'إشعارات لحظية للمشرفين',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      ticker: 'ticker',
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    await flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      notificationDetails,
    );
  }

  void dispose() {
    _socket.dispose();
  }
}
