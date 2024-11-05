import 'package:flutter/material.dart';

abstract class BaseConditionPage extends StatefulWidget {
  final Map<String, dynamic> initialData;
  final Function(bool) onModified;

  const BaseConditionPage({
    Key? key,
    required this.initialData,
    required this.onModified,
  }) : super(key: key);
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
