import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:math';
import 'dart:async';

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
  late List<SmartTip> _tips;
  int _currentIndex = 0;
  bool _expanded = false;
  Timer? _autoRotateTimer;

  @override
  void initState() {
    super.initState();
    _tips = widget.tips ?? [
      SmartTip(
        short: "💡 Did you know opening windows before 11AM can reduce AC costs by 20%?",
        long: "Morning air is cooler and less humid, so ventilating early helps keep your home comfortable and reduces the need for air conditioning.",
      ),
      SmartTip(
        short: "💡 Closing windows during high pollen hours can help allergy sufferers.",
        long: "Pollen counts are highest between 5AM and 10AM. Keep windows closed during these times to minimize indoor pollen.",
      ),
      SmartTip(
        short: "💡 Use cross-ventilation for faster cooling and fresher air.",
        long: "Opening windows on opposite sides of your home creates a breeze that quickly replaces stale indoor air with fresh outdoor air.",
      ),
      SmartTip(
        short: "💡 Clean window screens regularly to improve airflow and reduce allergens.",
        long: "Dust and pollen can accumulate on screens, blocking airflow and increasing allergy risk. Clean screens monthly for best results.",
      ),
      SmartTip(
        short: "💡 Smart window usage can lower energy bills and improve sleep quality.",
        long: "Letting in cool evening air and blocking out daytime heat helps regulate indoor temperature and supports restful sleep.",
      ),
      SmartTip(
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
