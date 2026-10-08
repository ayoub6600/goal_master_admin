import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import 'package:goal_master_admin/features/manager_setup/data/model/manager_setup_bootstrap_response.dart';
import 'package:goal_master_admin/features/manager_setup/presentation/manager/manager_setup_cubit/manager_setup_cubit.dart';

/// Add/remove photos for exactly ONE sport. Images belong to the service
/// (sch_services), not the physical field — a multi field's sports each
/// keep their own gallery, the simplest option that needs no new data model
/// and matches how the onboarding form already stores images.
class ManagerSportImagesSheet extends StatefulWidget {
  const ManagerSportImagesSheet({
    super.key,
    required this.serviceId,
    required this.sportTitle,
    required this.initialImages,
  });

  final int serviceId;
  final String sportTitle;
  final List<SetupServiceImage> initialImages;

  @override
  State<ManagerSportImagesSheet> createState() =>
      _ManagerSportImagesSheetState();
}

class _ManagerSportImagesSheetState extends State<ManagerSportImagesSheet> {
  static const int _maxImages = 10;
  static const _green = Color(0xFF418A49);
  static const _dark = Color(0xFF20372B);
  static const _muted = Color(0xFF78847C);

  bool _busy = false;

  void _message(String value) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(value), behavior: SnackBarBehavior.floating),
      );
  }

  List<SetupServiceImage> _currentImages(ManagerSetupCubit cubit) {
    final bootstrap = cubit.bootstrapResponse;
    if (bootstrap == null) return widget.initialImages;

    for (final service in bootstrap.data.catalog.services) {
      if (service.id == widget.serviceId) {
        return service.images;
      }
    }

    return widget.initialImages;
  }

  Future<void> _pick(ManagerSetupCubit cubit, int remaining) async {
    if (_busy || remaining <= 0) {
      if (remaining <= 0) {
        _message('يمكن إضافة $_maxImages صور كحد أقصى لكل رياضة.');
      }
      return;
    }

    setState(() => _busy = true);

    try {
      final picked = await ImagePicker().pickMultiImage(imageQuality: 80);
      if (!mounted || picked.isEmpty) return;

      final accepted = picked.take(remaining).toList();

      final error = await cubit.uploadSportImages(
        serviceId: widget.serviceId,
        images: accepted.map((x) => File(x.path)).toList(),
      );

      if (!mounted) return;

      if (error != null) {
        _message(error);
      } else if (picked.length > remaining) {
        _message('تم رفع أول $remaining صور فقط. الحد الأقصى $_maxImages.');
      }
    } catch (_) {
      if (mounted) _message('تعذر اختيار الصور. حاول مرة أخرى.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete(ManagerSetupCubit cubit, int mediaId) async {
    if (_busy) return;
    setState(() => _busy = true);

    final error = await cubit.deleteSportImage(
      serviceId: widget.serviceId,
      mediaId: mediaId,
    );

    if (!mounted) return;
    setState(() => _busy = false);

    if (error != null) _message(error);
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<ManagerSetupCubit>();
    final images = _currentImages(cubit);
    final remaining = _maxImages - images.length;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8E3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              Text(
                'صور ${widget.sportTitle}',
                style: const TextStyle(
                  color: _dark,
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$remaining من $_maxImages متبقية',
                style: const TextStyle(color: _muted, fontSize: 12),
              ),
              const SizedBox(height: 18),
              if (images.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 30),
                  child: Center(child: Text('لا توجد صور بعد')),
                )
              else
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final image in images)
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              image.url,
                              width: 88,
                              height: 88,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: -6,
                            left: -6,
                            child: GestureDetector(
                              onTap: _busy
                                  ? null
                                  : () => _delete(cubit, image.id),
                              child: Container(
                                padding: const EdgeInsets.all(3),
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Color(0x22000000),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.close_rounded,
                                  size: 16,
                                  color: Colors.redAccent,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              const SizedBox(height: 20),
              SizedBox(
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: _busy ? null : () => _pick(cubit, remaining),
                  icon: _busy
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.add_photo_alternate_outlined),
                  label: const Text('إضافة صور'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _green,
                    side: const BorderSide(color: _green),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
