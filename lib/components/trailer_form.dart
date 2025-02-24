import 'package:flutter/material.dart';
import 'package:ctp/models/trailer.dart';
import 'package:ctp/providers/form_data_provider.dart';

class TrailerForm extends StatefulWidget {
  final Trailer? initialTrailer;
  final bool isEdit;
  final bool isAdminUpload;
  final String? transporterId;
  final Future<void> Function(Trailer trailer) onSubmit;

  const TrailerForm({
    Key? key,
    this.initialTrailer,
    required this.isEdit,
    required this.isAdminUpload,
    this.transporterId,
    required this.onSubmit,
  }) : super(key: key);

  @override
  _TrailerFormState createState() => _TrailerFormState();
}

class _TrailerFormState extends State<TrailerForm> {
  final _formKey = GlobalKey<FormState>();
  // Common text controllers
  final TextEditingController _makeController = TextEditingController();
  final TextEditingController _yearController = TextEditingController();
  final TextEditingController _axlesController = TextEditingController();
  final TextEditingController _lengthController = TextEditingController();
  final TextEditingController _vinController = TextEditingController();
  final TextEditingController _registrationController = TextEditingController();
  final TextEditingController _sellingPriceController = TextEditingController();
  final TextEditingController _warrantyDetailsController =
      TextEditingController();
  // Trailer type dropdown
  String? _selectedTrailerType;

  @override
  void initState() {
    super.initState();
    if (widget.initialTrailer != null) {
      // Populate fields from initialTrailer (for edit)
      final t = widget.initialTrailer!;
      _makeController.text = t.makeModel;
      _yearController.text = t.year;
      _axlesController.text = t.axles;
      _lengthController.text = t.length;
      _vinController.text = t.vinNumber;
      _registrationController.text = t.registrationNumber;
      _sellingPriceController.text = t.sellingPrice;
      _warrantyDetailsController.text = t.warrantyDetails;
      _selectedTrailerType = t.trailerType;
    }
  }

  @override
  void dispose() {
    _makeController.dispose();
    _yearController.dispose();
    _axlesController.dispose();
    _lengthController.dispose();
    _vinController.dispose();
    _registrationController.dispose();
    _sellingPriceController.dispose();
    _warrantyDetailsController.dispose();
    super.dispose();
  }

  void _handleSubmit() async {
    if (_formKey.currentState!.validate()) {
      // Build Trailer object
      final trailer = Trailer(
        id: widget.initialTrailer?.id ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        makeModel: _makeController.text,
        year: _yearController.text,
        trailerType: _selectedTrailerType ?? '',
        axles: _axlesController.text,
        length: _lengthController.text,
        vinNumber: _vinController.text,
        registrationNumber: _registrationController.text,
        mileage: '', // Fill as needed
        engineNumber: '', // Fill as needed
        sellingPrice: _sellingPriceController.text,
        warrantyDetails: _warrantyDetailsController.text,
        referenceNumber: '', // Fill as needed
        country: '', // Fill as needed
        province: '', // Fill as needed
        vehicleStatus: '', // Fill as needed
        userId: widget.transporterId ?? '', // or current user id
        assignedSalesRepId: null,
        createdAt: widget.initialTrailer?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
        natisDocumentUrl: '',
        serviceHistoryUrl: '',
        mainImageUrl: '',
        frontImageUrl: '',
        sideImageUrl: '',
        tyresImageUrl: '',
        chassisImageUrl: '',
        deckImageUrl: '',
        makersPlateImageUrl: '',
        additionalImages: const [],
        superlinkData: null, // Extend with type-specific info if needed
        triAxleData: null, // Extend with type-specific info if needed
        damages: const [],
        damagesCondition: 'no',
        features: const [],
        featuresCondition: 'no',
        brands: const [],
      );
      await widget.onSubmit(trailer);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          // Common fields
          TextFormField(
            controller: _makeController,
            decoration: const InputDecoration(labelText: 'Make'),
            validator: (val) =>
                val == null || val.isEmpty ? 'Enter make' : null,
          ),
          TextFormField(
            controller: _yearController,
            decoration: const InputDecoration(labelText: 'Year'),
            validator: (val) =>
                val == null || val.isEmpty ? 'Enter year' : null,
          ),
          TextFormField(
            controller: _axlesController,
            decoration: const InputDecoration(labelText: 'Axles'),
            validator: (val) =>
                val == null || val.isEmpty ? 'Enter axles' : null,
          ),
          TextFormField(
            controller: _lengthController,
            decoration: const InputDecoration(labelText: 'Length'),
            validator: (val) =>
                val == null || val.isEmpty ? 'Enter length' : null,
          ),
          TextFormField(
            controller: _vinController,
            decoration: const InputDecoration(labelText: 'VIN Number'),
            validator: (val) => val == null || val.isEmpty ? 'Enter VIN' : null,
          ),
          TextFormField(
            controller: _registrationController,
            decoration: const InputDecoration(labelText: 'Registration Number'),
            validator: (val) =>
                val == null || val.isEmpty ? 'Enter reg number' : null,
          ),
          TextFormField(
            controller: _sellingPriceController,
            decoration: const InputDecoration(labelText: 'Selling Price'),
            validator: (val) =>
                val == null || val.isEmpty ? 'Enter selling price' : null,
          ),
          TextFormField(
            controller: _warrantyDetailsController,
            decoration: const InputDecoration(labelText: 'Warranty Details'),
          ),
          DropdownButtonFormField<String>(
            value: _selectedTrailerType,
            decoration: const InputDecoration(labelText: 'Trailer Type'),
            items: const [
              DropdownMenuItem(child: Text('Superlink'), value: 'Superlink'),
              DropdownMenuItem(child: Text('Tri-Axle'), value: 'Tri-Axle'),
              DropdownMenuItem(
                  child: Text('Double Axle'), value: 'Double Axle'),
              DropdownMenuItem(child: Text('Other'), value: 'Other'),
            ],
            onChanged: (value) => setState(() => _selectedTrailerType = value),
            validator: (val) =>
                val == null || val.isEmpty ? 'Select trailer type' : null,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _handleSubmit,
            child: Text(widget.isEdit ? 'Update Trailer' : 'Upload Trailer'),
          ),
        ],
      ),
    );
  }
}
