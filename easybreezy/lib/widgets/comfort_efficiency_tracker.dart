import 'package:flutter/material.dart';
import '../models/comfort_efficiency_model.dart';

class ComfortEfficiencyTracker extends StatefulWidget {
  final ComfortEfficiencyModel efficiencyData;
  final VoidCallback? onUpgradeTapped;

  const ComfortEfficiencyTracker({
    Key? key,
    required this.efficiencyData,
    this.onUpgradeTapped,
  }) : super(key: key);

  @override
  State<ComfortEfficiencyTracker> createState() => _ComfortEfficiencyTrackerState();
}

class _ComfortEfficiencyTrackerState extends State<ComfortEfficiencyTracker>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _percentageAnimation;
  late Animation<double> _savingsAnimation;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
    ));

    _percentageAnimation = Tween<double>(
      begin: 0.0,
      end: widget.efficiencyData.acAvoidancePercentage,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.3, 0.8, curve: Curves.easeOut),
    ));

    _savingsAnimation = Tween<double>(
      begin: 0.0,
      end: widget.efficiencyData.estimatedSavings,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
    ));

    // Start animation after widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _animationController.forward();
    });
  }

  @override
  void dispose() {
    if (_animationController.isAnimating || !_animationController.isCompleted) {
      _animationController.stop();
    }
    _animationController.dispose();
    super.dispose();
  }

  void _showPremiumUpgrade() {
    if (widget.onUpgradeTapped != null) {
      widget.onUpgradeTapped!();
    } else {
      // Default behavior - show modal
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: Colors.white,
            title: const Text(
              'Upgrade to Premium',
              style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
            ),
            content: const Text(
              'Get detailed energy insights, track your savings over time, and unlock advanced features to optimize your home\'s energy efficiency.',
              style: TextStyle(color: Colors.black87),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Maybe Later'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  // TODO: Navigate to premium upgrade page
                },
                child: const Text('Upgrade Now'),
              ),
            ],
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isHighSavings = widget.efficiencyData.estimatedSavings > 10.0;
    
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: [
                  Colors.green.shade50,
                  Colors.white,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header with icon
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.green.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.eco,
                                color: Colors.green.shade700,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Energy Saving Insights',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  Text(
                                    '${widget.efficiencyData.month} Summary',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Natural ventilation icon
                            Text(
                              '💨',
                              style: TextStyle(fontSize: 20),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // AC Avoidance Percentage
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.blue.shade100),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.ac_unit_outlined,
                                color: Colors.blue.shade600,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'AC Avoidance',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.black54,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'You avoided AC on ${_percentageAnimation.value.toInt()}% of days',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.black87,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 12),
                        
                        // Estimated Savings
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isHighSavings ? Colors.green.shade50 : Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isHighSavings ? Colors.green.shade100 : Colors.grey.shade200,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.savings_outlined,
                                color: isHighSavings ? Colors.green.shade600 : Colors.grey.shade600,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Estimated Savings',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.black54,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'You saved approximately \$${_savingsAnimation.value.toStringAsFixed(2)} this month',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: isHighSavings ? Colors.green.shade700 : Colors.black87,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Natural ventilation tip
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Text(
                                '🌱',
                                style: TextStyle(fontSize: 16),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Natural ventilation is better for the environment and your wallet!',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.green.shade700,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          
          // Premium overlay if not premium user - TEMPORARILY DISABLED FOR TESTING
          // if (!widget.efficiencyData.isPremiumUser)
          //   Positioned.fill(
          //     child: Container(
          //       decoration: BoxDecoration(
          //         borderRadius: BorderRadius.circular(16),
          //         color: Colors.white.withOpacity(0.85),
          //       ),
          //       child: Center(
          //         child: Padding(
          //           padding: const EdgeInsets.all(20.0),
          //           child: Column(
          //             mainAxisSize: MainAxisSize.min,
          //             children: [
          //               Icon(
          //                 Icons.star,
          //                 size: 48,
          //                 color: Colors.amber.shade600,
          //               ),
          //               const SizedBox(height: 12),
          //               const Text(
          //                 'Premium Feature',
          //                 style: TextStyle(
          //                   fontSize: 18,
          //                   fontWeight: FontWeight.bold,
          //                   color: Colors.black87,
          //                 ),
          //               ),
          //               const SizedBox(height: 8),
          //               const Text(
          //                 'See how much you\'re saving by using smarter ventilation and avoiding unnecessary AC.',
          //                 textAlign: TextAlign.center,
          //                 style: TextStyle(
          //                   fontSize: 14,
          //                   color: Colors.black87,
          //                   height: 1.4,
          //                 ),
          //               ),
          //               const SizedBox(height: 16),
          //               SizedBox(
          //                 width: double.infinity,
          //                 child: ElevatedButton(
          //                   onPressed: _showPremiumUpgrade,
          //                   style: ElevatedButton.styleFrom(
          //                     backgroundColor: Colors.amber.shade600,
          //                     foregroundColor: Colors.white,
          //                     padding: const EdgeInsets.symmetric(vertical: 12),
          //                     shape: RoundedRectangleBorder(
          //                       borderRadius: BorderRadius.circular(8),
          //                     ),
          //                     elevation: 2,
          //                   ),
          //                   child: const Text(
          //                     'Upgrade to Premium',
          //                     style: TextStyle(
          //                       fontWeight: FontWeight.w600,
          //                     ),
          //                   ),
          //                 ),
          //               ),
          //               const SizedBox(height: 8),
          //               TextButton(
          //                 onPressed: _showPremiumUpgrade,
          //                 child: Text(
          //                   'Learn More',
          //                   style: TextStyle(
          //                     color: Colors.grey.shade600,
          //                     fontSize: 12,
          //                   ),
          //                 ),
          //               ),
          //             ],
          //           ),
          //         ),
          //       ),
          //     ),
          //   ),
        ],
      ),
    );
  }
}
