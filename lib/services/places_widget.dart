import 'package:ctp/services/places_data_model.dart';
import 'package:ctp/services/places_services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';

class PlacesSearchField extends StatefulWidget {
  final TextEditingController controller;
  final Function(PlacesData) onSuggestionSelected;

  const PlacesSearchField({
    super.key,
    required this.controller,
    required this.onSuggestionSelected,
  });

  @override
  State<PlacesSearchField> createState() => _PlacesSearchFieldState();
}

class _PlacesSearchFieldState extends State<PlacesSearchField> {
  final FocusNode _focusNode = FocusNode();
  bool _suppress = false; // suppress suggestions after selection
  bool _hasSelected = false; // lock field after selection
  bool _isOpen = false; // track suggestions dropdown visibility heuristic

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      // ignore: avoid_print
      print(
          'PlacesSearchField: focus ${_focusNode.hasFocus ? 'GAINED' : 'LOST'}');
      if (!_focusNode.hasFocus) {
        if (_isOpen) {
          // ignore: avoid_print
          print('PlacesSearchField: suggestions CLOSE (focus lost)');
        }
        _isOpen = false;
      }
    });
  }

  Future<List<PlacesData>> _fetchSuggestions(String query) async {
    // Do not show suggestions while suppressed or after a confirmed selection
    if (_suppress || _hasSelected) return [];
    if (!_focusNode.hasFocus) return [];
    if (query.trim().length < 2) return []; // Only search if 2+ characters
    final results = await PlacesService.getSuggestions(query.trim());
    // ignore: avoid_print
    print('PlacesSearchField: query="$query" -> ${results.length} results');
    if (!_isOpen && results.isNotEmpty) {
      // ignore: avoid_print
      print('PlacesSearchField: suggestions OPEN (count=${results.length})');
      _isOpen = true;
    }
    if (_isOpen && results.isEmpty) {
      // ignore: avoid_print
      print('PlacesSearchField: suggestions CLOSE (no results)');
      _isOpen = false;
    }
    return results;
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TypeAheadField<PlacesData>(
      controller: widget.controller,
      focusNode: _focusNode,
      suggestionsCallback: _fetchSuggestions,
      hideOnEmpty: true,
      debounceDuration: const Duration(milliseconds: 350),
      loadingBuilder: (context) => SizedBox(
        height: 80,
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(color: Colors.blue),
          ),
        ),
      ),
      emptyBuilder: (context) => const Padding(
        padding: EdgeInsets.all(12.0),
        child: Text('No suggestions found',
            style: TextStyle(color: Colors.black54)),
      ),
      itemBuilder: (context, PlacesData suggestion) {
        return ListTile(
          title: Text(
            suggestion.description ?? "Unknown",
            style: const TextStyle(fontSize: 13, color: Colors.black),
          ),
        );
      },
      builder: (context, TextEditingController fieldController,
          FocusNode focusNode) {
        return TextFormField(
          controller: fieldController,
          focusNode: focusNode,
          // Allow typing anytime; we gate suggestions via _hasSelected/_suppress
          onChanged: (val) {
            if (_hasSelected) {
              // ignore: avoid_print
              print(
                  'PlacesSearchField: user typed after selection -> re-enable suggestions');
              setState(() {
                _hasSelected = false;
              });
            }
          },
          cursorColor: const Color(0xFFFF4E00),
          decoration: InputDecoration(
            hintText: "Address",
            hintStyle: const TextStyle(color: Colors.white70),
            filled: true,
            fillColor: Colors.white.withOpacity(0.2),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.5)),
            ),
            focusedBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(10.0)),
              borderSide: BorderSide(
                color: Color(0xFFFF4E00),
                width: 2.0,
              ),
            ),
          ),
          style: const TextStyle(color: Colors.white),
        );
      },
      onSelected: (PlacesData suggestion) {
        // Unfocus and lock to prevent the suggestions from reopening
        // ignore: avoid_print
        print('PlacesSearchField: onSelected -> ${suggestion.description}');
        _suppress = true;
        _hasSelected = true;
        _focusNode.unfocus();
        if (_isOpen) {
          // ignore: avoid_print
          print('PlacesSearchField: suggestions CLOSE (selection)');
          _isOpen = false;
        }
        // Defer text set + callback to next frame so overlay has time to close
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          widget.controller.text = suggestion.description ?? '';
          widget.onSuggestionSelected(suggestion);
          // Allow suggestions again after a short delay; still suppressed by _hasSelected
          await Future.delayed(const Duration(milliseconds: 250));
          if (mounted) setState(() => _suppress = false);
        });
      },
    );
  }
}

// import 'dart:async';
// import 'dart:developer';
// import 'package:ctp/services/places_data_model.dart';
// import 'package:ctp/services/places_services.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_async_autocomplete/flutter_async_autocomplete.dart';
//
// class PlacesSearchField extends StatefulWidget {
//   final TextEditingController controller;
//   final Function(PlacesData) onSuggestionSelected;
//
//   PlacesSearchField(
//       {Key? key, required this.controller, required this.onSuggestionSelected})
//       : super(key: key);
//
//   @override
//   _PlacesSearchFieldState createState() => _PlacesSearchFieldState();
// }
//
// class _PlacesSearchFieldState extends State<PlacesSearchField> {
//   Timer? _debounce;
//   ScrollController? _scrollController;
//
//   Future<List<PlacesData>> _getDebouncedSuggestions(String searchValue) async {
//     if (searchValue.length < 2) return []; // Only search if 2+ characters
//
//     if (_debounce?.isActive ?? false) _debounce!.cancel();
//     final completer = Completer<List<PlacesData>>();
//
//     _debounce = Timer(Duration(milliseconds: 500), () async {
//       final results = await PlacesService.getSuggestions(searchValue);
//       completer.complete(results);
//     });
//
//     return completer.future;
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return AsyncAutocomplete<PlacesData>(
//       controller: widget.controller,
//       inputTextStyle: TextStyle(
//         color: Colors.white,
//       ),
//       scrollBarController: _scrollController,
//       asyncSuggestions: _getDebouncedSuggestions,
//       onTapItem: (PlacesData place) {
//         debugPrint("Selected: ${place.description}");
//         log("Selected: ${place.description}");
//         print("Selected: ${place.description}");
//         setState(() {
//           widget.controller.text = place.description!;
//         });
//         widget.onSuggestionSelected(place);
//       },
//       suggestionBuilder: (place) => ListTile(
//         dense: true,
//         visualDensity: VisualDensity.compact,
//         contentPadding: EdgeInsets.zero,
//         title: Text(place.description!),
//       ),
//       decoration: InputDecoration(
//         hintText: "Address",
//         hintStyle: const TextStyle(color: Colors.white70),
//         filled: true,
//         fillColor: Colors.white.withOpacity(0.2),
//         border: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(10.0),
//           borderSide: BorderSide(color: Colors.white.withOpacity(0.5)),
//         ),
//         focusedBorder: const OutlineInputBorder(
//           borderRadius: BorderRadius.all(Radius.circular(10.0)),
//           borderSide: BorderSide(
//             color: Color(0xFFFF4E00),
//             width: 2.0,
//           ),
//         ),
//       ),
//     );
//   }
//
//   @override
//   void dispose() {
//     _debounce?.cancel();
//     super.dispose();
//   }
// }
