import 'package:flutter/material.dart';

class FloatingMenuBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onTap;

  const FloatingMenuBar({
    Key? key,
    required this.selectedIndex,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 24.0),
        child: Container(
          height: 64,
          margin: const EdgeInsets.symmetric(horizontal: 32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildIcon(context, Icons.home_rounded, 0, 'Home'),
              _buildIcon(context, Icons.wifi, 1, 'Smart'),
              _buildIcon(context, Icons.settings_rounded, 2, 'Settings'),
              _buildIcon(context, Icons.info_outline, 3, 'Pro'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIcon(BuildContext context, IconData icon, int index, String tooltip) {
    final isSelected = selectedIndex == index;
    return GestureDetector(
      onTap: () => onTap(index),
      child: Tooltip(
        message: tooltip,
        child: Container(
          decoration: BoxDecoration(
            color: isSelected ? Theme.of(context).primaryColor.withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.all(8),
          child: Icon(
            icon,
            size: 32,
            color: isSelected ? Theme.of(context).primaryColor : Colors.grey[700],
          ),
        ),
      ),
    );
  }
}
