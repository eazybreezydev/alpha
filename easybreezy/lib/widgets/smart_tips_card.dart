import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/quick_tips_provider.dart';

class SmartTipsCard extends StatelessWidget {
  const SmartTipsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<QuickTipsProvider>(
      builder: (context, tipsProvider, child) {
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 16), // Match other widgets' margins
          child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(12), // Minimal internal padding
              child: _buildContent(tipsProvider),
            ),
          ),
        );
      },
    );
  }

  Widget _buildContent(QuickTipsProvider tipsProvider) {
    if (tipsProvider.isLoading) {
      return SizedBox(
        height: 120,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade600),
              ),
              const SizedBox(height: 16),
              Text(
                'Loading smart tips...',
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

    if (tipsProvider.error != null) {
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
                tipsProvider.error!,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => tipsProvider.refreshTips(),
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

    if (!tipsProvider.hasTips) {
      return SizedBox(
        height: 120,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lightbulb_outline,
                color: Colors.grey.shade400,
                size: 32,
              ),
              const SizedBox(height: 8),
              Text(
                'No tips available',
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

    final currentTip = tipsProvider.currentTip!;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with icon and tip indicator
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.lightbulb,
                color: Colors.blue.shade600,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Smart Tip',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
            ),
            if (tipsProvider.tips.length > 1)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${tipsProvider.tips.indexOf(currentTip) + 1}/${tipsProvider.tips.length}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.swipe_left,
                      size: 14,
                      color: Colors.grey.shade500,
                    ),
                  ],
                ),
              ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Tip content (no expand/collapse functionality)
        GestureDetector(
          onHorizontalDragEnd: (details) {
            // Only handle swipes if there are multiple tips
            if (tipsProvider.tips.length > 1) {
              // Swipe threshold
              const double swipeThreshold = 100.0;
              
              if (details.primaryVelocity != null) {
                if (details.primaryVelocity! > swipeThreshold) {
                  // Swipe right - go to previous tip
                  tipsProvider.previousTip();
                } else if (details.primaryVelocity! < -swipeThreshold) {
                  // Swipe left - go to next tip
                  tipsProvider.nextTip();
                }
              }
            }
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                currentTip.headline,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                  height: 1.3,
                ),
                overflow: TextOverflow.visible,
              ),
              
              const SizedBox(height: 8),
              
              Text(
                currentTip.excerpt,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  height: 1.4,
                ),
                overflow: TextOverflow.visible,
              ),
              
              const SizedBox(height: 8),
              
              // Only show sponsor info if available
              if (currentTip.sponsor != null && currentTip.sponsor!.isNotEmpty)
                Text(
                  'Sponsored by ${currentTip.sponsor}',
                  style: TextStyle(
                    fontSize: 14, // Increased from 12 to 14 for better readability
                    color: Colors.grey.shade800, // Much darker for better visibility
                    fontStyle: FontStyle.italic,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
      ],
    );
  }
}
