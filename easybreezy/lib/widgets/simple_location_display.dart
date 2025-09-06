import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geocoding/geocoding.dart';
import '../providers/location_provider.dart';
import '../providers/weather_provider.dart';
import '../providers/home_provider.dart';
import '../models/location_model.dart';

class SimpleLocationDisplay extends StatelessWidget {
  final Color textColor;

  const SimpleLocationDisplay({
    Key? key,
    required this.textColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<LocationProvider>(
      builder: (context, locationProvider, child) {
        final currentLocation = locationProvider.currentLocation;
        
        return GestureDetector(
          onTap: () => _showLocationBottomSheet(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.location_on, color: textColor, size: 18),
                const SizedBox(width: 6),
                Text(
                  currentLocation?.name ?? _getCurrentLocationText(context),
                  style: TextStyle(
                    color: textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.keyboard_arrow_down, color: textColor, size: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  String _getCurrentLocationText(BuildContext context) {
    final weatherProvider = Provider.of<WeatherProvider>(context, listen: false);
    final city = weatherProvider.city ?? 'Current';
    final province = weatherProvider.province ?? '';
    return province.isNotEmpty ? '$city, $province' : city;
  }

  void _showLocationBottomSheet(BuildContext context) {
    final locationProvider = Provider.of<LocationProvider>(context, listen: false);
    final weatherProvider = Provider.of<WeatherProvider>(context, listen: false);
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Locations',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Always show all saved locations
            ...locationProvider.locations.map((location) => ListTile(
              leading: Icon(
                location.isCurrentLocation ? Icons.my_location : Icons.place,
                color: Colors.blue,
              ),
              title: Text(location.name),
              subtitle: Text('${location.city}, ${location.province}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (locationProvider.currentLocation?.id == location.id)
                    const Icon(Icons.check, color: Colors.green),
                  if (!location.isCurrentLocation)
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _showDeleteConfirmation(context, location, locationProvider),
                    ),
                ],
              ),
              onTap: () {
                Navigator.pop(context);
                locationProvider.switchToLocation(location.id, weatherProvider);
              },
            )),
            
            // If no locations exist, show current weather location option
            if (locationProvider.locations.isEmpty) ...[
              ListTile(
                leading: const Icon(Icons.my_location, color: Colors.blue),
                title: Text(_getCurrentLocationText(context)),
                subtitle: const Text('Current location'),
                trailing: const Icon(Icons.check, color: Colors.green),
                onTap: () => Navigator.pop(context),
              ),
            ],
            
            // Add location option
            if (locationProvider.canAddLocation) ...[
              const Divider(),
              ListTile(
                leading: const Icon(Icons.add, color: Colors.green),
                title: const Text('Add Location'),
                subtitle: Text('${2 - locationProvider.locations.length} slots remaining'),
                onTap: () {
                  Navigator.pop(context);
                  _showAddLocationDialog(context);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showAddLocationDialog(BuildContext context) {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController locationController = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Location'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Name (e.g., "Cottage")',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: locationController,
                decoration: const InputDecoration(
                  labelText: 'Location (e.g., "Muskoka, ON")',
                  border: OutlineInputBorder(),
                ),
              ),
              if (isLoading) ...[
                const SizedBox(height: 16),
                const CircularProgressIndicator(),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isLoading ? null : () async {
                if (nameController.text.isNotEmpty && locationController.text.isNotEmpty) {
                  setState(() => isLoading = true);
                  
                  try {
                    // Geocode the location
                    List<Location> locations = await locationFromAddress(locationController.text);
                    if (locations.isNotEmpty) {
                      final location = locations.first;
                      
                      // Parse city and province from location string
                      final locationParts = locationController.text.split(',');
                      final city = locationParts.first.trim();
                      final province = locationParts.length > 1 ? locationParts.last.trim() : '';
                      
                      // Add to LocationProvider
                      final locationProvider = Provider.of<LocationProvider>(context, listen: false);
                      final weatherProvider = Provider.of<WeatherProvider>(context, listen: false);
                      
                      // If this is the first location being added, save the current weather location first
                      if (locationProvider.locations.isEmpty) {
                        await _saveCurrentWeatherLocation(context, locationProvider, weatherProvider);
                      }
                      
                      final success = await locationProvider.addLocation(
                        name: nameController.text,
                        city: city,
                        province: province,
                        latitude: location.latitude,
                        longitude: location.longitude,
                        isCurrentLocation: false,
                      );
                      
                      Navigator.pop(context);
                      if (success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('${nameController.text} added successfully!')),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Error: Maximum locations reached (2 max for free tier)')),
                        );
                      }
                    } else {
                      throw Exception('Location not found');
                    }
                  } catch (e) {
                    setState(() => isLoading = false);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: Could not find location "${locationController.text}"')),
                    );
                  }
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  /// Save the current weather location as the first saved location
  Future<void> _saveCurrentWeatherLocation(BuildContext context, LocationProvider locationProvider, WeatherProvider weatherProvider) async {
    try {
      final city = weatherProvider.city ?? 'Current';
      final province = weatherProvider.province ?? '';
      
      // Use the coordinates from home provider (which is what weather provider uses)
      final homeProvider = Provider.of<HomeProvider>(context, listen: false);
      double? latitude = homeProvider.homeConfig.latitude;
      double? longitude = homeProvider.homeConfig.longitude;
      
      // If we don't have home coordinates, use default coordinates for your area
      latitude ??= 44.3975666; // Your home coordinates from the logs
      longitude ??= -79.6767054;
      
      await locationProvider.addLocation(
        name: 'Home', // Default name for current location
        city: city,
        province: province,
        latitude: latitude,
        longitude: longitude,
        isCurrentLocation: true,
      );
    } catch (e) {
      print('Error saving current weather location: $e');
    }
  }

  void _showDeleteConfirmation(BuildContext context, LocationModel location, LocationProvider locationProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Location'),
        content: Text('Are you sure you want to delete "${location.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await locationProvider.removeLocation(location.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${location.name} deleted')),
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
