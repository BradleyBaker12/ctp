import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ctp/providers/form_data_provider.dart';

class FormNavigationWidget extends StatelessWidget {
  const FormNavigationWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<FormDataProvider>(
      builder: (context, formDataProvider, child) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 10.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildNavigationButton(
                  context, formDataProvider, Icons.looks_two, 0, 'Form 2'),
              _buildNavigationButton(
                  context, formDataProvider, Icons.looks_3, 1, 'Form 3'),
              _buildNavigationButton(
                  context, formDataProvider, Icons.looks_4, 2, 'Form 4'),
              _buildNavigationButton(
                  context, formDataProvider, Icons.looks_5, 3, 'Form 5'),
              _buildNavigationButton(
                  context, formDataProvider, Icons.looks_6, 4, 'Form 6'),
              _buildNavigationButton(
                  context, formDataProvider, Icons.looks_one, 5, 'Form 7'),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNavigationButton(
      BuildContext context,
      FormDataProvider formDataProvider,
      IconData icon,
      int index,
      String label) {
    int currentIndex = formDataProvider.currentFormIndex;
    return GestureDetector(
      onTap: () {
        formDataProvider.setCurrentFormIndex(index);
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: currentIndex == index
                ? Colors.white
                : Colors.white.withOpacity(0.6),
          ),
          Text(
            label,
            style: TextStyle(
              color: currentIndex == index
                  ? Colors.black
                  : Colors.black.withOpacity(0.6),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
