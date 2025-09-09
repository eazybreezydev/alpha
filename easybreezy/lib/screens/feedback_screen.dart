import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({Key? key}) : super(key: key);

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final _formKey = GlobalKey<FormState>();
  final _feedbackController = TextEditingController();
  final _emailController = TextEditingController();
  
  String _selectedFeedbackType = 'General Feedback';
  List<File> _attachedImages = [];
  
  final List<String> _feedbackTypes = [
    'Bug / Issue',
    'Feature Request', 
    'General Feedback',
    'Other'
  ];

  @override
  void dispose() {
    _feedbackController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image != null) {
      setState(() {
        _attachedImages.add(File(image.path));
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _attachedImages.removeAt(index);
    });
  }

  void _submitFeedback() async {
    if (_formKey.currentState!.validate()) {
      // Prepare email content
      String subject = 'Easy Breezy App Feedback - $_selectedFeedbackType';
      String body = '''
Feedback Type: $_selectedFeedbackType

Feedback Content:
${_feedbackController.text}

User Email: ${_emailController.text.isNotEmpty ? _emailController.text : 'Not provided'}

Screenshots Attached: ${_attachedImages.length} images

---
Sent from Easy Breezy App
''';

      // Create mailto URL
      String encodedSubject = Uri.encodeComponent(subject);
      String encodedBody = Uri.encodeComponent(body);
      String mailtoUrl = 'mailto:eazybreezydev@gmail.com?subject=$encodedSubject&body=$encodedBody';
      
      try {
        final Uri uri = Uri.parse(mailtoUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
          
          // Show success dialog after attempting to open email
          if (mounted) {
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: const Text('Feedback Ready to Send'),
                  content: const Text(
                    'Your email app should have opened with the feedback pre-filled. Please send the email to complete your feedback submission.\n\n'
                    'Thank you for helping make Easy Breezy better!'
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop(); // Close dialog
                        Navigator.of(context).pop(); // Close feedback screen
                      },
                      child: const Text('Done'),
                    ),
                  ],
                );
              },
            );
          }
        } else {
          // Fallback if email app can't be opened
          if (mounted) {
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: const Text('Email App Not Available'),
                  content: Text(
                    'Please send your feedback manually to: eazybreezydev@gmail.com\n\n'
                    'Subject: $subject\n\n'
                    'Message:\n$body'
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop(); // Close dialog
                        Navigator.of(context).pop(); // Close feedback screen
                      },
                      child: const Text('Done'),
                    ),
                  ],
                );
              },
            );
          }
        }
      } catch (e) {
        // Error handling
        if (mounted) {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('Error'),
                content: const Text(
                  'There was an error opening your email app. Please send your feedback manually to eazybreezydev@gmail.com'
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text('OK'),
                  ),
                ],
              );
            },
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Feedback',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Header Section
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade100),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.feedback,
                        color: Colors.blue.shade600,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Feedback Makes Easy Breezy Better',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'We\'d love your feedback! Share your ideas, issues, or suggestions to help make Easy Breezy even better.',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black87,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Feedback Type Dropdown
            const Text(
              'Feedback Type',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedFeedbackType,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              items: _feedbackTypes.map((String type) {
                return DropdownMenuItem<String>(
                  value: type,
                  child: Row(
                    children: [
                      _getFeedbackTypeIcon(type),
                      const SizedBox(width: 8),
                      Text(type),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedFeedbackType = newValue!;
                });
              },
            ),
            
            const SizedBox(height: 24),
            
            // Feedback Text Area
            const Text(
              'Your Feedback',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _feedbackController,
              maxLines: 6,
              decoration: InputDecoration(
                hintText: 'Tell us what\'s on your mind...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please tell us what\'s on your mind';
                }
                if (value.trim().length < 10) {
                  return 'Please provide more detail (at least 10 characters)';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 24),
            
            // Screenshot / Attachment Section
            if (_selectedFeedbackType == 'Bug / Issue') ...[
              const Text(
                'Screenshots (Optional)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Adding screenshots helps us understand and fix issues faster.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 12),
              
              // Image Picker Button
              OutlinedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.add_a_photo),
                label: const Text('Add Screenshot'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Display selected images
              if (_attachedImages.isNotEmpty) ...[
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _attachedImages.asMap().entries.map((entry) {
                    int index = entry.key;
                    File image = entry.value;
                    
                    return Stack(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              image,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          top: -4,
                          right: -4,
                          child: GestureDetector(
                            onTap: () => _removeImage(index),
                            child: Container(
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
              ],
            ],
            
            // Email Address (Optional)
            const Text(
              'Email Address (Optional)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Leave your email if you\'d like us to follow up with you.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                hintText: 'your.email@example.com',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                prefixIcon: const Icon(Icons.email_outlined),
              ),
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  // Basic email validation
                  if (!value.contains('@') || !value.contains('.')) {
                    return 'Please enter a valid email address';
                  }
                }
                return null;
              },
            ),
            
            const SizedBox(height: 32),
            
            // Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitFeedback,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Submit Feedback',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Privacy Note
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.privacy_tip_outlined,
                    color: Colors.grey.shade600,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Your feedback is important to us. We\'ll only use your email to respond to your feedback and will never share it with third parties.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                        height: 1.3,
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
  
  Widget _getFeedbackTypeIcon(String type) {
    switch (type) {
      case 'Bug / Issue':
        return const Icon(Icons.bug_report, color: Colors.red, size: 20);
      case 'Feature Request':
        return const Icon(Icons.lightbulb_outline, color: Colors.orange, size: 20);
      case 'General Feedback':
        return const Icon(Icons.chat_bubble_outline, color: Colors.blue, size: 20);
      case 'Other':
        return const Icon(Icons.more_horiz, color: Colors.grey, size: 20);
      default:
        return const Icon(Icons.feedback, color: Colors.blue, size: 20);
    }
  }
}
