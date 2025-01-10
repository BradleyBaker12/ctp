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

  String _sortField = 'createdAt';
  bool _sortAscending = false;
  String _filterStatus = 'All';

  final List<String> _filterOptions = [
    'All',
    'Pending',
    'Accepted',
    'Rejected',
    'Expired'
  ];
  List<String> _selectedFilters = [];

  final List<Map<String, String>> _sortOptions = [
    {'field': 'createdAt', 'label': 'Date'},
    {'field': 'offerAmount', 'label': 'Amount'},
    {'field': 'offerStatus', 'label': 'Status'}
  ];

  // Add stream subscription
  StreamSubscription? _offerSubscription;

  @override
  void initState() {
    super.initState();
    print('DEBUG: OffersTab initState');
    print('DEBUG: userId: ${widget.userId}, userRole: ${widget.userRole}');

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      print('DEBUG: Post frame callback executing');
      final offerProvider = Provider.of<OfferProvider>(context, listen: false);
      offerProvider.initialize(widget.userId, widget.userRole);
      print('DEBUG: Provider initialized, fetching offers');
      await offerProvider.refreshOffers();
      print('DEBUG: Initial fetch completed');
    });

    _offerSubscription = Provider.of<OfferProvider>(context, listen: false)
        .offersStream
        .listen((offers) {
      print('DEBUG: Stream update - offers count: ${offers.length}');
      if (mounted) setState(() {});
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

  Future<void> _initializeData() async {
    if (mounted) {
      await Provider.of<OfferProvider>(context, listen: false).refreshOffers();
    }
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
    _offerSubscription?.cancel();
    _debounce?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _showSortMenu() async {
    final RenderBox button = context.findRenderObject() as RenderBox;
    final RenderBox overlay =
        Overlay.of(context)!.context.findRenderObject() as RenderBox;
    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(Offset.zero, ancestor: overlay),
        button.localToGlobal(button.size.bottomRight(Offset.zero),
            ancestor: overlay),
      ),
      Offset.zero & overlay.size,
    );

    await showMenu(
      context: context,
      position: position,
      color: Colors.grey[900],
      items: _sortOptions.map((option) {
        return PopupMenuItem<String>(
          value: option['field'],
          child: Row(
            children: [
              Text(
                option['label']!,
                style: GoogleFonts.montserrat(color: Colors.white),
              ),
              if (_sortField == option['field']) const SizedBox(width: 8),
              if (_sortField == option['field'])
                const Icon(Icons.check, size: 18, color: Colors.white),
            ],
          ),
        );
      }).toList(),
    ).then((value) {
      if (value != null) {
        setState(() {
          _sortField = value;
        });
      }
    });
  }

  Future<void> _showFilterDialog() async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              backgroundColor: Colors.grey[900],
              title: Text(
                'Filter Offers',
                style: GoogleFonts.montserrat(color: Colors.white),
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView(
                  shrinkWrap: true,
                  children: _filterOptions.map((filter) {
                    return CheckboxListTile(
                      title: Text(
                        filter,
                        style: GoogleFonts.montserrat(color: Colors.white),
                      ),
                      value: _selectedFilters.contains(filter),
                      onChanged: (bool? value) {
                        setState(() {
                          if (value == true) {
                            _selectedFilters.add(filter);
                          } else {
                            _selectedFilters.remove(filter);
                          }
                        });
                      },
                      checkColor: Colors.black,
                      activeColor: Colors.white,
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.montserrat(color: Colors.white),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    this.setState(() {
                      // Update parent widget state
                      _filterStatus = _selectedFilters.isEmpty
                          ? 'All'
                          : _selectedFilters.first;
                    });
                    Navigator.pop(context);
                  },
                  child: Text(
                    'Apply',
                    style: GoogleFonts.montserrat(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
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

  List<Offer> _getFilteredAndSortedOffers(List<Offer> offers) {
    // First apply status filter
    var filteredOffers = offers.where((offer) {
      if (_filterStatus == 'All') return true;
      return offer.offerStatus.toLowerCase() == _filterStatus.toLowerCase();
    }).toList();

    // Then sort
    filteredOffers.sort((a, b) {
      if (_sortField == 'createdAt') {
        return _sortAscending
            ? (a.createdAt ?? DateTime(0)).compareTo(b.createdAt ?? DateTime(0))
            : (b.createdAt ?? DateTime(0))
                .compareTo(a.createdAt ?? DateTime(0));
      } else if (_sortField == 'offerAmount') {
        final aAmount = a.offerAmount ?? 0.0;
        final bAmount = b.offerAmount ?? 0.0;
        return _sortAscending
            ? aAmount.compareTo(bAmount)
            : bAmount.compareTo(aAmount);
      } else if (_sortField == 'offerStatus') {
        return _sortAscending
            ? a.offerStatus.compareTo(b.offerStatus)
            : b.offerStatus.compareTo(a.offerStatus);
      }
      return 0;
    });

    return filteredOffers;
  }

  Widget _buildOfferImage(Offer offer) {
    print('DEBUG: Building image for offer: ${offer.offerId}');
    print('DEBUG: Vehicle main image URL: ${offer.vehicleMainImage}');
    
    if (offer.isVehicleDetailsLoading) {
      return SizedBox(
        width: 50,
        height: 50,
        child: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF4E00)),
          ),
        ),
      );
    }
    
    if (offer.vehicleMainImage == null || offer.vehicleMainImage!.isEmpty) {
      print('DEBUG: No main image available for offer: ${offer.offerId}');
      return Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: Colors.grey[800],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(Icons.directions_car, color: Colors.blueAccent),
      );
    }
  
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        offer.vehicleMainImage!,
        width: 50,
        height: 50,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          print('DEBUG: Error loading image: $error');
          return Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.error_outline, color: Colors.red),
          );
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF4E00)),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search Bar and Controls Row
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              // Search Bar
              Expanded(
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: TextField(
                    controller: _searchController,
                    style: GoogleFonts.montserrat(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Search offers...',
                      hintStyle: GoogleFonts.montserrat(color: Colors.white54),
                      prefixIcon:
                          const Icon(Icons.search, color: Colors.white54),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    // Removed the immediate onChanged callback to rely solely on debounce
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Sort Button
              IconButton(
                icon: const Icon(Icons.sort, color: Colors.white),
                onPressed: () => _showSortMenu(),
                tooltip: 'Sort by: ${_sortField.replaceAll('_', ' ')}',
              ),
              // Sort Direction Button
              IconButton(
                icon: Icon(
                  _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                  color: Colors.white,
                ),
                onPressed: () {
                  setState(() {
                    _sortAscending = !_sortAscending;
                  });
                },
                tooltip: _sortAscending ? 'Sort Ascending' : 'Sort Descending',
              ),
              // Filter Button
              IconButton(
                icon: const Icon(Icons.filter_list, color: Colors.white),
                onPressed: () => _showFilterDialog(),
                tooltip: 'Filter Offers',
              ),
            ],
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

              // Apply filtering and sorting
              final filteredAndSortedOffers = _getFilteredAndSortedOffers(
                  offerProvider.offers
                      .where((offer) => _matchesSearch(offer))
                      .toList());

              if (filteredAndSortedOffers.isEmpty) {
                return Center(
                  child: Text(
                    'No offers match your search.',
                    style: GoogleFonts.montserrat(color: Colors.white),
                  ),
                );
              }

              return ListView.builder(
                controller: _scrollController,
                itemCount: filteredAndSortedOffers.length +
                    (offerProvider.hasMore ? 1 : 0), // Extra item for loading
                itemBuilder: (context, index) {
                  if (index == filteredAndSortedOffers.length) {
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

                  Offer offer = filteredAndSortedOffers[index];

                  // **Determine if the offer needs attention based solely on 'needsInvoice'**
                  bool needsAttention = offer.needsInvoice == true;

                  return Card(
                    color: needsAttention
                        ? Colors.red[800]
                        : Colors.grey[900], // Updated
                    margin:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    child: ListTile(
                      leading: Stack(
                        children: [
                          _buildOfferImage(offer),
                          if (needsAttention)
                            Positioned(
                              top: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: Colors.yellow,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.warning,
                                  size: 12,
                                  color: Colors.red[800],
                                ),
                              ),
                            ),
                        ],
                      ),
                      title: Text(
                        "${offer.vehicleMakeModel ?? 'No Title'}\nR ${offer.offerAmount?.toStringAsFixed(2) ?? 'N/A'}",
                        style: GoogleFonts.montserrat(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Status: ${offer.offerStatus}',
                            style:
                                GoogleFonts.montserrat(color: Colors.white70),
                          ),
                          if (needsAttention)
                            Text(
                              'Needs Invoice',
                              style: GoogleFonts.montserrat(
                                color: Colors.yellowAccent,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                        ],
                      ),
                      isThreeLine:
                          needsAttention, // Adjust based on whether needsInvoice is true
                      trailing:
                          Icon(Icons.arrow_forward_ios, color: Colors.white),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => OfferDetailPage(
                              offer: offer,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
