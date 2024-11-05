import 'package:ctp/pages/truckForms/basic_information.dart';
import 'package:ctp/pages/truckForms/external_cab_form.dart';
import 'package:ctp/pages/truckForms/internal_cab_form.dart';
import 'package:flutter/material.dart';

Map<String, Widget Function(BuildContext)> routes = {
  '/basic-info': (context) => const BasicInformationForm(),
  '/external-cab': (context) {
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    return ExternalCabForm(formData: args);
  },
  '/internal-cab': (context) {
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    return InternalCabForm(formData: args);
  },
  // ... other routes
};
