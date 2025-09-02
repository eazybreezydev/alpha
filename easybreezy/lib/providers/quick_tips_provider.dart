import 'dart:async';
import 'package:flutter/foundation.dart';
import '../services/airtable_service.dart';

class QuickTipsProvider extends ChangeNotifier {
  List<QuickTip> _tips = [];
  int _currentTipIndex = 0;
  bool _isLoading = false;
  String? _error;
  Timer? _rotationTimer;

  // Getters
  List<QuickTip> get tips => _tips;
  QuickTip? get currentTip => _tips.isNotEmpty ? _tips[_currentTipIndex] : null;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasTips => _tips.isNotEmpty;

  // Tip rotation interval (in seconds) - longer than ads since tips are more content-heavy
  static const int _rotationInterval = 45; // Rotate every 45 seconds

  QuickTipsProvider() {
    loadTips();
    _startTipRotation();
  }

  /// Load tips from Airtable
  Future<void> loadTips({bool forceRefresh = false}) async {
    if (_isLoading && !forceRefresh) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      List<QuickTip> fetchedTips = await AirtableService.fetchQuickTips();

      _tips = fetchedTips;
      _currentTipIndex = 0;
      
      if (_tips.isEmpty) {
        _error = 'No tips available';
      } else {
        _error = null;
        print('Loaded ${_tips.length} quick tips');
      }
    } catch (e) {
      _error = 'Failed to load tips: $e';
      print('Error loading tips: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Start automatic tip rotation
  void _startTipRotation() {
    _stopTipRotation(); // Stop any existing timer
    
    if (_tips.length > 1) {
      _rotationTimer = Timer.periodic(
        const Duration(seconds: _rotationInterval),
        (timer) {
          nextTip();
        },
      );
    }
  }

  /// Stop tip rotation
  void _stopTipRotation() {
    _rotationTimer?.cancel();
    _rotationTimer = null;
  }

  /// Move to next tip
  void nextTip() {
    if (_tips.isEmpty) return;
    
    _currentTipIndex = (_currentTipIndex + 1) % _tips.length;
    notifyListeners();
  }

  /// Move to previous tip
  void previousTip() {
    if (_tips.isEmpty) return;
    
    _currentTipIndex = (_currentTipIndex - 1 + _tips.length) % _tips.length;
    notifyListeners();
  }

  /// Go to specific tip
  void goToTip(int index) {
    if (index >= 0 && index < _tips.length) {
      _currentTipIndex = index;
      notifyListeners();
    }
  }

  /// Refresh tips manually
  Future<void> refreshTips() async {
    await loadTips(forceRefresh: true);
    _startTipRotation(); // Restart rotation with new tips
  }

  @override
  void dispose() {
    _stopTipRotation();
    super.dispose();
  }
}
