import 'package:flutter/material.dart';
import '../models/carbon_footprint_model.dart';

class CarbonFootprintWidget extends StatefulWidget {
  final CarbonFootprintModel carbonData;
  final VoidCallback? onViewFullReport;
  final Function(EcoRecommendation)? onApplyRecommendation;
  final VoidCallback? onConnectThermostat;
  final Function(EcoRecommendation)? onAutoApplyThermostat;

  const CarbonFootprintWidget({
    Key? key,
    required this.carbonData,
    this.onViewFullReport,
    this.onApplyRecommendation,
    this.onConnectThermostat,
    this.onAutoApplyThermostat,
  }) : super(key: key);

  @override
  State<CarbonFootprintWidget> createState() => _CarbonFootprintWidgetState();
}

class _CarbonFootprintWidgetState extends State<CarbonFootprintWidget>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _pulseAnimation;
  bool _showDetailedView = false;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
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
      begin: 40.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.2, 0.8, curve: Curves.easeOut),
    ));

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _animationController.forward();
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.carbonData;
    
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: Transform.translate(
            offset: Offset(0, _slideAnimation.value),
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              color: Colors.white,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.white,
                ),
                child: Column(
                  children: [
                    // Header Section
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.green.shade50, Colors.white],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                      ),
                      child: Column(
                        children: [
                          // Title Row
                          Row(
                            children: [
                              AnimatedBuilder(
                                animation: _pulseController,
                                builder: (context, child) {
                                  return Transform.scale(
                                    scale: _pulseAnimation.value,
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Color(int.parse('0xFF${data.impactColor.substring(1)}')).withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        data.impactIcon,
                                        style: const TextStyle(fontSize: 24),
                                      ),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Carbon Footprint Tracker',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    Text(
                                      '${data.impactLevel} Impact • ${data.gridMix}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey.shade600,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                onPressed: () {
                                  setState(() {
                                    _showDetailedView = !_showDetailedView;
                                  });
                                },
                                icon: AnimatedRotation(
                                  turns: _showDetailedView ? 0.5 : 0,
                                  duration: const Duration(milliseconds: 300),
                                  child: const Icon(Icons.expand_more, color: Colors.grey),
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Main Carbon Display
                          _buildMainCarbonDisplay(),
                          
                          const SizedBox(height: 16),
                          
                          // Quick Stats Row
                          _buildQuickStatsRow(),
                        ],
                      ),
                    ),
                    
                    // Expanded Content
                    if (_showDetailedView) ...[
                      _buildDetailedContent(),
                    ],
                    
                    // Action Buttons
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: widget.onViewFullReport,
                              icon: const Icon(Icons.assessment, size: 18),
                              label: const Text('Monthly Report'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green.shade600,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _showRecommendationsDialog(context),
                              icon: const Icon(Icons.eco, size: 18),
                              label: const Text('Eco Tips'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.green.shade600,
                                side: BorderSide(color: Colors.green.shade600),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMainCarbonDisplay() {
    final data = widget.carbonData;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Color(int.parse('0xFF${data.impactColor.substring(1)}')).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Color(int.parse('0xFF${data.impactColor.substring(1)}')).withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                data.dailyCarbonKg.toStringAsFixed(1),
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Color(int.parse('0xFF${data.impactColor.substring(1)}')),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'kg CO₂',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(int.parse('0xFF${data.impactColor.substring(1)}')),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Today\'s Carbon Footprint',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.park, color: Colors.green.shade600, size: 16),
              const SizedBox(width: 4),
              Text(
                '${data.treesEquivalent.toStringAsFixed(1)} trees needed to offset',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.green.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStatsRow() {
    final data = widget.carbonData;
    
    return Row(
      children: [
        Expanded(child: _buildStatCard(
          '${data.energyUsageKwh.toStringAsFixed(1)} kWh',
          'Energy Used',
          Icons.flash_on,
          Colors.orange.shade600,
        )),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard(
          '${data.monthlyCarbonKg.toStringAsFixed(0)} kg',
          'This Month',
          Icons.calendar_month,
          Colors.blue.shade600,
        )),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard(
          data.comparison.ranking,
          'Your Ranking',
          Icons.emoji_events,
          Color(int.parse('0xFF${data.comparison.rankingColor.substring(1)}')),
        )),
      ],
    );
  }

  Widget _buildStatCard(String value, String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedContent() {
    final data = widget.carbonData;
    
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Monthly Progress
          _buildSectionHeader('Monthly Progress', Icons.trending_up),
          const SizedBox(height: 12),
          _buildMonthlyProgress(),
          
          const SizedBox(height: 20),
          
          // Comparison Section
          _buildSectionHeader('How You Compare', Icons.compare_arrows),
          const SizedBox(height: 12),
          _buildComparisonSection(),
          
          const SizedBox(height: 20),
          
          // Smart Thermostat Integration
          if (data.thermostatIntegration != null) ...[
            _buildSectionHeader('Smart Thermostat', Icons.thermostat),
            const SizedBox(height: 12),
            _buildThermostatSection(),
            const SizedBox(height: 20),
          ] else ...[
            _buildSectionHeader('Connect Smart Thermostat', Icons.link),
            const SizedBox(height: 12),
            _buildConnectThermostatSection(),
            const SizedBox(height: 20),
          ],
          
          // Top Recommendations Preview
          _buildSectionHeader('Quick Eco Tips', Icons.lightbulb),
          const SizedBox(height: 12),
          _buildRecommendationsPreview(),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.green.shade600, size: 18),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildMonthlyProgress() {
    final report = widget.carbonData.monthlyReport;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(int.parse('0xFF${report.trendColor.substring(1)}')).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Color(int.parse('0xFF${report.trendColor.substring(1)}')).withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                report.trendIcon,
                style: const TextStyle(fontSize: 20),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${report.percentChange.abs().toStringAsFixed(1)}% ${report.trend}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(int.parse('0xFF${report.trendColor.substring(1)}')),
                      ),
                    ),
                    Text(
                      'vs last month',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${report.daysTracked}/${report.totalDays} days',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: report.daysTracked / report.totalDays,
            backgroundColor: Colors.grey.shade300,
            valueColor: AlwaysStoppedAnimation<Color>(
              Color(int.parse('0xFF${report.trendColor.substring(1)}')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonSection() {
    final comparison = widget.carbonData.comparison;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(int.parse('0xFF${comparison.rankingColor.substring(1)}')).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Color(int.parse('0xFF${comparison.rankingColor.substring(1)}')).withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Text(
            comparison.rankingIcon,
            style: const TextStyle(fontSize: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  comparison.ranking,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(int.parse('0xFF${comparison.rankingColor.substring(1)}')),
                  ),
                ),
                if (comparison.percentBetter > 0) ...[
                  Text(
                    '${comparison.percentBetter.toStringAsFixed(0)}% better than similar homes',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ] else ...[
                  Text(
                    '${comparison.percentBetter.abs().toStringAsFixed(0)}% above similar homes',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThermostatSection() {
    final thermostat = widget.carbonData.thermostatIntegration!;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(thermostat.statusIcon, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${thermostat.brand} Connected',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      thermostat.statusMessage,
                      style: TextStyle(
                        fontSize: 12,
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
                    '${thermostat.currentTemp.toStringAsFixed(0)}°F',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.blue,
                    ),
                  ),
                  Text(
                    'Current',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          if (thermostat.automatableRecommendations.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            
            Text(
              'Auto-Optimization Available',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.green.shade700,
              ),
            ),
            const SizedBox(height: 8),
            
            ...thermostat.automatableRecommendations.map((rec) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  Text(rec.icon, style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          rec.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          '${rec.carbonSavingsKg.toStringAsFixed(1)} kg CO₂ saved/day',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => widget.onAutoApplyThermostat?.call(rec),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      minimumSize: Size.zero,
                    ),
                    child: const Text(
                      'Auto-Apply',
                      style: TextStyle(fontSize: 11),
                    ),
                  ),
                ],
              ),
            )).toList(),
          ],
          
          const SizedBox(height: 12),
          
          // Savings Summary
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSavingStat(
                  '${thermostat.savings.dailySavingsKg.toStringAsFixed(1)} kg',
                  'Daily Savings',
                  Icons.today,
                ),
                _buildSavingStat(
                  '${thermostat.savings.treesEquivalent}',
                  'Trees/Year',
                  Icons.park,
                ),
                _buildSavingStat(
                  '\$${thermostat.savings.costSavings.toStringAsFixed(0)}',
                  'Cost Savings',
                  Icons.attach_money,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectThermostatSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.link_off, color: Colors.orange.shade600, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'No Smart Thermostat Connected',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade700,
                      ),
                    ),
                    Text(
                      'Connect your thermostat for automatic carbon optimization',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Column(
              children: [
                Text(
                  'Potential with Smart Thermostat:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildPotentialStat('8.5 kg', 'CO₂ Saved/Day', Icons.eco),
                    _buildPotentialStat('18%', 'Reduction', Icons.trending_down),
                    _buildPotentialStat('\$25', 'Monthly Savings', Icons.savings),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 12),
          
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: widget.onConnectThermostat,
              icon: const Icon(Icons.link, size: 16),
              label: const Text('Connect Smart Thermostat'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSavingStat(String value, String label, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.green.shade600, size: 16),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.green.shade700,
            fontSize: 12,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildPotentialStat(String value, String label, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.blue.shade600, size: 14),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.blue.shade700,
            fontSize: 11,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            color: Colors.grey.shade600,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildRecommendationsPreview() {
    final recommendations = widget.carbonData.recommendations.take(2).toList();
    
    return Column(
      children: recommendations.map((rec) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Color(int.parse('0xFF${rec.impactColor.substring(1)}')).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Color(int.parse('0xFF${rec.impactColor.substring(1)}')).withOpacity(0.3),
          ),
        ),
        child: Row(
          children: [
            Text(rec.icon, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    rec.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    rec.description,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Color(int.parse('0xFF${rec.impactColor.substring(1)}')),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                rec.impact,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      )).toList(),
    );
  }

  void _showRecommendationsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.eco, color: Colors.green, size: 24),
                    const SizedBox(width: 8),
                    const Text(
                      'Eco-Friendly Recommendations',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 300,
                  child: ListView.builder(
                    itemCount: widget.carbonData.recommendations.length,
                    itemBuilder: (context, index) {
                      final rec = widget.carbonData.recommendations[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Color(int.parse('0xFF${rec.impactColor.substring(1)}')).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Color(int.parse('0xFF${rec.impactColor.substring(1)}')).withOpacity(0.3),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(rec.icon, style: const TextStyle(fontSize: 20)),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    rec.title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Color(int.parse('0xFF${rec.impactColor.substring(1)}')),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    rec.impact,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              rec.description,
                              style: const TextStyle(fontSize: 14),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(Icons.eco, color: Colors.green.shade600, size: 14),
                                const SizedBox(width: 4),
                                Text(
                                  'Save ${rec.carbonSavingsKg.toStringAsFixed(1)} kg CO₂',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.green.shade700,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
