import 'package:flutter/material.dart';

abstract class BaseConditionPage extends StatefulWidget {
  final Map<String, dynamic> initialData;
  final Function(bool) onModified;

  const BaseConditionPage({
    super.key,
    required this.initialData,
    required this.onModified,
  });
}

abstract class BaseConditionPageState<T extends BaseConditionPage>
    extends State<T> {
  bool _isModified = false;

  void markAsModified() {
    if (!_isModified) {
      _isModified = true;
      widget.onModified(true);
    }
  }

  Future<Map<String, dynamic>> getData();

  void initializeWithData(Map<String, dynamic> data);
}
