import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:goal_master_admin/core/components/custom_failure_toast.dart';
import 'package:goal_master_admin/core/styles/app_colors.dart';
import 'package:goal_master_admin/core/styles/app_text_styles.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:goal_master_admin/features/home/data/model/banner_model.dart';
import 'package:goal_master_admin/features/home/presentation/manager/banner_cubit/banner_cubit.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';

class BannerCarouselScreen extends StatefulWidget {
  const BannerCarouselScreen({super.key});

  @override
  State<BannerCarouselScreen> createState() => _BannerCarouselScreenState();
}

class _BannerCarouselScreenState extends State<BannerCarouselScreen> {
  final CarouselSliderController _carouselController =
      CarouselSliderController();
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BannerCubitCubit, BannerCubitState>(
      builder: (context, state) {
        if (state is BannerCubitLoading) {
          return _buildLoadingState();
        } else if (state is BannerCubitError) {
          return _buildErrorState(state.message);
        } else if (state is BannerCubitLoaded) {
          final activeSlides =
              state.slideModel.where((e) => e.status == "active").toList();
          return _buildCarousel(activeSlides);
        }

        return const SizedBox();
      },
    );
  }

  Widget _buildLoadingState() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Container(
        height: 150,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Container(
      height: 150,
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red[200]!),
      ),
      //   padding: const EdgeInsets.all(16),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 32),
            const SizedBox(height: 8),
            Text(
              "خطأ: $message",
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCarousel(List<Slide> slides) {
    if (slides.isEmpty) return const SizedBox();

    return Column(
      children: [
        CarouselSlider.builder(
          carouselController: _carouselController,
          itemCount: slides.length,
          itemBuilder: (context, index, realIndex) {
            final slide = slides[index];
            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CachedNetworkImage(
                      imageUrl: slide.image ?? "",
                      fit: BoxFit.contain,
                      placeholder: (context, url) => Container(
                        color: Colors.grey[200],
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey[200],
                        child: const Center(child: Icon(Icons.broken_image)),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              Colors.black.withOpacity(0.8),
                              Colors.transparent,
                            ],
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              slide.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              slide.description ?? "",
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 14,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            slide.url == null
                                ? const SizedBox()
                                : GestureDetector(
                                    onTap: () => _handleSlideTap(slide),
                                    child: Container(
                                      width: 100.w,
                                      alignment: Alignment.center,
                                      padding: EdgeInsets.symmetric(
                                          vertical: 8.h, horizontal: 16.w),
                                      decoration: BoxDecoration(
                                        color: Color(0xff418946),
                                        borderRadius:
                                            BorderRadius.circular(12.r),
                                      ),
                                      child: Center(
                                        child: Text(
                                          "اذهب",
                                          style:
                                              AppTextStyles.font16Bold.copyWith(
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
          options: CarouselOptions(
            height: 220,
            autoPlay: true,
            enlargeCenterPage: true,
            viewportFraction: 0.92,
            aspectRatio: 16 / 9,
            autoPlayInterval: const Duration(seconds: 5),
            autoPlayAnimationDuration: const Duration(milliseconds: 800),
            pauseAutoPlayOnTouch: true,
            onPageChanged: (index, reason) {
              setState(() {
                _currentIndex = index;
              });
            },
          ),
        ),
        const SizedBox(height: 16),
        AnimatedSmoothIndicator(
          activeIndex: _currentIndex,
          count: slides.length,
          effect: ExpandingDotsEffect(
            dotHeight: 8,
            dotWidth: 8,
            spacing: 6,
            activeDotColor: AppColors.primary,
            dotColor: Colors.grey.shade400,
          ),
          // onDotClicked: (index) {
          //   _carouselController.animateToPage(index);
          // },
        ),
      ],
    );
  }

  Future<void> _handleSlideTap(Slide slide) async {
    final url = slide.url?.trim() ?? '';

    if (url.isEmpty) return;

    final uri = Uri.tryParse(url);
    if (uri == null) {
      showCustomFailureToast("صيغة الرابط غير صحيحة");
      return;
    }

    try {
      final canLaunch = await canLaunchUrl(uri);
      if (!canLaunch) {
        showCustomFailureToast("لا يوجد تطبيق متاح لفتح الرابط");
        return;
      }

      final success = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication, // أفضل دعم لـ Android و iOS
      );

      if (!success) {
        showCustomFailureToast("تعذر فتح الرابط");
      }
    } catch (e) {
      showCustomFailureToast("حدث خطأ: ${e.toString()}");
    }
  }
}

Future<void> launchCustomTab(String url) async {
  try {
    final uri = Uri.parse(url);

    // محاولة فتح الرابط في متصفح خارجي
    if (await canLaunchUrl(uri)) {
      await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
        webOnlyWindowName: '_blank', // يساعد في فتح نافذة جديدة
      );
    } else {
      throw 'Could not launch $url';
    }
  } catch (e) {
    print('Error launching URL: $e');
    // يمكنك عرض رسالة خطأ للمستخدم هنا
  }
}
