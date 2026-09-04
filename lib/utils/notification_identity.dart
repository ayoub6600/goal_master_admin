/// A stable identity for one logical notification event, shared by every
/// channel that can deliver it (socket, FCM foreground, REST polling) so
/// [NotificationDedupStore] recognizes the same event arriving twice
/// through two different channels — not just a replay on the same channel.
///
/// Backend notification payloads (SocketNotify's array, SendPushNotification's
/// FCM `data`) consistently carry `id` (a real row id, e.g. a transaction)
/// or `booking_id` alongside a `type`/`status` — see
/// goal-master-web app/Http/Controllers/Api/Booking/BookingController.php.
/// Reusing those, rather than a random per-delivery id, is what makes
/// cross-channel dedup possible without inventing a new backend concept.
class NotificationIdentity {
  NotificationIdentity._();

  static String resolve(Map<String, dynamic> data) {
    final id = data['id'];
    if (id != null && id.toString().isNotEmpty) {
      return 'evt:${id.toString()}';
    }

    final bookingId = data['booking_id'];
    if (bookingId != null && bookingId.toString().isNotEmpty) {
      final type = data['type']?.toString() ?? '';
      final status = data['status']?.toString() ?? '';
      return 'evt:booking:${bookingId.toString()}:$type:$status';
    }

    // No stable id/booking_id available for this event — falls back to a
    // per-delivery id, same as before this fix. It still shows correctly;
    // it just can't be cross-channel-deduped against its FCM/socket twin.
    return 'unstable:${DateTime.now().millisecondsSinceEpoch}';
  }
}
