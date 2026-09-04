import 'package:flutter/widgets.dart';

/// One editable service (pitch) row inside the catalog form.
class ManagerServiceDraft {
  ManagerServiceDraft({
    String title = '',
    String price = '',
    String remarks = '',
    this.slotMinutes = 60,
    this.supportsEvening = true,
    this.supportsAfterMidnight = false,
    this.isNew = true,
  })  : titleController = TextEditingController(text: title),
        priceController = TextEditingController(text: price),
        remarksController = TextEditingController(text: remarks);

  final TextEditingController titleController;
  final TextEditingController priceController;
  final TextEditingController remarksController;
  int slotMinutes;
  bool supportsEvening;
  bool supportsAfterMidnight;

  /// True until the server has told us which bands this pitch belongs to.
  /// A loaded pitch keeps its own bands; a brand-new one takes the default.
  final bool isNew;

  void dispose() {
    titleController.dispose();
    priceController.dispose();
    remarksController.dispose();
  }
}
