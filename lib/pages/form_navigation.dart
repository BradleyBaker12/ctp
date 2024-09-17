import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ctp/providers/form_data_provider.dart';
import 'package:ctp/pages/truckForms/vehcileUpload_form2.dart';
import 'package:ctp/pages/truckForms/vehcileUpload_form3.dart';
import 'package:ctp/pages/truckForms/vehcileUpload_form4.dart';
import 'package:ctp/pages/truckForms/vehcileUpload_form5.dart';
import 'package:ctp/pages/truckForms/vehcileUpload_form6.dart';
import 'package:ctp/pages/truckForms/vehcileUpload_form7.dart';

class FormNavigationPage extends StatelessWidget {
  final List<Widget> _formPages = [
    SecondFormPage(),
    ThirdFormPage(),
    FourthFormPage(),
    FifthFormPage(),
    SixthFormPage(),
    SeventhFormPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer<FormDataProvider>(
      builder: (context, formDataProvider, child) {
        int _currentIndex = formDataProvider.currentFormIndex;
        print('Building FormNavigationPage with _currentIndex=$_currentIndex');

        return Scaffold(
          body: _formPages[_currentIndex],
          bottomNavigationBar: Theme(
            data: Theme.of(context).copyWith(canvasColor: Color(0xFF2F7FFF)),
            child: BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (int index) {
                formDataProvider.setCurrentFormIndex(index);
              },
              backgroundColor: const Color(0xFF2F7FFF), // Blue color background
              selectedItemColor: Colors.black, // Selected icon color
              unselectedItemColor:
                  Colors.black.withOpacity(0.6), // Unselected icon color
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.looks_two),
                  label: 'Form 2',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.looks_3),
                  label: 'Form 3',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.looks_4),
                  label: 'Form 4',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.looks_5),
                  label: 'Form 5',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.looks_6),
                  label: 'Form 6',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.looks_one),
                  label: 'Form 7',
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
