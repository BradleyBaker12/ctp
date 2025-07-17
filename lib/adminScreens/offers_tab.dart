import 'dart:async';
import 'package:ctp/adminScreens/offer_details_page.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/offer_provider.dart';
import '../providers/user_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


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

  // Sorting
  String _sortField = 'createdAt';
  bool _sortAscending = false;

  // Filters: Added "Rejected" here
  final List<String> _filterOptions = [
    'All',
    'In-Progress',
    'Accepted',
    'Rejected',
  ];
  final List<String> _selectedFilters = [];

  // Track the filter that actually gets applied
  String _filterStatus = 'All';

  // Sort dropdown options
  final List<Map<String, String>> _sortOptions = [
    {'field': 'createdAt', 'label': 'Date'},
    {'field': 'offerAmount', 'label': 'Amount'},
    {'field': 'offerStatus', 'label': 'Status'}
  ];

  // Offers stream subscription
  StreamSubscription? _offerSubscription;

  // Tab state – "All", "In Progress", "Successful", or "Rejected"
  String _selectedTab = 'All';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final offerProvider = Provider.of<OfferProvider>(context, listen: false);
      offerProvider.initialize(widget.userId, widget.userRole);
      await offerProvider.refreshOffers();
    });

    // Listen to provider's offers stream
    _offerSubscription = Provider.of<OfferProvider>(context, listen: false)
        .offersStream
        .listen((offers) {
      if (mounted) setState(() {});
    });

    // Scroll listener for pagination
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 200 &&
          !Provider.of<OfferProvider>(context, listen: false).isFetching &&
          Provider.of<OfferProvider>(context, listen: false).hasMore) {
        Provider.of<OfferProvider>(context, listen: false).fetchMoreOffers();
      }
    });

    // Debounce for search
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
        // print('DEBUG: _searchQuery set to => $_searchQuery');
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
        Overlay.of(context).context.findRenderObject() as RenderBox;
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
          // print('DEBUG: _sortField changed to => $_sortField');
        });
      }
    });
  }

  Future<void> _showFilterDialog() async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.grey[900],
              title: Text('Filter Offers',
                  style: GoogleFonts.montserrat(color: Colors.white)),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView(
                  shrinkWrap: true,
                  children: _filterOptions.map((filter) {
                    return CheckboxListTile(
                      title: Text(filter,
                          style: GoogleFonts.montserrat(color: Colors.white)),
                      value: _selectedFilters.contains(filter),
                      onChanged: (bool? value) {
                        setDialogState(() {
                          if (value == true) {
                            _selectedFilters.add(filter);
                          } else {
                            _selectedFilters.remove(filter);
                          }
                          // print('DEBUG: _selectedFilters => $_selectedFilters');
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
                    setState(() {
                      _selectedFilters.clear();
                      _filterStatus = 'All';
                    });
                    // print('DEBUG: Filters cleared. _filterStatus = All');
                    Navigator.pop(context);
                  },
                  child: Text('Clear All',
                      style: GoogleFonts.montserrat(color: Colors.white)),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _filterStatus = _selectedFilters.isEmpty
                          ? 'All'
                          : _selectedFilters.first;
                    });
                    // print('DEBUG: _filterStatus set to => $_filterStatus');
                    Navigator.pop(context);
                  },
                  child: Text('Apply',
                      style: GoogleFonts.montserrat(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Matches the search query against offer fields.
  bool _matchesSearch(Offer offer) {
    if (_searchQuery.isEmpty) return true;

    final query = _searchQuery.toLowerCase();

    // Enhanced search across all relevant fields
    return (offer.vehicleMakeModel ?? '').toLowerCase().contains(query) ||
        (offer.dealerId).toLowerCase().contains(query) ||
        (offer.transporterId ?? '').toLowerCase().contains(query) ||
        (offer.offerStatus).toLowerCase().contains(query) ||
        (offer.offerAmount?.toString() ?? '').contains(query);
  }

  /// Filter offers by status, sort them, and return the final list.
  List<Offer> _getFilteredAndSortedOffers(List<Offer> offers) {
    // First apply status filter
    var filteredOffers = offers.where((offer) {
      if (_filterStatus == 'All') return true;

      final status = offer.offerStatus.toLowerCase();
      switch (_filterStatus.toLowerCase()) {
        case 'accepted':
          return status == 'accepted';
        case 'rejected':
          return status == 'rejected';
        case 'in-progress':
          return status != 'accepted' && status != 'rejected';
        default:
          return true;
      }
    }).toList();

    // Then apply search
    filteredOffers = filteredOffers.where(_matchesSearch).toList();

    // Finally sort
    filteredOffers.sort((a, b) {
      switch (_sortField) {
        case 'createdAt':
          return _sortAscending
              ? (a.createdAt ?? DateTime(0))
                  .compareTo(b.createdAt ?? DateTime(0))
              : (b.createdAt ?? DateTime(0))
                  .compareTo(a.createdAt ?? DateTime(0));
        case 'offerAmount':
          return _sortAscending
              ? (a.offerAmount ?? 0).compareTo(b.offerAmount ?? 0)
              : (b.offerAmount ?? 0).compareTo(a.offerAmount ?? 0);
        case 'offerStatus':
          return _sortAscending
              ? a.offerStatus.compareTo(b.offerStatus)
              : b.offerStatus.compareTo(a.offerStatus);
        default:
          return 0;
      }
    });

    return filteredOffers;
  }

  Widget _buildOfferImage(Offer offer) {
    if (offer.isVehicleDetailsLoading) {
      return const SizedBox(
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
      return Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: Colors.grey[800],
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.directions_car, color: Colors.blueAccent),
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
          return Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.error_outline, color: Colors.red),
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
                valueColor:
                    const AlwaysStoppedAnimation<Color>(Color(0xFFFF4E00)),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Filter offers for Sales Representative asynchronously.
  Future<List<Offer>> getFilteredOffersForSalesRep(
      List<Offer> allOffers, String salesRepId) async {
    // print('DEBUG: Filtering offers for sales rep: $salesRepId');

    try {
      // Get all users (dealers/transporters) managed by this sales rep
      QuerySnapshot managedAccounts = await FirebaseFirestore.instance
          .collection('users')
          .where('assignedSalesRep', isEqualTo: salesRepId)
          .get();

      // Get the IDs of all managed accounts
      List<String> managedAccountIds =
          managedAccounts.docs.map((doc) => doc.id).toList();

      // print('DEBUG: Found ${managedAccountIds.length} managed accounts');

      // Filter offers to only include those where either dealerId or transporterId
      // belongs to accounts managed by the sales rep
      List<Offer> filteredOffers = allOffers.where((offer) {
        bool isManaged = managedAccountIds.contains(offer.dealerId) ||
            managedAccountIds.contains(offer.transporterId);

        // print('DEBUG: Offer ${offer.offerId} - Dealer: ${offer.dealerId}, '
        // 'Transporter: ${offer.transporterId}, Is Managed: $isManaged');

        return isManaged;
      }).toList();

      // print(
      //     'DEBUG: Filtered ${allOffers.length} offers down to ${filteredOffers.length}');
      return filteredOffers;
    } catch (e) {
      print('ERROR: Failed to filter offers for sales rep: $e');
      return [];
    }
  }

  // Filtering logic (4 tabs):
  List<Offer> _filterOffersByTab(List<Offer> offers, String status) {
    final filtered = offers.where((offer) {
      final lowerStatus = offer.offerStatus.toLowerCase();
      return lowerStatus != 'sold';
    }).toList();
    switch (status.toUpperCase()) {
      case 'ALL':
        return filtered;
      case 'IN PROGRESS':
        return filtered.where((offer) {
          final lowerStatus = offer.offerStatus.toLowerCase();
          return lowerStatus != 'rejected' &&
              lowerStatus != 'successful' &&
              lowerStatus != 'completed' &&
              lowerStatus != 'sold' &&
              lowerStatus != 'done';
        }).toList();
      case 'SUCCESSFUL':
        return filtered.where((offer) {
          final lowerStatus = offer.offerStatus.toLowerCase();
          return lowerStatus == 'successful' ||
              lowerStatus == 'completed' ||
              lowerStatus == 'sold' ||
              lowerStatus == 'done';
        }).toList();
      case 'REJECTED':
        return filtered
            .where((offer) => offer.offerStatus.toLowerCase() == 'rejected')
            .toList();
      default:
        return [];
    }
  }

  int _getFilteredCount(List<Offer> offers, String status) {
    return _filterOffersByTab(offers, status).length;
  }

  Widget _buildTabButton(String title, String tab) {
    bool isSelected = _selectedTab == tab;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTab = tab;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        decoration: BoxDecoration(
          color: isSelected ? Color(0xFFFF4E00) : Colors.black,
          borderRadius: BorderRadius.circular(4.0),
          border: Border.all(
            color: isSelected ? Colors.black : Colors.blue,
            width: 1.0,
          ),
        ),
        child: Text(
          title.toUpperCase(),
          style: GoogleFonts.montserrat(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildStickyTabs(List<Offer> offers) {
    return Container(
      color: Colors.transparent,
      alignment: Alignment.center,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: [
              _buildTabButton(
                  'All (${_getFilteredCount(offers, "ALL")})', 'All'),
              const SizedBox(width: 12),
              _buildTabButton(
                  'In Progress (${_getFilteredCount(offers, "IN PROGRESS")})',
                  'In Progress'),
              const SizedBox(width: 12),
              _buildTabButton(
                  'Successful (${_getFilteredCount(offers, "SUCCESSFUL")})',
                  'Successful'),
              const SizedBox(width: 12),
              _buildTabButton(
                  'Rejected (${_getFilteredCount(offers, "REJECTED")})',
                  'Rejected'),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search and Controls Row.
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
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
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.sort, color: Colors.white),
                onPressed: _showSortMenu,
                tooltip: 'Sort by: ${_sortField.replaceAll('_', ' ')}',
              ),
              IconButton(
                icon: Icon(
                  _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                  color: Colors.white,
                ),
                onPressed: () {
                  setState(() {
                    _sortAscending = !_sortAscending;
                    // print('DEBUG: _sortAscending => $_sortAscending');
                  });
                },
                tooltip: _sortAscending ? 'Sort Ascending' : 'Sort Descending',
              ),
              IconButton(
                icon: const Icon(Icons.filter_list, color: Colors.white),
                onPressed: _showFilterDialog,
                tooltip: 'Filter Offers',
              ),
            ],
          ),
        ),
        // Tabs under search bar
        Consumer<OfferProvider>(
          builder: (context, offerProvider, child) {
            return _buildStickyTabs(offerProvider.offers);
          },
        ),
        // Expanded Offers List.
        Expanded(
          child: Consumer<OfferProvider>(
            builder: (context, offerProvider, child) {
              if (offerProvider.isFetching && offerProvider.offers.isEmpty) {
                return const Center(
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

              // Check if filtering for Sales Representative is needed.
              // If the user is a sales rep, we use FutureBuilder to wait for filtering.
              if (widget.userRole.toLowerCase() == 'sales representative') {
                return FutureBuilder<List<Offer>>(
                  future: getFilteredOffersForSalesRep(
                      offerProvider.offers, widget.userId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(
                          child:
                              Text('Error loading offers: ${snapshot.error}'));
                    }

                    final filteredOffers = snapshot.data ?? [];
                    // Continue with displaying the filtered offers...
                    // Apply search filter.
                    final searchedOffers =
                        filteredOffers.where(_matchesSearch).toList();
                    // Apply status filtering and sorting.
                    final filteredAndSortedOffers =
                        _getFilteredAndSortedOffers(searchedOffers);

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
                          (offerProvider.hasMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == filteredAndSortedOffers.length) {
                          if (offerProvider.isFetching) {
                            return const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Center(
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Color(0xFFFF4E00)),
                                ),
                              ),
                            );
                          } else {
                            return const SizedBox.shrink();
                          }
                        }
                        final offer = filteredAndSortedOffers[index];
                        // Countdown calculation (or "No Life span" if none)
                        final now = DateTime.now();
                        final expiration = offer
                            .expirationDate; // assumes expirationDate is a DateTime
                        String countdownText;
                        if (expiration != null) {
                          final diff = expiration.difference(now);
                          if (diff.isNegative) {
                            countdownText = 'Offer Expired';
                          } else {
                            final days = diff.inDays;
                            final hours = diff.inHours % 24;
                            final minutes = diff.inMinutes % 60;
                            if (days > 0) {
                              countdownText =
                                  '$days day${days > 1 ? 's' : ''} left';
                            } else if (hours > 0) {
                              countdownText =
                                  '$hours hour${hours > 1 ? 's' : ''} $minutes min left';
                            } else {
                              countdownText = '$minutes min left';
                            }
                          }
                        } else {
                          countdownText = 'No Life span';
                        }
                        final needsAttention = offer.needsInvoice == true;
                        return Card(
                          color: needsAttention
                              ? Colors.red[800]
                              : Colors.grey[900],
                          margin: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
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
                                      decoration: const BoxDecoration(
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
                            title: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (offer.vehicleRef != null) ...[
                                  Text(
                                    'Ref: ${offer.vehicleRef}',
                                    style: GoogleFonts.montserrat(
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFFF4E00),
                                      fontSize: 16,
                                    ),
                                  ),
                                  FutureBuilder<String?>(
                                    future: Provider.of<UserProvider>(context,
                                            listen: false)
                                        .getUserEmailById(offer.dealerId),
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState ==
                                          ConnectionState.waiting) {
                                        return Padding(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 4.0),
                                          child: SizedBox(
                                            height: 18,
                                            width: 18,
                                            child: Center(
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2.5,
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                            Color>(
                                                        Color(0xFFFF4E00)),
                                              ),
                                            ),
                                          ),
                                        );
                                      }
                                      final email = snapshot.data ?? '';
                                      return email.isNotEmpty
                                          ? Text(
                                              email,
                                              style: GoogleFonts.montserrat(
                                                color: Colors.white70,
                                                fontSize: 14,
                                              ),
                                            )
                                          : const SizedBox.shrink();
                                    },
                                  ),
                                ],
                                Text(
                                  "${offer.vehicleMakeModel ?? 'No Title'}\nR ${offer.offerAmount?.toStringAsFixed(2) ?? 'N/A'}",
                                  style: GoogleFonts.montserrat(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white),
                                ),
                              ],
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Status: ${offer.offerStatus}',
                                  style: GoogleFonts.montserrat(
                                      color: Colors.white70),
                                ),
                                if (needsAttention)
                                  Text(
                                    'Needs Invoice',
                                    style: GoogleFonts.montserrat(
                                      color: Colors.yellowAccent,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                if (countdownText.isNotEmpty)
                                  Text(
                                    countdownText,
                                    style: GoogleFonts.montserrat(
                                        color: Colors.white70),
                                  ),
                              ],
                            ),
                            isThreeLine: needsAttention,
                            trailing: const Icon(Icons.arrow_forward_ios,
                                color: Colors.white),
                            onTap: () {
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
                    );
                  },
                );
              } else {
                // For non-sales representatives, proceed synchronously.
                List<Offer> offersForDisplay = offerProvider.offers;
                // Apply tab filter
                final tabFilteredOffers =
                    _filterOffersByTab(offersForDisplay, _selectedTab);
                // Apply search filter.
                final searchedOffers =
                    tabFilteredOffers.where(_matchesSearch).toList();
                // Apply status filtering and sorting.
                final filteredAndSortedOffers =
                    _getFilteredAndSortedOffers(searchedOffers);

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
                      (offerProvider.hasMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == filteredAndSortedOffers.length) {
                      if (offerProvider.isFetching) {
                        return const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  Color(0xFFFF4E00)),
                            ),
                          ),
                        );
                      } else {
                        return const SizedBox.shrink();
                      }
                    }
                    final offer = filteredAndSortedOffers[index];
                    // Countdown calculation (or "No Life span" if none)
                    final now = DateTime.now();
                    final expiration = offer
                        .expirationDate; // assumes expirationDate is a DateTime
                    String countdownText;
                    if (expiration != null) {
                      final diff = expiration.difference(now);
                      if (diff.isNegative) {
                        countdownText = 'Offer Expired';
                      } else {
                        final days = diff.inDays;
                        final hours = diff.inHours % 24;
                        final minutes = diff.inMinutes % 60;
                        if (days > 0) {
                          countdownText =
                              '$days day${days > 1 ? 's' : ''} left';
                        } else if (hours > 0) {
                          countdownText =
                              '$hours hour${hours > 1 ? 's' : ''} $minutes min left';
                        } else {
                          countdownText = '$minutes min left';
                        }
                      }
                    } else {
                      countdownText = 'No Life span';
                    }
                    final needsAttention = offer.needsInvoice == true;
                    return Card(
                      color:
                          needsAttention ? Colors.red[800] : Colors.grey[900],
                      margin: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
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
                                  decoration: const BoxDecoration(
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
                        title: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              offer.vehicleMakeModel ?? 'No Title',
                              style: GoogleFonts.montserrat(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white),
                            ),
                            Text(
                              offer.offerAmount?.toStringAsFixed(2) ?? 'N/A',
                              style: GoogleFonts.montserrat(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white),
                            ),
                            if (offer.vehicleRef != null) ...[
                              Text(
                                'Ref: ${offer.vehicleRef}',
                                style: GoogleFonts.montserrat(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFFF4E00),
                                  fontSize: 16,
                                ),
                              ),
                              FutureBuilder<String?>(
                                future: Provider.of<UserProvider>(context,
                                        listen: false)
                                    .getUserEmailById(offer.dealerId),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 4.0),
                                      child: SizedBox(
                                        height: 18,
                                        width: 18,
                                        child: Center(
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                    Color(0xFFFF4E00)),
                                          ),
                                        ),
                                      ),
                                    );
                                  }
                                  final email = snapshot.data ?? '';
                                  return email.isNotEmpty
                                      ? Text(
                                          email,
                                          style: GoogleFonts.montserrat(
                                            color: Colors.white70,
                                            fontSize: 14,
                                          ),
                                        )
                                      : const SizedBox.shrink();
                                },
                              ),
                            ],
                          ],
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
                            if (countdownText.isNotEmpty)
                              Text(
                                countdownText,
                                style: GoogleFonts.montserrat(
                                    color: Colors.white70),
                              ),
                          ],
                        ),
                        isThreeLine: needsAttention,
                        trailing: const Icon(Icons.arrow_forward_ios,
                            color: Colors.white),
                        onTap: () {
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
                );
              }
            },
          ),
        ),
      ],
    );
  }
}
