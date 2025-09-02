import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../services/airtable_service.dart';

class LocalAdsProvider extends ChangeNotifier {
  List<LocalAd> _ads = [];
  int _currentAdIndex = 0;
  bool _isLoading = false;
  String? _error;
  Timer? _rotationTimer;
  String? _currentProvince;
  String? _currentCity;

  // Getters
  List<LocalAd> get ads => _ads;
  LocalAd? get currentAd => _ads.isNotEmpty ? _ads[_currentAdIndex] : null;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasAds => _ads.isNotEmpty;
  String? get currentProvince => _currentProvince;
  String? get currentCity => _currentCity;

  // Ad rotation interval (in seconds)
  static const int _rotationInterval = 30; // Rotate every 30 seconds

  LocalAdsProvider() {
    _initializeLocation();
  }

  /// Initialize location and load ads
  Future<void> _initializeLocation() async {
    await _getCurrentLocation();
    await loadAds();
    _startAdRotation();
  }

  /// Get current location for targeted ads
  Future<void> _getCurrentLocation() async {
    try {
      // Check permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _error = 'Location permissions denied';
          notifyListeners();
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _error = 'Location permissions permanently denied';
        notifyListeners();
        return;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
      );

      // Get address from coordinates
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        _currentProvince = placemark.administrativeArea ?? placemark.country;
        _currentCity = placemark.locality ?? placemark.subLocality;
        
        print('Location detected: $_currentCity, $_currentProvince');
        notifyListeners();
      }
    } catch (e) {
      print('Error getting location: $e');
      // Don't set error - continue without location filtering
      print('Continuing without location - will show all ads');
      notifyListeners();
    }
  }

  /// Load ads from Airtable
  Future<void> loadAds({bool forceRefresh = false}) async {
    if (_isLoading && !forceRefresh) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Always start by getting all active ads
      List<LocalAd> allAds = await AirtableService.fetchLocalAds();
      List<LocalAd> fetchedAds;
      
      // If we have location data, try to find location-specific ads
      if (_currentProvince != null && _currentCity != null) {
        // Try city-specific ads first
        List<LocalAd> cityAds = allAds.where((ad) => 
          ad.city?.toLowerCase() == _currentCity!.toLowerCase() &&
          ad.province?.toLowerCase() == _currentProvince!.toLowerCase()
        ).toList();
        
        if (cityAds.isNotEmpty) {
          fetchedAds = cityAds;
          print('Found ${cityAds.length} city-specific ads for $_currentCity, $_currentProvince');
        } else {
          // Try province-specific ads
          List<LocalAd> provinceAds = allAds.where((ad) => 
            ad.province?.toLowerCase() == _currentProvince!.toLowerCase()
          ).toList();
          
          if (provinceAds.isNotEmpty) {
            fetchedAds = provinceAds;
            print('Found ${provinceAds.length} province-specific ads for $_currentProvince');
          } else {
            // Show all ads if no location-specific ones found
            fetchedAds = allAds;
            print('No location-specific ads found, showing all ${allAds.length} ads');
          }
        }
      } else {
        // No location available, show all active ads
        fetchedAds = allAds;
        print('No location detected, showing all ${allAds.length} ads');
      }

      _ads = fetchedAds;
      _currentAdIndex = 0;
      
      if (_ads.isEmpty) {
        _error = 'No ads available';
      } else {
        _error = null;
        print('Loaded ${_ads.length} ads for display');
      }
    } catch (e) {
      _error = 'Failed to load ads: $e';
      print('Error loading ads: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Start automatic ad rotation
  void _startAdRotation() {
    _stopAdRotation(); // Stop any existing timer
    
    if (_ads.length > 1) {
      _rotationTimer = Timer.periodic(
        const Duration(seconds: _rotationInterval),
        (timer) {
          nextAd();
        },
      );
    }
  }

  /// Stop ad rotation
  void _stopAdRotation() {
    _rotationTimer?.cancel();
    _rotationTimer = null;
  }

  /// Move to next ad
  void nextAd() {
    if (_ads.isEmpty) return;
    
    _currentAdIndex = (_currentAdIndex + 1) % _ads.length;
    notifyListeners();
  }

  /// Move to previous ad
  void previousAd() {
    if (_ads.isEmpty) return;
    
    _currentAdIndex = (_currentAdIndex - 1 + _ads.length) % _ads.length;
    notifyListeners();
  }

  /// Go to specific ad
  void goToAd(int index) {
    if (index >= 0 && index < _ads.length) {
      _currentAdIndex = index;
      notifyListeners();
    }
  }

  /// Track ad interaction
  Future<void> trackAdClick(LocalAd ad) async {
    try {
      await AirtableService.trackAdInteraction(ad.id, 'click');
    } catch (e) {
      print('Error tracking ad click: $e');
    }
  }

  /// Refresh ads manually
  Future<void> refreshAds() async {
    await loadAds(forceRefresh: true);
    _startAdRotation(); // Restart rotation with new ads
  }

  /// Update location manually
  Future<void> updateLocation() async {
    await _getCurrentLocation();
    await loadAds(forceRefresh: true);
  }

  @override
  void dispose() {
    _stopAdRotation();
    super.dispose();
  }
}
