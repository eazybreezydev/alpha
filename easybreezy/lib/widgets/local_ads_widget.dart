import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/local_ads_provider.dart';
import '../services/airtable_service.dart';

class LocalAdsWidget extends StatelessWidget {
  const LocalAdsWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<LocalAdsProvider>(
      builder: (context, adsProvider, child) {
        return Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Content
              Padding(
                padding: const EdgeInsets.all(16),
                child: _buildContent(context, adsProvider),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildContent(BuildContext context, LocalAdsProvider adsProvider) {
    if (adsProvider.isLoading) {
      return const SizedBox(
        height: 120,
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (adsProvider.error != null) {
      return SizedBox(
        height: 120,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                color: Colors.grey.shade400,
                size: 32,
              ),
              const SizedBox(height: 8),
              Text(
                adsProvider.error!,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => adsProvider.refreshAds(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (!adsProvider.hasAds) {
      return SizedBox(
        height: 120,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.local_offer_outlined,
                color: Colors.grey.shade400,
                size: 32,
              ),
              const SizedBox(height: 8),
              Text(
                'No local offers available',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final currentAd = adsProvider.currentAd!;
    
    return _buildAdContent(context, currentAd, adsProvider);
  }

  Widget _buildAdContent(BuildContext context, LocalAd ad, LocalAdsProvider adsProvider) {
    return GestureDetector(
      onTap: () => _handleAdTap(context, ad, adsProvider),
      onHorizontalDragEnd: (details) {
        // Only handle swipes if there are multiple ads
        if (adsProvider.ads.length > 1) {
          // Swipe threshold
          const double swipeThreshold = 100.0;
          
          if (details.primaryVelocity != null) {
            if (details.primaryVelocity! > swipeThreshold) {
              // Swipe right - go to previous ad
              adsProvider.previousAd();
            } else if (details.primaryVelocity! < -swipeThreshold) {
              // Swipe left - go to next ad
              adsProvider.nextAd();
            }
          }
        }
      },
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              // Left: Text content (60%)
              Expanded(
                flex: 6,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ad.headline,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      ad.description,
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.black87,
                        height: 1.4,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (ad.url != null && ad.url!.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.black87, width: 1),
                            ),
                            child: const Text(
                              'Learn More',
                              style: TextStyle(
                                color: Colors.black87,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        if (ad.city != null || ad.province != null) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                size: 14,
                                color: Colors.grey.shade600,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                [ad.city, ad.province]
                                    .where((s) => s != null && s.isNotEmpty)
                                    .join(', '),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              
              // Right: Image (40%)
              if (ad.attachments.isNotEmpty) ...[
                const SizedBox(width: 16),
                Expanded(
                  flex: 4,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: AspectRatio(
                      aspectRatio: 1, // Square aspect ratio for right side image
                      child: Image.network(
                        ad.attachments.first,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.image_not_supported,
                                color: Colors.grey,
                                size: 24,
                              ),
                            ),
                          );
                        },
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleAdTap(BuildContext context, LocalAd ad, LocalAdsProvider adsProvider) async {
    // Track the click
    await adsProvider.trackAdClick(ad);
    
    // Open URL if available
    if (ad.url != null && ad.url!.isNotEmpty) {
      try {
        final uri = Uri.parse(ad.url!);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Unable to open link'),
                duration: Duration(seconds: 2),
              ),
            );
          }
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Invalid link'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    }
  }
}
