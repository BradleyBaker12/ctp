import 'package:ctp/components/form_navigation_widget.dart';
import 'package:flutter/material.dart';
import 'package:ctp/pages/truckForms/vehcileUpload_form2.dart';
import 'package:ctp/pages/truckForms/vehcileUpload_form3.dart';
import 'package:ctp/pages/truckForms/vehcileUpload_form4.dart';
import 'package:ctp/pages/truckForms/vehcileUpload_form5.dart';
import 'package:ctp/pages/truckForms/vehcileUpload_form6.dart';
import 'package:ctp/pages/truckForms/vehcileUpload_form7.dart';
import 'package:provider/provider.dart';

import '../providers/form_data_provider.dart'; // Import the navigation widget

class FormNavigationPage extends StatelessWidget {
  final List<Widget> _formPages = [
    SecondFormPage(),
    ThirdFormPage(),
    FourthFormPage(),
    FifthFormPage(),
    SixthFormPage(),
    SeventhFormPage(),
  ];

  FormNavigationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Header image section
          Container(
            color: Colors.blue, // Replace with actual image if necessary
            width: double.infinity,
            height: 150.0, // Set the height as per your design
            child: Center(
              child: Text(
                'Header Image',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
          ),
          SizedBox(height: 10), // Space between header and form navigation

          // Use the FormNavigationWidget
          FormNavigationWidget(),

          SizedBox(height: 10), // Space between navigation and form content

          // Displaying the form page based on the current index
          Expanded(
            child: Consumer<FormDataProvider>(
              builder: (context, formDataProvider, child) {
                int currentIndex = formDataProvider.currentFormIndex;
                return _formPages[currentIndex];
              },
            ),
          ),
        ],
      ),
    );
  }
}
