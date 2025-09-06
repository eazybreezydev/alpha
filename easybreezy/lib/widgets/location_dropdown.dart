import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/location_model.dart';
import '../providers/location_provider.dart';
import '../providers/weather_provider.dart';

class LocationDropdown extends StatelessWidget {
  final Color textColor;

  const LocationDropdown({
    Key? key,
    required this.textColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer2<LocationProvider, WeatherProvider>(
      builder: (context, locationProvider, weatherProvider, child) {
        final locations = locationProvider.locations;
        final currentLocation = locationProvider.currentLocation;
        final weatherCity = weatherProvider.city ?? 'Unknown';
        final weatherProvince = weatherProvider.province ?? '';

        return GestureDetector(
          onTap: () => _showLocationMenu(context, locationProvider, weatherProvider),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.location_on, color: textColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  currentLocation?.displayName ?? '$weatherCity${weatherProvince.isNotEmpty ? ', $weatherProvince' : ''}',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.keyboard_arrow_down,
                  color: textColor,
                  size: 20,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showLocationMenu(BuildContext context, LocationProvider locationProvider, WeatherProvider weatherProvider) {
    final locations = locationProvider.locations;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Location',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            
            // Current location (if no saved locations)
            if (locations.isEmpty)
              ListTile(
                leading: const Icon(Icons.my_location, color: Colors.blue),
                title: Text(weatherProvider.city ?? 'Current Location'),
                subtitle: Text(weatherProvider.province ?? ''),
                onTap: () => Navigator.pop(context),
              ),
            
            // Saved locations
            ...locations.map((location) => ListTile(
              leading: Icon(
                location.isCurrentLocation ? Icons.my_location : Icons.place,
                color: Colors.blue,
              ),
              title: Text(location.displayName),
              subtitle: Text(location.fullLocation),
              onTap: () {
                Navigator.pop(context);
                locationProvider.switchToLocation(location.id, weatherProvider);
              },
            )),
            
            // Add location option
            if (locationProvider.canAddLocation)
              ListTile(
                leading: const Icon(Icons.add, color: Colors.green),
                title: const Text('Add Location'),
                subtitle: const Text('Save up to 2 locations'),
                onTap: () {
                  Navigator.pop(context);
                  _showAddLocationDialog(context);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentLocationDisplay(WeatherProvider weatherProvider) {
    return Row(
      children: [
        Icon(Icons.location_on, color: textColor),
        const SizedBox(width: 8),
        _buildLocationText(
          weatherProvider.city ?? 'Unknown',
          weatherProvider.province ?? '',
        ),
      ],
    );
  }

  Widget _buildLocationText(String city, String province) {
    final locationText = province.isNotEmpty ? '$city, $province' : city;
    return Text(
      locationText,
      style: TextStyle(
        color: textColor,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildDropdownItem(String name, String fullLocation, IconData icon) {
    // Ensure safe string handling
    final safeName = name.isNotEmpty ? name : 'Unknown Location';
    final safeFullLocation = fullLocation.isNotEmpty ? fullLocation : safeName;
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[600], size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  safeName,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (safeFullLocation != safeName && safeFullLocation.isNotEmpty)
                  Text(
                    safeFullLocation,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddLocationItem() {
    return Row(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: Colors.blue[100],
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            Icons.add,
            color: Colors.blue[600],
            size: 16,
          ),
        ),
        const SizedBox(width: 12),
        const Text(
          'Add Location',
          style: TextStyle(
            color: Colors.blue,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  void _showAddLocationDialog(BuildContext context) {
    final nameController = TextEditingController();
    final cityController = TextEditingController();
    final provinceController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add New Location'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Location Name (e.g., Home, Cottage)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: cityController,
                  decoration: const InputDecoration(
                    labelText: 'City',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: provinceController,
                  decoration: const InputDecoration(
                    labelText: 'Province/State',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Note: This feature will require premium in future updates. Enjoy it free for now!',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty ||
                    cityController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter both name and city'),
                    ),
                  );
                  return;
                }

                // For now, use placeholder coordinates
                // In a real implementation, you'd use geocoding to get lat/lng
                final success = await Provider.of<LocationProvider>(
                  context,
                  listen: false,
                ).addLocation(
                  name: nameController.text.trim(),
                  city: cityController.text.trim(),
                  province: provinceController.text.trim(),
                  latitude: 43.7 + (DateTime.now().millisecond / 10000), // Placeholder
                  longitude: -79.4 + (DateTime.now().millisecond / 10000), // Placeholder
                );

                if (!success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Maximum locations reached (2 free)'),
                    ),
                  );
                } else {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Added ${nameController.text.trim()}'),
                    ),
                  );
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }
}
