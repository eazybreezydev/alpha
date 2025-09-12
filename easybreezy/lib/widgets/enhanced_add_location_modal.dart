import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/location_model.dart';
import '../widgets/enhanced_location_picker_widget.dart';
import '../models/home_config.dart';
import '../providers/home_provider.dart';

class EnhancedAddLocationModal extends StatefulWidget {
  final Function(LocationModel) onLocationAdded;

  const EnhancedAddLocationModal({
    Key? key,
    required this.onLocationAdded,
  }) : super(key: key);

  @override
  State<EnhancedAddLocationModal> createState() => _EnhancedAddLocationModalState();
}

class _EnhancedAddLocationModalState extends State<EnhancedAddLocationModal> {
  final TextEditingController _nameController = TextEditingController();
  String _selectedAddress = '';
  Map<String, double>? _selectedCoords;
  HomeOrientation _selectedOrientation = HomeOrientation.north;
  List<WindowDirection> _selectedWindows = [];
  bool _isLocationValid = false;
  bool _isFormValid = false;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_validateForm);
  }

  @override
  void dispose() {
    _nameController.removeListener(_validateForm);
    _nameController.dispose();
    super.dispose();
  }

  void _validateForm() {
    setState(() {
      _isFormValid = _nameController.text.trim().isNotEmpty && _isLocationValid;
    });
  }

  void _onLocationSelected(String address, Map<String, double> coords, HomeOrientation orientation, List<WindowDirection> windows) {
    setState(() {
      _selectedAddress = address;
      _selectedCoords = coords;
      _selectedOrientation = orientation;
      _selectedWindows = windows;
      _isLocationValid = address.isNotEmpty && coords.isNotEmpty;
    });
    _validateForm(); // Trigger form validation when location changes
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
        const SnackBar(content: Text('Please complete the location setup')),
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
      // Add window directions to the location model if needed
      // This might require updating the LocationModel class
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
          maxHeight: MediaQuery.of(context).size.height * 0.9,
          maxWidth: MediaQuery.of(context).size.width * 0.95,
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
                  const Expanded(
                    child: Text(
                      'Add New Location',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                    color: Colors.blue,
                  ),
                ],
              ),
            ),
            
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Location name input
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
                      decoration: const InputDecoration(
                        hintText: 'e.g., Cottage, Office, Mom\'s House',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                          borderSide: BorderSide(color: Colors.grey),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                          borderSide: BorderSide(color: Colors.blue, width: 2),
                        ),
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      style: const TextStyle(color: Colors.black87),
                    ),
                    const SizedBox(height: 24),
                    
                    // Enhanced location picker
                    Expanded(
                      child: Consumer<HomeProvider>(
                        builder: (context, homeProvider, child) {
                          print('DEBUG: AddLocationModal - Country from HomeProvider: ${homeProvider.selectedCountry}');
                          return EnhancedLocationPickerWidget(
                            selectedCountry: homeProvider.selectedCountry, // Use stored country
                            onLocationSelected: _onLocationSelected,
                            showTitle: false,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Footer with action buttons
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
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isFormValid ? _saveLocation : null,
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
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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

// Function to show the enhanced add location modal
Future<void> showEnhancedAddLocationModal(BuildContext context, Function(LocationModel) onLocationAdded) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return EnhancedAddLocationModal(
        onLocationAdded: onLocationAdded,
      );
    },
  );
}
