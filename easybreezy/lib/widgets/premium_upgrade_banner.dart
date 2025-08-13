import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PremiumUpgradeBanner extends StatefulWidget {
  final VoidCallback? onUpgradeTap;
  final VoidCallback? onDismiss;

  const PremiumUpgradeBanner({
    Key? key,
    this.onUpgradeTap,
    this.onDismiss,
  }) : super(key: key);

  /// Reset the banner dismissal state (useful for testing)
  static Future<void> resetBannerState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('premium_banner_dismissed');
  }

  @override
  State<PremiumUpgradeBanner> createState() => _PremiumUpgradeBannerState();
}

class _PremiumUpgradeBannerState extends State<PremiumUpgradeBanner>
    with SingleTickerProviderStateMixin {
  bool _isVisible = true;
  bool _isDismissed = false;
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<double>(
      begin: -1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    
    _loadBannerState();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadBannerState() async {
    final prefs = await SharedPreferences.getInstance();
    final isDismissed = prefs.getBool('premium_banner_dismissed') ?? false;
    
    if (!isDismissed) {
      setState(() {
        _isVisible = true;
      });
      _animationController.forward();
    } else {
      setState(() {
        _isVisible = false;
        _isDismissed = true;
      });
    }
  }

  Future<void> _dismissBanner() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('premium_banner_dismissed', true);
    
    await _animationController.reverse();
    setState(() {
      _isVisible = false;
      _isDismissed = true;
    });
    
    widget.onDismiss?.call();
  }

  void _handleUpgradeTap() {
    widget.onUpgradeTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isVisible || _isDismissed) {
      return const SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: _slideAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value * 100),
          child: Container(
            height: 110,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Card(
              elevation: 8,
              color: Colors.white,
              surfaceTintColor: Colors.white,
              shadowColor: Colors.black.withOpacity(0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  onTap: _handleUpgradeTap,
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Row(
                      children: [
                      // Left emoji
                      const Text(
                        '🔒',
                        style: TextStyle(fontSize: 28),
                      ),
                      const SizedBox(width: 16),
                      // Main content column
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Text on first line
                            Text(
                              'Unlock Personalized Insights & Max Savings',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Poppins',
                                height: 1.2,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            // Button on second line
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.shade600,
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.amber.shade600.withOpacity(0.3),
                                        offset: const Offset(0, 2),
                                        blurRadius: 4,
                                        spreadRadius: 0,
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Upgrade to Premium',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          fontFamily: 'Poppins',
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Icon(
                                        Icons.arrow_forward,
                                        color: Colors.white,
                                        size: 14,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Dismiss button
                      GestureDetector(
                        onTap: _dismissBanner,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            Icons.close,
                            color: Colors.grey.shade600,
                            size: 18,
                          ),
                        ),
                      ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
