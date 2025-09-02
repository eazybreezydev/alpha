import 'package:flutter/material.dart';
import '../models/predictive_recommendation_model.dart';

class PredictiveWindowRecommendationsWidget extends StatefulWidget {
  final PredictiveRecommendationModel predictions;
  final VoidCallback? onNotificationTapped;

  const PredictiveWindowRecommendationsWidget({
    Key? key,
    required this.predictions,
    this.onNotificationTapped,
  }) : super(key: key);

  @override
  State<PredictiveWindowRecommendationsWidget> createState() => 
      _PredictiveWindowRecommendationsWidgetState();
}

class _PredictiveWindowRecommendationsWidgetState 
    extends State<PredictiveWindowRecommendationsWidget>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));

    _slideAnimation = Tween<double>(
      begin: 30.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.2, 0.8, curve: Curves.easeOut),
    ));

    // Start animation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _animationController.forward();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _showPredictiveInfo() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Row(
            children: [
              Icon(Icons.schedule, color: Colors.blue, size: 24),
              SizedBox(width: 8),
              Text(
                'Predictive Recommendations',
                style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: const SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'How Predictions Work:',
                  style: TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  '• Analyzes 48-hour weather forecast',
                  style: TextStyle(color: Colors.black87),
                ),
                Text(
                  '• Calculates optimal window timing',
                  style: TextStyle(color: Colors.black87),
                ),
                Text(
                  '• Predicts energy-saving opportunities',
                  style: TextStyle(color: Colors.black87),
                ),
                Text(
                  '• Alerts you before weather changes',
                  style: TextStyle(color: Colors.black87),
                ),
                SizedBox(height: 16),
                Text(
                  'Priority Levels:',
                  style: TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  '🔴 High: Weather alerts (rain, storms)',
                  style: TextStyle(color: Colors.red),
                ),
                Text(
                  '🟠 Medium: Temperature changes',
                  style: TextStyle(color: Colors.orange),
                ),
                Text(
                  '🟢 Low: Optimization opportunities',
                  style: TextStyle(color: Colors.green),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Got it'),
            ),
          ],
        );
      },
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Icon _getPriorityIcon(String priority) {
    switch (priority) {
      case 'high':
        return const Icon(Icons.warning, color: Colors.red, size: 16);
      case 'medium':
        return const Icon(Icons.info, color: Colors.orange, size: 16);
      case 'low':
        return const Icon(Icons.eco, color: Colors.green, size: 16);
      default:
        return const Icon(Icons.circle, color: Colors.grey, size: 16);
    }
  }

  String _formatTimeUntil(Duration duration) {
    if (duration.inMinutes < 60) {
      return '${duration.inMinutes}m';
    } else if (duration.inHours < 24) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    } else {
      return '${duration.inDays}d ${duration.inHours % 24}h';
    }
  }

  @override
  Widget build(BuildContext context) {
    final urgentRecommendation = widget.predictions.urgentRecommendation;
    final next6Hours = widget.predictions.next6Hours;
    
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
      child: Container(
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          color: Colors.white,
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return FadeTransition(
                opacity: _fadeAnimation,
                child: Transform.translate(
                  offset: Offset(0, _slideAnimation.value),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.schedule,
                              color: Colors.blue.shade700,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Predictive Recommendations',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                Text(
                                  'Next 48 hours forecast',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: _showPredictiveInfo,
                            icon: const Icon(
                              Icons.info_outline,
                              color: Colors.grey,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Next Action Summary
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: urgentRecommendation?.priority == 'high'
                            ? Colors.red.shade50
                            : Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: urgentRecommendation?.priority == 'high'
                              ? Colors.red.shade200
                              : Colors.blue.shade200,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                urgentRecommendation != null
                                  ? _getPriorityIcon(urgentRecommendation.priority)
                                  : const Icon(Icons.check_circle, color: Colors.green, size: 16),
                                const SizedBox(width: 8),
                                const Text(
                                  'Next Action',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                                if (urgentRecommendation != null) ...[
                                  const Spacer(),
                                  Text(
                                    'in ${_formatTimeUntil(urgentRecommendation.timeUntil)}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: _getPriorityColor(urgentRecommendation.priority),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              widget.predictions.nextActionSummary,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Statistics Row
                      Row(
                        children: [
                          // Optimal Hours Today
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.green.shade100),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Optimal Hours',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.green.shade700,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${widget.predictions.optimalHoursToday}h',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green.shade800,
                                    ),
                                  ),
                                  Text(
                                    'next 48h',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.green.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          
                          const SizedBox(width: 12),
                          
                          // Potential Savings
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.blue.shade100),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Potential Savings',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.blue.shade700,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '\$${widget.predictions.totalPotentialSavings.toStringAsFixed(0)}',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue.shade800,
                                    ),
                                  ),
                                  Text(
                                    'next 48h',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.blue.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Upcoming Recommendations (Next 6 hours)
                      if (next6Hours.isNotEmpty) ...[
                        const Text(
                          'Next 6 Hours',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...next6Hours.take(3).map((recommendation) => Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Row(
                            children: [
                              Text(
                                recommendation.actionIcon,
                                style: const TextStyle(fontSize: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${recommendation.action.toUpperCase()} ${recommendation.reason}',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      'Flow Score: ${recommendation.flowScore}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    _formatTimeUntil(recommendation.timeUntil),
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: _getPriorityColor(recommendation.priority),
                                    ),
                                  ),
                                  if (recommendation.potentialSavings > 0)
                                    Text(
                                      '\$${recommendation.potentialSavings.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.green.shade600,
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        )).toList(),
                        
                        if (widget.predictions.recommendations.length > 3)
                          TextButton(
                            onPressed: () {
                              // TODO: Navigate to full predictions view
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Full predictions view coming soon!'),
                                ),
                              );
                            },
                            child: Text(
                              'View All ${widget.predictions.recommendations.length} Predictions →',
                              style: TextStyle(
                                color: Colors.blue.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
