// lib/adminScreens/offers_tab.dart

import 'dart:async';
import 'package:ctp/adminScreens/offer_details_page.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/offer_provider.dart';

class OffersTab extends StatefulWidget {
  final String userId;
  final String userRole;

  const OffersTab({super.key, required this.userId, required this.userRole});

  @override
  _OffersTabState createState() => _OffersTabState();
}

class _OffersTabState extends State<OffersTab> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final ScrollController _scrollController = ScrollController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    // Fetch initial offers after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<OfferProvider>(context, listen: false)
          .fetchOffers(widget.userId, widget.userRole);
    });

    // Add scroll listener for pagination
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 200 &&
          !Provider.of<OfferProvider>(context, listen: false).isFetching &&
          Provider.of<OfferProvider>(context, listen: false).hasMore) {
        Provider.of<OfferProvider>(context, listen: false).fetchMoreOffers();
      }
    });

    // Add listener for search input with debounce
    _searchController.addListener(_onSearchChanged);
  }

  // Debounce search input
  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // Helper method to filter offers based on search query
  bool _matchesSearch(Offer offer) {
    if (_searchQuery.isEmpty) return true;

    String vehicleMakeModel = offer.vehicleMakeModel?.toLowerCase() ?? '';
    String dealerId = offer.dealerId.toLowerCase();
    String offerStatus = offer.offerStatus.toLowerCase();

    return vehicleMakeModel.contains(_searchQuery) ||
        dealerId.contains(_searchQuery) ||
        offerStatus.contains(_searchQuery);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search Bar
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            controller: _searchController,
            style: GoogleFonts.montserrat(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Search Offers',
              labelStyle: GoogleFonts.montserrat(color: Colors.white),
              prefixIcon: Icon(Icons.search, color: Colors.white),
              filled: true,
              fillColor: Colors.transparent,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: BorderSide(color: Colors.white),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: BorderSide(color: Color(0xFFFF4E00)),
              ),
            ),
          ),
        ),
        // Expanded ListView
        Expanded(
          child: Consumer<OfferProvider>(
            builder: (context, offerProvider, child) {
              if (offerProvider.isFetching && offerProvider.offers.isEmpty) {
                // Initial loading
                return Center(
                  child: CircularProgressIndicator(
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Color(0xFFFF4E00)),
                  ),
                );
              }

              if (offerProvider.errorMessage != null &&
                  offerProvider.offers.isEmpty) {
                return Center(
                  child: Text(
                    offerProvider.errorMessage!,
                    style: GoogleFonts.montserrat(color: Colors.redAccent),
                  ),
                );
              }

              if (offerProvider.offers.isEmpty) {
                return Center(
                  child: Text(
                    'No offers found.',
                    style: GoogleFonts.montserrat(color: Colors.white),
                  ),
                );
              }

              // Apply filtering
              final filteredOffers = offerProvider.offers.where((offer) {
                return _matchesSearch(offer);
              }).toList();

              if (filteredOffers.isEmpty) {
                return Center(
                  child: Text(
                    'No offers match your search.',
                    style: GoogleFonts.montserrat(color: Colors.white),
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () async {
                  await Provider.of<OfferProvider>(context, listen: false)
                      .refreshOffers();
                },
                child: ListView.builder(
                  controller: _scrollController,
                  itemCount: filteredOffers.length +
                      (offerProvider.hasMore ? 1 : 0), // Extra item for loading
                  itemBuilder: (context, index) {
                    if (index == filteredOffers.length) {
                      // Loading indicator at the bottom
                      if (offerProvider.isFetching) {
                        return Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  Color(0xFFFF4E00)),
                            ),
                          ),
                        );
                      } else {
                        return SizedBox.shrink();
                      }
                    }

                    Offer offer = filteredOffers[index];

                    return Card(
                      color: Colors.grey[900],
                      margin: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      child: ListTile(
                        leading: offer.vehicleMainImage != null
                            ? Image.network(
                                offer.vehicleMainImage!,
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Icon(Icons.directions_car,
                                      color: Colors.blueAccent);
                                },
                                loadingBuilder:
                                    (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Color(0xFFFF4E00)),
                                  );
                                },
                              )
                            : Icon(Icons.directions_car,
                                color: Colors.blueAccent),
                        title: Text(
                          "${offer.vehicleMakeModel ?? 'No Title'}\nR ${offer.offerAmount?.toStringAsFixed(2) ?? 'N/A'}",
                          style: GoogleFonts.montserrat(
                              fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        subtitle: Text(
                          'Status: ${offer.offerStatus}',
                          style: GoogleFonts.montserrat(color: Colors.white70),
                        ),
                        isThreeLine: true,
                        trailing:
                            Icon(Icons.arrow_forward_ios, color: Colors.white),
                        onTap: () {
                          // Navigate to OfferDetailPage
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  OfferDetailPage(offer: offer),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
