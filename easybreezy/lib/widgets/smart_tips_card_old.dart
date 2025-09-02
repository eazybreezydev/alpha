import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';
import '../providers/quick_tips_provider.dart';
import '../services/airtable_service.dart';

class SmartTip {
  final String short;
  final String long;
  SmartTip({required this.short, required this.long});
}

class SmartTipsCard extends StatefulWidget {
  final List<SmartTip>? tips;
  const SmartTipsCard({Key? key, this.tips}) : super(key: key);

  @override
  State<SmartTipsCard> createState() => _SmartTipsCardState();
}

class _SmartTipsCardState extends State<SmartTipsCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<QuickTipsProvider>(
      builder: (context, tipsProvider, child) {
        return Card(
          elevation: 8,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          color: Colors.white,
          margin: const EdgeInsets.symmetric(vertical: 16),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: _buildContent(context, tipsProvider),
          ),
        );
      },
    );
  }

  Widget _buildContent(BuildContext context, QuickTipsProvider tipsProvider) {
    if (tipsProvider.isLoading) {
      return const SizedBox(
        height: 120,
        child: Center(
          child: CircularProgressIndicator(),
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
                child: Text(
                  '${tipsProvider.tips.indexOf(currentTip) + 1}/${tipsProvider.tips.length}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Tip content
        GestureDetector(
          onTap: () {
            setState(() {
              _expanded = !_expanded;
            });
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
              ),
              
              const SizedBox(height: 8),
              
              AnimatedCrossFade(
                duration: const Duration(milliseconds: 300),
                crossFadeState: _expanded 
                    ? CrossFadeState.showSecond 
                    : CrossFadeState.showFirst,
                firstChild: Text(
                  currentTip.excerpt.length > 100 
                      ? '${currentTip.excerpt.substring(0, 100)}...'
                      : currentTip.excerpt,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    height: 1.4,
                  ),
                ),
                secondChild: Text(
                  currentTip.excerpt,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    height: 1.4,
                  ),
                ),
              ),
              
              const SizedBox(height: 8),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (currentTip.sponsor != null && currentTip.sponsor!.isNotEmpty)
                    Text(
                      'Sponsored by ${currentTip.sponsor}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  const Spacer(),
                  Text(
                    _expanded ? 'Tap to collapse' : 'Tap to expand',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
        short: "💡 Keep windows closed during high humidity to prevent mold growth.",
        long: "High humidity can lead to condensation and mold. Use a dehumidifier or AC when outdoor humidity is high.",
      ),
      SmartTip(
        short: "💡 Open windows after rain to freshen indoor air and reduce musty odors.",
        long: "Rain clears dust and pollen from the air, making it a great time to ventilate your home.",
      ),
      SmartTip(
        short: "💡 Use window fans to boost airflow and save on cooling costs.",
        long: "Window fans can quickly move cool air inside and push warm air out, reducing reliance on AC.",
      ),
    ];
    _currentIndex = Random().nextInt(_tips.length);
    _autoRotateTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) _nextTip();
    });
  }

  @override
  void dispose() {
    _autoRotateTimer?.cancel();
    super.dispose();
  }

  void _nextTip() {
    setState(() {
      _expanded = false;
      _currentIndex = (_currentIndex + 1) % _tips.length;
    });
  }

  void _toggleExpanded() {
    setState(() {
      _expanded = !_expanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    final tip = _tips[_currentIndex];

    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.ease,
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            const Text(
              'Quick Tips',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black, // Pure black title
              ),
            ),
            const SizedBox(height: 16),
            // Tip content
            InkWell(
              onTap: _toggleExpanded,
              borderRadius: BorderRadius.circular(18),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      tip.short,
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.black87,
                  ),
                ],
              ),
            ),
            if (_expanded) ...[
              const SizedBox(height: 12),
              Text(
                tip.long,
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 15,
                ),
              ),
            ],
            const SizedBox(height: 16),
            // Sponsored by line
            GestureDetector(
              onTap: () async {
                const url = 'https://www.nordikwindows.com';
                if (await canLaunchUrl(Uri.parse(url))) {
                  await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                }
              },
              child: Text(
                'Sponsored by Nordik Windows & Doors',
                style: TextStyle(
                  color: Colors.blue[700],
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
