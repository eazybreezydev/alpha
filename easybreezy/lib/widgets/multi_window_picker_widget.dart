import 'package:flutter/material.dart';
import '../models/home_config.dart';

/// MultiWindowPickerWidget
/// Displays a house silhouette with clickable window zones (N/E/S/W).
/// Supports multiple window selections and visual feedback for cross-breeze.
class MultiWindowPickerWidget extends StatefulWidget {
  final Set<WindowDirection> selectedWindows;
  final ValueChanged<Set<WindowDirection>> onChanged;

  const MultiWindowPickerWidget({
    Key? key,
    required this.selectedWindows,
    required this.onChanged,
  }) : super(key: key);

  @override
  State<MultiWindowPickerWidget> createState() => _MultiWindowPickerWidgetState();
}


class _MultiWindowPickerWidgetState extends State<MultiWindowPickerWidget> {
  late Set<WindowDirection> _selected;

  @override
  void initState() {
    super.initState();
    _selected = Set.from(widget.selectedWindows);
  }

  void _toggle(WindowDirection dir) {
    setState(() {
      if (_selected.contains(dir)) {
        _selected.remove(dir);
      } else {
        _selected.add(dir);
      }
      widget.onChanged(_selected);
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      height: 220,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // House silhouette
          CustomPaint(
            size: const Size(180, 180),
            painter: _HousePainter(),
          ),
          // Window zones
          ...WindowDirection.values.map((dir) {
            final pos = _getZonePosition(dir);
            final selected = _selected.contains(dir);
            return Positioned(
              left: pos.dx,
              top: pos.dy,
              child: GestureDetector(
                onTap: () => _toggle(dir),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: selected ? Colors.blueAccent : Colors.white,
                    border: Border.all(
                      color: selected ? Colors.blue : Colors.grey,
                      width: 2,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: selected
                        ? [BoxShadow(color: Colors.blue.withOpacity(0.2), blurRadius: 8)]
                        : [],
                  ),
                  child: Center(
                    child: Icon(
                      Icons.window,
                      color: selected ? Colors.white : Colors.blueGrey,
                    ),
                  ),
                ),
              ),
            );
          }),
          // Cross-breeze feedback (simple: highlight opposite selections)
          if (_selected.length == 2 && _isOpposite(_selected))
            Positioned(
              bottom: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text(
                  'Cross-breeze enabled!',
                  style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Offset _getZonePosition(WindowDirection dir) {
    switch (dir) {
      case WindowDirection.north:
        return const Offset(90, 0);
      case WindowDirection.east:
        return const Offset(170, 90);
      case WindowDirection.south:
        return const Offset(90, 170);
      case WindowDirection.west:
        return const Offset(0, 90);
    }
  }

  bool _isOpposite(Set<WindowDirection> selected) {
    if (selected.contains(WindowDirection.north) && selected.contains(WindowDirection.south)) return true;
    if (selected.contains(WindowDirection.east) && selected.contains(WindowDirection.west)) return true;
    return false;
  }
}

class _HousePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.shade300
      ..style = PaintingStyle.fill;
    // Draw simple house silhouette (rectangle + triangle roof)
    final rect = Rect.fromLTWH(30, 60, 120, 90);
    canvas.drawRect(rect, paint);
    final roof = Path()
      ..moveTo(30, 60)
      ..lineTo(90, 20)
      ..lineTo(150, 60)
      ..close();
    canvas.drawPath(roof, paint..color = Colors.grey.shade400);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
