import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:goal_master_admin/core/components/button_app.dart';
import 'package:goal_master_admin/core/styles/app_colors.dart';
import 'package:goal_master_admin/core/styles/app_text_styles.dart';
import 'package:goal_master_admin/core/styles/spaces.dart';
import 'package:goal_master_admin/features/manager_setup/data/model/manager_setup_bootstrap_response.dart';
import 'package:latlong2/latlong.dart' as latlng;
import 'package:location/location.dart' as device_location;

class LocationPickerResult {
  const LocationPickerResult({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;
}

class LocationPickerView extends StatefulWidget {
  const LocationPickerView({
    super.key,
    this.initialLatitude,
    this.initialLongitude,
    this.zone,
  });

  final double? initialLatitude;
  final double? initialLongitude;
  final ZoneOption? zone;

  @override
  State<LocationPickerView> createState() => _LocationPickerViewState();
}

class _LocationPickerViewState extends State<LocationPickerView> {
  static const _defaultCenter = latlng.LatLng(32.8872, 13.1913); // Tripoli, Libya
  static const _distance = latlng.Distance();

  late final MapController _mapController;
  late latlng.LatLng _center;
  bool _locatingDevice = false;

  latlng.LatLng? _zoneCircleCenter;
  double? _zoneCircleRadius;
  List<latlng.LatLng>? _zonePolygonPoints;

  bool get _hasZoneBoundary => _zoneCircleCenter != null || _zonePolygonPoints != null;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _parseZoneBoundary();

    if (widget.initialLatitude != null && widget.initialLongitude != null) {
      _center = latlng.LatLng(widget.initialLatitude!, widget.initialLongitude!);
    } else if (_zoneCircleCenter != null) {
      _center = _zoneCircleCenter!;
    } else if (_zonePolygonPoints != null && _zonePolygonPoints!.isNotEmpty) {
      _center = _polygonCentroid(_zonePolygonPoints!);
    } else {
      _center = _defaultCenter;
    }
  }

  void _parseZoneBoundary() {
    final zone = widget.zone;
    if (zone == null) return;

    if (zone.boundaryType == 'circle' &&
        zone.centerLat != null &&
        zone.centerLng != null) {
      _zoneCircleCenter = latlng.LatLng(zone.centerLat!, zone.centerLng!);
      _zoneCircleRadius = (zone.radiusMeters ?? 500).toDouble();
    } else if (zone.boundaryType == 'polygon' &&
        (zone.polygonPath ?? '').isNotEmpty) {
      try {
        final decoded = json.decode(zone.polygonPath!) as List<dynamic>;
        _zonePolygonPoints = decoded
            .map((p) => latlng.LatLng(
                  (p['lat'] as num).toDouble(),
                  (p['lng'] as num).toDouble(),
                ))
            .toList();
        if (_zonePolygonPoints!.length < 3) _zonePolygonPoints = null;
      } catch (_) {
        _zonePolygonPoints = null;
      }
    }
  }

  latlng.LatLng _polygonCentroid(List<latlng.LatLng> points) {
    var lat = 0.0, lng = 0.0;
    for (final p in points) {
      lat += p.latitude;
      lng += p.longitude;
    }
    return latlng.LatLng(lat / points.length, lng / points.length);
  }

  bool _isInsideZoneBoundary(latlng.LatLng point) {
    if (_zoneCircleCenter != null) {
      final distanceMeters = _distance.as(
        latlng.LengthUnit.Meter,
        _zoneCircleCenter!,
        point,
      );
      return distanceMeters <= (_zoneCircleRadius ?? 0);
    }

    if (_zonePolygonPoints != null) {
      return _pointInPolygon(point, _zonePolygonPoints!);
    }

    return true;
  }

  bool _pointInPolygon(latlng.LatLng point, List<latlng.LatLng> points) {
    var inside = false;
    final count = points.length;

    for (var i = 0, j = count - 1; i < count; j = i++) {
      final pi = points[i];
      final pj = points[j];

      final intersects = ((pi.longitude > point.longitude) !=
              (pj.longitude > point.longitude)) &&
          (point.latitude <
              (pj.latitude - pi.latitude) *
                      (point.longitude - pi.longitude) /
                      (pj.longitude - pi.longitude) +
                  pi.latitude);

      if (intersects) inside = !inside;
    }

    return inside;
  }

  void _goToZone() {
    latlng.LatLng target;
    double zoom;

    if (_zoneCircleCenter != null) {
      target = _zoneCircleCenter!;
      zoom = _zoomForRadius(_zoneCircleRadius ?? 500);
    } else if (_zonePolygonPoints != null && _zonePolygonPoints!.isNotEmpty) {
      target = _polygonCentroid(_zonePolygonPoints!);
      zoom = 13;
    } else {
      return;
    }

    _mapController.move(target, zoom);
  }

  double _zoomForRadius(double radiusMeters) {
    if (radiusMeters <= 1000) return 15;
    if (radiusMeters <= 3000) return 14;
    if (radiusMeters <= 8000) return 13;
    if (radiusMeters <= 20000) return 12;
    return 11;
  }

  Future<void> _useDeviceLocation() async {
    setState(() => _locatingDevice = true);
    try {
      final location = device_location.Location();

      var serviceEnabled = await location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await location.requestService();
        if (!serviceEnabled) return;
      }

      var permission = await location.hasPermission();
      if (permission == device_location.PermissionStatus.denied) {
        permission = await location.requestPermission();
        if (permission != device_location.PermissionStatus.granted &&
            permission != device_location.PermissionStatus.grantedLimited) {
          return;
        }
      }

      final currentLocation = await location.getLocation();
      if (currentLocation.latitude == null || currentLocation.longitude == null) {
        return;
      }

      final newCenter = latlng.LatLng(
        currentLocation.latitude!,
        currentLocation.longitude!,
      );

      if (!mounted) return;
      setState(() => _center = newCenter);
      _mapController.move(newCenter, 16);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر تحديد موقعك الحالي، حاول مرة أخرى.')),
      );
    } finally {
      if (mounted) setState(() => _locatingDevice = false);
    }
  }

  void _confirmLocation() {
    if (_hasZoneBoundary && !_isInsideZoneBoundary(_center)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'هذا الموقع يقع خارج حدود منطقة "${widget.zone?.name ?? ''}". اختر موقعًا داخل الحدود الموضحة باللون الأخضر على الخريطة.',
          ),
        ),
      );
      return;
    }

    Navigator.of(context).pop(
      LocationPickerResult(
        latitude: _center.latitude,
        longitude: _center.longitude,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isOutsideZone = _hasZoneBoundary && !_isInsideZoneBoundary(_center);

    return Scaffold(
      appBar: AppBar(
        title: Text('تحديد موقع الملعب', style: AppTextStyles.font16Bold),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _center,
              initialZoom: _hasZoneBoundary ? 12 : 14,
              onPositionChanged: (position, hasGesture) {
                if (hasGesture) {
                  setState(() => _center = position.center);
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.goalmaster.manager',
              ),
              if (_zoneCircleCenter != null)
                CircleLayer(
                  circles: [
                    CircleMarker(
                      point: _zoneCircleCenter!,
                      radius: _zoneCircleRadius ?? 500,
                      useRadiusInMeter: true,
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderColor: AppColors.primary,
                      borderStrokeWidth: 2,
                    ),
                  ],
                ),
              if (_zonePolygonPoints != null)
                PolygonLayer(
                  polygons: [
                    Polygon(
                      points: _zonePolygonPoints!,
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderColor: AppColors.primary,
                      borderStrokeWidth: 2,
                    ),
                  ],
                ),
            ],
          ),
          const IgnorePointer(
            child: Center(
              child: _StadiumPinMarker(),
            ),
          ),
          if (widget.zone != null)
            Positioned(
              top: 10.h,
              left: 16.w,
              right: 16.w,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12.r),
                  boxShadow: const [
                    BoxShadow(color: Colors.black26, blurRadius: 6),
                  ],
                ),
                child: Text(
                  !_hasZoneBoundary
                      ? 'منطقة "${widget.zone!.name}" لا تملك حدودًا مرسومة بعد، يمكنك اختيار أي موقع.'
                      : isOutsideZone
                          ? 'هذا الموقع خارج حدود منطقة "${widget.zone!.name}". حرّك الخريطة لتضع الدبوس داخل الدائرة الخضراء.'
                          : 'اختر موقعًا داخل حدود منطقة "${widget.zone!.name}" الموضحة على الخريطة.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.font12Medium.copyWith(
                    color: isOutsideZone ? Colors.redAccent : null,
                  ),
                ),
              ),
            ),
          if (_hasZoneBoundary)
            Positioned(
              top: widget.zone != null ? 60.h : 10.h,
              right: 16.w,
              child: Material(
                color: Colors.white,
                shape: const CircleBorder(),
                elevation: 3,
                child: IconButton(
                  tooltip: 'الذهاب إلى المنطقة',
                  icon: Icon(Icons.center_focus_strong, color: AppColors.primary),
                  onPressed: _goToZone,
                ),
              ),
            ),
          Positioned(
            left: 16.w,
            right: 16.w,
            bottom: 16.h,
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(
                      horizontal: 14.w, vertical: 10.h),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14.r),
                    boxShadow: const [
                      BoxShadow(color: Colors.black26, blurRadius: 8),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.pin_drop_outlined,
                          color: AppColors.primary, size: 18.sp),
                      WidthSpace(8.w),
                      Expanded(
                        child: Text(
                          '${_center.latitude.toStringAsFixed(6)}, ${_center.longitude.toStringAsFixed(6)}',
                          style: AppTextStyles.font12Medium,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _locatingDevice ? null : _useDeviceLocation,
                        icon: _locatingDevice
                            ? SizedBox(
                                width: 14.w,
                                height: 14.w,
                                child: const CircularProgressIndicator(
                                    strokeWidth: 2),
                              )
                            : const Icon(Icons.my_location, size: 16),
                        label: const Text('موقعي الحالي'),
                      ),
                    ],
                  ),
                ),
                HeightSpace(10.h),
                ButtonApp(
                  text: isOutsideZone
                      ? 'اختر موقعًا داخل المنطقة أولاً'
                      : 'تأكيد هذا الموقع',
                  backGround: isOutsideZone ? Colors.grey : null,
                  onTap: isOutsideZone ? null : _confirmLocation,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StadiumPinMarker extends StatelessWidget {
  const _StadiumPinMarker();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 42),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                Icons.location_on,
                size: 54,
                color: AppColors.primary,
                shadows: const [
                  Shadow(
                    color: Colors.black38,
                    blurRadius: 6,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 17),
                child: Container(
                  width: 26,
                  height: 26,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.sports_soccer,
                    size: 17,
                    color: Color(0xff1E4B31),
                  ),
                ),
              ),
            ],
          ),
          Container(
            width: 16,
            height: 6,
            margin: const EdgeInsets.only(top: 2),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.28),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ],
      ),
    );
  }
}
