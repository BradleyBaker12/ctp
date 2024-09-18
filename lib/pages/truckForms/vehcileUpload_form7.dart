import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:ctp/components/blurry_app_bar.dart';
import 'package:ctp/components/custom_back_button.dart';
import 'package:ctp/components/custom_button.dart';
import 'package:ctp/components/gradient_background.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:ctp/providers/user_provider.dart';
import 'package:ctp/providers/vehicles_provider.dart'; // Import VehicleProvider
import 'package:ctp/providers/form_data_provider.dart'; // Import FormDataProvider
// import 'package:path/path.dart' as path;

class SeventhFormPage extends StatefulWidget {
  const SeventhFormPage({super.key});

  @override
  _SeventhFormPageState createState() => _SeventhFormPageState();
}

class _SeventhFormPageState extends State<SeventhFormPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  late FormDataProvider formDataProvider;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    formDataProvider = Provider.of<FormDataProvider>(context);

    // Debugging code
    print(
        "SeventhFormPage: vehicleId from FormDataProvider in didChangeDependencies: ${formDataProvider.vehicleId}");
  }

  Future<void> _pickImage(ImageSource source, {required int index}) async {
    try {
      final pickedFile = await ImagePicker().pickImage(source: source);
      if (pickedFile != null) {
        // Use the setter method from FormDataProvider
        formDataProvider.setPhotoAtIndex(index, File(pickedFile.path));
      }
    } catch (e) {
      print("Error picking image at index $index: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  void _pickImageDialog(int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Choose Image Source'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _pickImage(ImageSource.camera, index: index);
              },
              child: const Text('Camera'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _pickImage(ImageSource.gallery, index: index);
              },
              child: const Text('Gallery'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _submitForm() async {
    print("Submitting SeventhFormPage form...");

    setState(() {
      _isLoading = true;
    });

    try {
      final FirebaseFirestore firestore = FirebaseFirestore.instance;
      final FirebaseStorage storage = FirebaseStorage.instance;

      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final vehicleProvider =
          Provider.of<VehicleProvider>(context, listen: false);

      String? userId = userProvider.userId;
      String? vehicleId = vehicleProvider.vehicleId;

      print("User ID: $userId");
      print("Vehicle ID: $vehicleId");

      if (userId == null) {
        print("Error: userId is null");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: User not logged in.')),
        );
        return;
      }

      if (vehicleId != null) {
        // Upload images and get URLs
        Map<String, String?> photoUrls = {};
        List<String> photoLabels = [
          'front_view',
          'right_side_view',
          'left_side_view',
          'rear_view',
          'left_front_45',
          'right_front_45',
          'left_rear_45',
          'right_rear_45',
          'front_tyres_tread',
          'rear_tyres_tread',
          'spare_wheel',
          'license_disk',
          'seats',
          'bed_bunk',
          'roof',
          'mileage_image',
          'dashboard',
          'door_panels',
        ];

        for (int i = 0; i < formDataProvider.photoPaths.length; i++) {
          if (formDataProvider.photoPaths[i] != null) {
            print("Uploading image at index $i...");
            String fileName = '${photoLabels[i]}.jpg';

            // Define the storage path
            final ref = storage.ref().child('vehicles/$vehicleId/$fileName');

            final uploadTask = ref.putFile(formDataProvider.photoPaths[i]!);
            final snapshot = await uploadTask;
            String downloadUrl = await snapshot.ref.getDownloadURL();

            photoUrls[photoLabels[i]] = downloadUrl;

            print("Image uploaded for ${photoLabels[i]}: $downloadUrl");
          } else {
            print("No image selected for index $i (${photoLabels[i]}).");
          }
        }

        // Update the existing vehicle document using vehicleId
        print("Updating Firestore document for vehicle...");
        await firestore.collection('vehicles').doc(vehicleId).update({
          ...photoUrls,
          'userId': userId,
        });

        print("Form submitted successfully!");

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Form submitted successfully!')),
        );

        // Navigate to the next form or update the form index
        formDataProvider.incrementFormIndex();
      } else {
        print('Error: vehicleId is null');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: Vehicle ID is null.')),
        );
      }
    } catch (e, stackTrace) {
      print("Error submitting form: $e");
      print("Stack trace: $stackTrace");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error submitting form: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    print("Building SeventhFormPage...");

    final File? imageFile = formDataProvider.selectedMainImage;
    final String? vehicleId = formDataProvider.vehicleId;

    print('Debug: vehicleId in SeventhFormPage build method: $vehicleId');

    if (vehicleId == null) {
      return Scaffold(
        body: Center(
          child: const Text(
            'Invalid or missing vehicle ID. Please try again.',
            style: TextStyle(color: Colors.red),
          ),
        ),
      );
    }

    var orange = const Color(0xFFFF4E00);

    return Scaffold(
      body: Stack(
        children: [
          GradientBackground(
            child: Column(
              children: [
                const BlurryAppBar(),
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 8.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 20),
                            Center(
                              child: Column(
                                children: [
                                  Container(
                                    height: 300,
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(16.0),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.3),
                                      borderRadius: BorderRadius.circular(10.0),
                                    ),
                                    child: imageFile == null
                                        ? const Text(
                                            'No image selected',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                            ),
                                          )
                                        : ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(10.0),
                                            child: Image.file(
                                              imageFile,
                                              width: double.infinity,
                                              height: double.infinity,
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            const Center(
                              child: Text(
                                'TRUCK/TRAILER FORM',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(height: 10),
                            const Center(
                              child: Text(
                                'Photos of Truck',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(height: 20),
                            const Center(
                              child: Text(
                                'Exterior Photos',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(height: 10),
                            _buildPhotoGrid(0, 4),
                            const SizedBox(height: 20),
                            const Center(
                              child: Text(
                                'Exterior Photos Required',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(height: 10),
                            _buildPhotoGrid(4, 12),
                            const SizedBox(height: 20),
                            const Center(
                              child: Text(
                                'Interior Photos Required',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(height: 10),
                            _buildPhotoGrid(12, 18),
                            const SizedBox(height: 20),
                            Center(
                              child: CustomButton(
                                text: _isLoading ? 'Submitting...' : 'CONTINUE',
                                borderColor: orange,
                                onPressed: _isLoading
                                    ? () {
                                        print(
                                            "Submit button pressed while loading.");
                                      }
                                    : () {
                                        print("Submit button pressed.");
                                        _submitForm();
                                      },
                              ),
                            ),
                            const SizedBox(height: 10),
                            Center(
                              child: TextButton(
                                onPressed: () {
                                  print("Cancel button pressed.");
                                  Navigator.pop(context);
                                },
                                child: const Text(
                                  'CANCEL',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                            const SizedBox(height: 30),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
          const Positioned(
            top: 40,
            left: 16,
            child: CustomBackButton(),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoGrid(int startIndex, int endIndex) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: endIndex - startIndex,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10.0,
        mainAxisSpacing: 10.0,
        childAspectRatio: 1.5,
      ),
      itemBuilder: (context, index) {
        int actualIndex = startIndex + index;
        print("Building grid item at index $actualIndex");
        return GestureDetector(
          onTap: () => _pickImageDialog(actualIndex),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(10.0),
              border: Border.all(color: Colors.white70, width: 1),
            ),
            child: Center(
              child: formDataProvider.photoPaths[actualIndex] == null
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.add, color: Colors.blue, size: 40),
                        Text(
                          _getPhotoLabel(actualIndex),
                          style: const TextStyle(color: Colors.white),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(10.0),
                      child: Image.file(
                        formDataProvider.photoPaths[actualIndex]!,
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
            ),
          ),
        );
      },
    );
  }

  String _getPhotoLabel(int index) {
    switch (index) {
      case 0:
        return 'Front View';
      case 1:
        return 'Right Side View';
      case 2:
        return 'Left Side View';
      case 3:
        return 'Rear View';
      case 4:
        return '45° Left Front View';
      case 5:
        return '45° Right Front View';
      case 6:
        return '45° Left Rear View';
      case 7:
        return '45° Right Rear View';
      case 8:
        return 'Front Tyres Tread';
      case 9:
        return 'Rear Tyres Tread';
      case 10:
        return 'Spare Wheel';
      case 11:
        return 'License Disk';
      case 12:
        return 'Seats';
      case 13:
        return 'Bed Bunk';
      case 14:
        return 'Roof';
      case 15:
        return 'Mileage';
      case 16:
        return 'Dashboard';
      case 17:
        return 'Door Panels';
      default:
        return 'Unknown Label';
    }
  }
}
