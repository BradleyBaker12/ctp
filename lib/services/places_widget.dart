import 'package:ctp/services/places_data_model.dart';
import 'package:ctp/services/places_services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';

class PlacesSearchField extends StatelessWidget {
  final TextEditingController controller;
  final Function(PlacesData) onSuggestionSelected;

  PlacesSearchField({
    Key? key,
    required this.controller,
    required this.onSuggestionSelected,
  }) : super(key: key);

  Future<List<PlacesData>> _fetchSuggestions(String query) async {
    if (query.length < 2) return []; // Only search if 2+ characters
    return await PlacesService.getSuggestions(query); // Fetch places data
  }

  @override
  Widget build(BuildContext context) {
    return TypeAheadField<PlacesData>(
      controller: controller,
      suggestionsCallback: _fetchSuggestions,
      hideOnEmpty: true,
      loadingBuilder: (context) => SizedBox(
        height: 80,
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              color: Colors.blue,
            ),
          ),
        ),
      ),
      itemBuilder: (context, PlacesData suggestion) {
        return ListTile(
          title: Text(
            suggestion.description ?? "Unknown",
            style: TextStyle(
              fontSize: 13,
            ),
          ),
        );
      },
      builder: (context, controller, focusNode) {
        return TextFormField(
          controller: controller,
          focusNode: focusNode,
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
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter address';
            }
            return null;
          },
        );
      },
      onSelected: (PlacesData suggestion) {
        controller.text = suggestion.description ?? '';
        onSuggestionSelected(suggestion);
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
