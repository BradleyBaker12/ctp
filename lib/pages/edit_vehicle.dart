import 'package:ctp/components/gradient_background.dart';
import 'package:ctp/components/custom_button.dart';
import 'package:ctp/providers/vehicles_provider.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class EditVehiclePage extends StatefulWidget {
  final Vehicle vehicle;

  const EditVehiclePage({super.key, required this.vehicle});

  @override
  _EditVehiclePageState createState() => _EditVehiclePageState();
}

class _EditVehiclePageState extends State<EditVehiclePage> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();
  Map<String, TextEditingController> _controllers = {};
  bool _isLoading = false;

  final Map<String, List<String?>> _imageUrls = {
    'licenceDiskUrl': [],
    'dashboardPhoto': [],
    'faultCodesPhoto': [],
    'damagePhotos': [],
    'tyrePhoto1': [],
    'tyrePhoto2': [],
    'frontView': [],
    'rightSideView': [],
    'leftSideView': [],
    'rearView': [],
    'rightFront45View': [],
    'rightRear45View': [],
    'leftFront45View': [],
    'leftRear45View': [],
    'frontTyreTread': [],
    'rearTyresTread': [],
    'spareWheelLicenseDisk': [],
    'seats': [],
    'bedBunk': [],
    'roof': [],
    'mileageImage': [],
    'dashboard': [],
    'doorPanels': [],
  };

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _initializeImageUrls();
  }

  void _initializeControllers() {
    _controllers = {
      'makeModel': TextEditingController(text: widget.vehicle.makeModel),
      'engineNumber': TextEditingController(text: widget.vehicle.engineNumber),
      'registrationNumber':
          TextEditingController(text: widget.vehicle.registrationNumber),
      'transmission': TextEditingController(text: widget.vehicle.transmission),
      'year': TextEditingController(text: widget.vehicle.year),
      'bookValue': TextEditingController(text: widget.vehicle.bookValue),
      'damageDescription':
          TextEditingController(text: widget.vehicle.damageDescription),
      'hydraulics': TextEditingController(text: widget.vehicle.hydraulics),
      'suspension': TextEditingController(text: widget.vehicle.suspension),
      'tyreType': TextEditingController(text: widget.vehicle.tyreType),
      'vinNumber': TextEditingController(text: widget.vehicle.vinNumber),
      'settlementAmount':
          TextEditingController(text: widget.vehicle.settlementAmount),
    };
  }

  void _initializeImageUrls() {
    _imageUrls['licenceDiskUrl'] = widget.vehicle.licenceDiskUrl != null
        ? [widget.vehicle.licenceDiskUrl]
        : [];
    _imageUrls['dashboardPhoto'] = widget.vehicle.dashboardPhoto != null
        ? [widget.vehicle.dashboardPhoto]
        : [];
    _imageUrls['faultCodesPhoto'] = widget.vehicle.faultCodesPhoto != null
        ? [widget.vehicle.faultCodesPhoto]
        : [];
    _imageUrls['damagePhotos'] = widget.vehicle.damagePhotos.isNotEmpty
        ? widget.vehicle.damagePhotos
        : [];
    _imageUrls['tyrePhoto1'] =
        widget.vehicle.tyrePhoto1 != null ? [widget.vehicle.tyrePhoto1] : [];
    _imageUrls['tyrePhoto2'] =
        widget.vehicle.tyrePhoto2 != null ? [widget.vehicle.tyrePhoto2] : [];
    _imageUrls['mileageImage'] = widget.vehicle.mileageImage != null
        ? [widget.vehicle.mileageImage]
        : [];
    _imageUrls['frontView'] = [];
    _imageUrls['rightSideView'] = [];
    _imageUrls['leftSideView'] = [];
    _imageUrls['rearView'] = [];
    _imageUrls['rightFront45View'] = [];
    _imageUrls['rightRear45View'] = [];
    _imageUrls['leftFront45View'] = [];
    _imageUrls['leftRear45View'] = [];
    _imageUrls['frontTyreTread'] = [];
    _imageUrls['rearTyresTread'] = [];
    _imageUrls['spareWheelLicenseDisk'] = [];
    _imageUrls['seats'] = [];
    _imageUrls['bedBunk'] = [];
    _imageUrls['roof'] = [];
    _imageUrls['dashboard'] = [];
    _imageUrls['doorPanels'] = [];
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _pickImage(String imageType, int index) async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        if (_imageUrls[imageType]!.length > index) {
          _imageUrls[imageType]![index] = pickedFile.path;
        } else {
          _imageUrls[imageType]!.add(pickedFile.path);
        }
      });
    }
  }

  Future<String> _uploadImage(
      String path, String vehicleId, String imageType, int index) async {
    final ref = FirebaseStorage.instance
        .ref()
        .child('vehicle_images/$vehicleId/$imageType/image_$index.jpg');
    final result = await ref.putFile(File(path));
    return await result.ref.getDownloadURL();
  }

  Future<void> _saveVehicle() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        Map<String, List<String?>> uploadedImageUrls = {};

        for (var entry in _imageUrls.entries) {
          List<String?> images = [];
          for (int i = 0; i < entry.value.length; i++) {
            if (entry.value[i] != null && entry.value[i]!.contains('http')) {
              images.add(entry.value[i]);
            } else if (entry.value[i] != null) {
              final imageUrl = await _uploadImage(
                  entry.value[i]!, widget.vehicle.id, entry.key, i);
              images.add(imageUrl);
            }
          }
          uploadedImageUrls[entry.key] = images;
        }

        await FirebaseFirestore.instance
            .collection('vehicles')
            .doc(widget.vehicle.id)
            .update({
          'makeModel': _controllers['makeModel']!.text,
          'engineNumber': _controllers['engineNumber']!.text,
          'registrationNumber': _controllers['registrationNumber']!.text,
          'transmission': _controllers['transmission']!.text,
          'year': _controllers['year']!.text,
          'bookValue': _controllers['bookValue']!.text,
          'damageDescription': _controllers['damageDescription']!.text,
          'hydraulics': _controllers['hydraulics']!.text,
          'suspension': _controllers['suspension']!.text,
          'tyreType': _controllers['tyreType']!.text,
          'vinNumber': _controllers['vinNumber']!.text,
          'settlementAmount': _controllers['settlementAmount']!.text,
          'images': uploadedImageUrls,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vehicle updated successfully!')),
        );
        Navigator.of(context).pop();
      } catch (e) {
        print('Error updating vehicle: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update vehicle')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildImageGallery(String imageType) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$imageType Images',
          style: const TextStyle(
              color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _imageUrls[imageType]!.asMap().entries.map((entry) {
            int index = entry.key;
            String? imageUrl = entry.value;
            return Stack(
              children: [
                GestureDetector(
                  onTap: () => _pickImage(imageType, index),
                  child: Image.network(
                    imageUrl?.contains('http') ?? false ? imageUrl! : '',
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 100,
                      height: 100,
                      color: Colors.grey,
                      child: const Center(
                          child: Icon(Icons.image, color: Colors.white)),
                    ),
                  ),
                ),
                Positioned(
                  top: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _imageUrls[imageType]!.removeAt(index);
                      });
                    },
                    child: const Icon(Icons.remove_circle, color: Colors.red),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
        CustomButton(
          text: 'Add New Image',
          borderColor: Colors.orange,
          onPressed: () => _pickImage(imageType, _imageUrls[imageType]!.length),
        ),
      ],
    );
  }

  Widget _buildTextField(String label, String field) {
    return TextFormField(
      controller: _controllers[field],
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white),
      ),
      style: const TextStyle(color: Colors.white),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            const Text('Edit Vehicle', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
      ),
      body: GradientBackground(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTextField('Make and Model', 'makeModel'),
                        _buildTextField('Engine Number', 'engineNumber'),
                        _buildTextField(
                            'Registration Number', 'registrationNumber'),
                        _buildTextField('Transmission', 'transmission'),
                        _buildTextField('Year', 'year'),
                        _buildTextField('Book Value', 'bookValue'),
                        _buildTextField(
                            'Damage Description', 'damageDescription'),
                        _buildTextField('Hydraulics', 'hydraulics'),
                        _buildTextField('Suspension', 'suspension'),
                        _buildTextField('Tyre Type', 'tyreType'),
                        _buildTextField('VIN Number', 'vinNumber'),
                        _buildTextField(
                            'Settlement Amount', 'settlementAmount'),
                        const SizedBox(height: 16),
                        _buildImageGallery('licenceDiskUrl'),
                        _buildImageGallery('dashboardPhoto'),
                        _buildImageGallery('faultCodesPhoto'),
                        _buildImageGallery('damagePhotos'),
                        _buildImageGallery('tyrePhoto1'),
                        _buildImageGallery('tyrePhoto2'),
                        _buildImageGallery('frontView'),
                        _buildImageGallery('rightSideView'),
                        _buildImageGallery('leftSideView'),
                        _buildImageGallery('rearView'),
                        _buildImageGallery('rightFront45View'),
                        _buildImageGallery('rightRear45View'),
                        _buildImageGallery('leftFront45View'),
                        _buildImageGallery('leftRear45View'),
                        _buildImageGallery('frontTyreTread'),
                        _buildImageGallery('rearTyresTread'),
                        _buildImageGallery('spareWheelLicenseDisk'),
                        _buildImageGallery('seats'),
                        _buildImageGallery('bedBunk'),
                        _buildImageGallery('roof'),
                        _buildImageGallery('mileageImage'),
                        _buildImageGallery('dashboard'),
                        _buildImageGallery('doorPanels'),
                        const SizedBox(height: 16),
                        CustomButton(
                          text: 'Save Changes',
                          borderColor: Colors.orange,
                          onPressed: _saveVehicle,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
