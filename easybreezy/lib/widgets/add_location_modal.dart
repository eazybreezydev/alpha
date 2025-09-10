import 'package:flutter/material.dart';
import '../models/location_model.dart';
import '../widgets/location_picker_widget.dart';
import '../models/home_config.dart';

class AddLocationModal extends StatefulWidget {
  final Function(LocationModel) onLocationAdded;

  const AddLocationModal({
    Key? key,
    required this.onLocationAdded,
  }) : super(key: key);

  @override
  State<AddLocationModal> createState() => _AddLocationModalState();
}

class _AddLocationModalState extends State<AddLocationModal> {
  final TextEditingController _nameController = TextEditingController();
  String _selectedAddress = '';
  Map<String, double>? _selectedCoords;
  HomeOrientation _selectedOrientation = HomeOrientation.north;
  bool _isLocationValid = false;
  Map<WindowDirection, bool> _selectedWindows = {
    WindowDirection.north: false,
    WindowDirection.east: false,
    WindowDirection.south: false,
    WindowDirection.west: false,
  };

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _onLocationSelected(String address, Map<String, double> coords, HomeOrientation orientation) {
    setState(() {
      _selectedAddress = address;
      _selectedCoords = coords;
      _selectedOrientation = orientation;
      _isLocationValid = address.isNotEmpty && coords.isNotEmpty;
    });
  }

  void _saveLocation() async {
    final name = _nameController.text.trim();
    
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a location name')),
      );
      return;
    }

    if (!_isLocationValid || _selectedCoords == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a valid location')),
      );
      return;
    }

    // Parse city and province from address
    final addressParts = _selectedAddress.split(', ');
    String city = '';
    String province = '';
    
    if (addressParts.length >= 2) {
      // Typically format: "Street, City, Province, Country"
      city = addressParts.length >= 3 ? addressParts[addressParts.length - 3] : addressParts[0];
      province = addressParts.length >= 2 ? addressParts[addressParts.length - 2] : '';
    } else {
      city = _selectedAddress; // Fallback to full address
    }

    final newLocation = LocationModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      city: city,
      province: province,
      address: _selectedAddress,
      latitude: _selectedCoords!['lat']!,
      longitude: _selectedCoords!['lng']!,
      orientation: _selectedOrientation,
      isHome: false,
      createdAt: DateTime.now(),
      windows: Map.from(_selectedWindows), // Pass window selections
    );

    // Close the modal immediately and pass the location to the callback
    Navigator.of(context).pop();
    
    // Call the callback after closing the modal
    widget.onLocationAdded(newLocation);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
          maxWidth: MediaQuery.of(context).size.width * 0.9,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.add_location, color: Colors.blue, size: 28),
                  const SizedBox(width: 12),
                  const Text(
                    'Add New Location',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.grey),
                  ),
                ],
              ),
            ),
            
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Location Name Field
                    const Text(
                      'Location Name',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _nameController,
                      style: const TextStyle(color: Colors.black87),
                      decoration: const InputDecoration(
                        labelText: 'Enter a name for this location',
                        hintText: 'e.g., Office, Vacation Home, etc.',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.label_outline),
                      ),
                      onChanged: (value) {
                        setState(() {}); // Refresh to update save button state
                      },
                    ),
                    const SizedBox(height: 24),
                    
                    // Location Picker
                    LocationPickerWidget(
                      onLocationSelected: _onLocationSelected,
                      showTitle: true,
                    ),
                  ],
                ),
              ),
            ),
            
            // Footer with buttons
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: (_nameController.text.trim().isNotEmpty && _isLocationValid)
                          ? _saveLocation
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Add Location',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Helper function to show the modal
Future<void> showAddLocationModal(BuildContext context, Function(LocationModel) onLocationAdded) {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => AddLocationModal(onLocationAdded: onLocationAdded),
  );
}
