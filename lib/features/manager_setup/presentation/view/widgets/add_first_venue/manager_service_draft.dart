import 'package:flutter/widgets.dart';
import 'package:goal_master_admin/features/manager_setup/data/model/manager_setup_bootstrap_response.dart';
import 'package:image_picker/image_picker.dart';

/// One editable pitch/service inside the manager catalog form.
///
/// Besides the service fields, this draft owns the gallery state for that
/// specific pitch:
///
/// - [existingImages] are images already stored on the server.
/// - [newImages] are images picked locally and not uploaded yet.
/// - [removedExistingImageIds] are existing images the manager asked to remove.
///
/// Keeping this state on the draft guarantees that images selected for
/// "ملعب رقم 1" cannot accidentally be mixed with "ملعب رقم 2".
class ManagerServiceDraft {
  ManagerServiceDraft({
    this.serviceId,
    String title = '',
    String price = '',
    String remarks = '',
    List<SetupServiceImage>? existingImages,
    List<XFile>? newImages,
    Set<int>? removedExistingImageIds,
    this.slotMinutes = 60,
    this.supportsEvening = true,
    this.supportsAfterMidnight = false,
    this.isNew = true,
  })  : titleController = TextEditingController(text: title),
        priceController = TextEditingController(text: price),
        remarksController = TextEditingController(text: remarks),
        existingImages = List<SetupServiceImage>.from(
          existingImages ?? const <SetupServiceImage>[],
        ),
        newImages = List<XFile>.from(
          newImages ?? const <XFile>[],
        ),
        removedExistingImageIds = Set<int>.from(
          removedExistingImageIds ?? const <int>{},
        );

  /// Null until a brand-new service has been saved by the backend.
  ///
  /// Existing services loaded through bootstrap always have an id.
  int? serviceId;

  final TextEditingController titleController;
  final TextEditingController priceController;
  final TextEditingController remarksController;

  int slotMinutes;
  bool supportsEvening;
  bool supportsAfterMidnight;

  /// Images already saved in Spatie Media Library for this service.
  final List<SetupServiceImage> existingImages;

  /// New local images waiting to be uploaded.
  final List<XFile> newImages;

  /// Existing server images marked for deletion.
  ///
  /// We keep them marked instead of immediately losing the information,
  /// so the eventual save flow can delete the correct media ids.
  final Set<int> removedExistingImageIds;

  /// True until the server has created this pitch/service.
  final bool isNew;

  /// Existing images that should currently be visible in the UI.
  List<SetupServiceImage> get visibleExistingImages {
    return existingImages
        .where(
          (image) => !removedExistingImageIds.contains(image.id),
        )
        .toList(growable: false);
  }

  /// Total visible/pending images for this pitch.
  int get totalVisibleImages =>
      visibleExistingImages.length + newImages.length;

  void addNewImages(Iterable<XFile> images) {
    newImages.addAll(images);
  }

  void removeNewImageAt(int index) {
    if (index < 0 || index >= newImages.length) return;
    newImages.removeAt(index);
  }

  void markExistingImageForRemoval(int mediaId) {
    removedExistingImageIds.add(mediaId);
  }

  void restoreExistingImage(int mediaId) {
    removedExistingImageIds.remove(mediaId);
  }

  void dispose() {
    titleController.dispose();
    priceController.dispose();
    remarksController.dispose();
  }
}
