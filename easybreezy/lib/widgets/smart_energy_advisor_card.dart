import 'package:flutter/material.dart';
import '../models/smart_thermostat_model.dart';

class SmartEnergyAdvisorCard extends StatelessWidget {
  final SmartThermostatModel thermostatData;
  final VoidCallback? onApplyNow;

  const SmartEnergyAdvisorCard({
    Key? key,
    required this.thermostatData,
    this.onApplyNow,
  }) : super(key: key);

  void _showEnergyAdvisorInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Text(
            'Energy Efficiency Optimizer',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          ),
          content: Text(
            'The Energy Efficiency Optimizer helps you reduce your energy bills by giving smart, real-time suggestions based on your thermostat settings and window status. When windows are open, the widget checks if your air conditioning or heating is still running — and if so, it recommends adjusting your thermostat to avoid wasting energy.',
            style: TextStyle(color: Colors.black87),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Got it'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasOpportunity = thermostatData.hasEnergySavingOpportunity;
    final savings = thermostatData.potentialSavingsPercentage;

    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.white,
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with icon
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: hasOpportunity ? Colors.green.shade100 : Colors.blue.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          hasOpportunity ? Icons.energy_savings_leaf : Icons.thermostat,
                          color: hasOpportunity ? Colors.green.shade700 : Colors.blue.shade700,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Energy Efficiency Tip',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            if (hasOpportunity && savings > 0)
                              Text(
                                'Save up to $savings% on energy',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.green.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                          ],
                        ),
                      ),
                      // Status indicators
                      Row(
                        children: [
                          if (thermostatData.windowsOpen)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade100,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.window, size: 12, color: Colors.blue.shade700),
                                  const SizedBox(width: 2),
                                  Text(
                                    'Open',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.blue.shade700,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          const SizedBox(width: 4),
                          if (thermostatData.isCooling)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.cyan.shade100,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.ac_unit, size: 12, color: Colors.cyan.shade700),
                                  const SizedBox(width: 2),
                                  Text(
                                    'A/C',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.cyan.shade700,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Energy tip message
                  Text(
                    thermostatData.energyTip,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                      height: 1.4,
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Temperature display
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        // Current indoor temp
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                'Indoor Temp',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${thermostatData.indoorTemp.toInt()}°C',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // Arrow indicator
                        if (hasOpportunity) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Icon(
                              Icons.arrow_forward,
                              color: Colors.green.shade600,
                              size: 20,
                            ),
                          ),
                          
                          // Suggested target temp
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  'Suggested',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.green.shade600,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${thermostatData.suggestedTargetTemp.toInt()}°C',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ] else ...[
                          // Current target when no opportunity
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  'Target Temp',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${thermostatData.targetTemp.toInt()}°C',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Apply button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: hasOpportunity ? onApplyNow : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: hasOpportunity ? Colors.green.shade600 : Colors.grey.shade300,
                        foregroundColor: hasOpportunity ? Colors.white : Colors.grey.shade600,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: hasOpportunity ? 2 : 0,
                      ),
                      icon: Icon(
                        hasOpportunity ? Icons.check_circle_outline : Icons.check_circle,
                        size: 18,
                      ),
                      label: Text(
                        hasOpportunity ? 'Apply Now (Mock)' : 'Settings Optimized',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  
                  // Additional info for testing
                  if (hasOpportunity)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'Note: This is a demonstration. In a real app, this would adjust your smart thermostat.',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                          fontStyle: FontStyle.italic,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
              ),
            ),
          ),
          // Info icon positioned in top-right corner
          Positioned(
            top: 8,
            right: 8,
            child: Tooltip(
              message: 'The Energy Efficiency Optimizer helps you reduce your energy bills by giving smart, real-time suggestions based on your thermostat settings and window status. When windows are open, the widget checks if your air conditioning or heating is still running — and if so, it recommends adjusting your thermostat to avoid wasting energy.',
              preferBelow: false,
              waitDuration: Duration(milliseconds: 500),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              textStyle: TextStyle(
                color: Colors.black87,
                fontSize: 12,
              ),
              child: GestureDetector(
                onTap: () => _showEnergyAdvisorInfo(context),
                child: Container(
                  padding: EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 2,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.info_outline,
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
