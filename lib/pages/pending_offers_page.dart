import 'package:flutter/material.dart';
import 'package:ctp/providers/offer_provider.dart';
import 'package:ctp/providers/user_provider.dart';
import 'package:provider/provider.dart';
import 'package:ctp/components/custom_bottom_navigation.dart';
import 'package:ctp/components/blurry_app_bar.dart';
import 'package:ctp/components/gradient_background.dart'; // Import the GradientBackground widget

import 'package:auto_route/auto_route.dart';

@RoutePage()
class PendingOffersPage extends StatefulWidget {
  const PendingOffersPage({super.key});

  @override
  _PendingOffersPageState createState() => _PendingOffersPageState();
}

class _PendingOffersPageState extends State<PendingOffersPage> {
  String _selectedTab = 'All';
  int _selectedIndex = 2; // Set the heart icon as the initial selected index

  @override
  void initState() {
    super.initState();
    // Fetch offers when the page loads using the correct userId from UserProvider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final userId = userProvider.userId;
      final userRole = userProvider.getUserRole;

      if (userId != null) {
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        Provider.of<OfferProvider>(context, listen: false)
            .fetchOffers(userId, userRole,
                isTradeInManager: userProvider.isTradeInManager,
                tradeInBrand: userProvider.tradeInBrand)
            .then((_) {
          print('Offers fetched in initState');
        });
      } else {
        print('No userId found');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final userProv = Provider.of<UserProvider>(context);
    final role = userProv.getUserRole.toLowerCase();
    final bool isOemOrTradeInEmployee =
        (role == 'oem' && !userProv.isOemManager) ||
            ((role == 'tradein' || role == 'trade-in') &&
                !userProv.isTradeInManager);
    if (isOemOrTradeInEmployee) {
      // Show simple blocked view
      return Scaffold(
        body: GradientBackground(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.lock_outline,
                      color: Colors.white70, size: 64),
                  const SizedBox(height: 16),
                  const Text(
                    'Restricted: Employee accounts cannot view offers.',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () =>
                        Navigator.of(context).pushReplacementNamed('/home'),
                    child: const Text('Return Home'),
                  )
                ],
              ),
            ),
          ),
        ),
      );
    }
    final size = MediaQuery.of(context).size;
    final offerProvider = Provider.of<OfferProvider>(context, listen: false);

    List<Offer> getFilteredOffers() {
      print('Filtering offers with tab: $_selectedTab');
      if (_selectedTab == 'All') {
        return offerProvider.offers;
      } else if (_selectedTab == 'Accepted') {
        return offerProvider.offers
            .where((offer) => offer.offerStatus == 'accepted')
            .toList();
      } else if (_selectedTab == 'Rejected') {
        return offerProvider.offers
            .where((offer) => offer.offerStatus == 'rejected')
            .toList();
      } else if (_selectedTab == 'In-Progress') {
        return offerProvider.offers
            .where((offer) => offer.offerStatus == 'in-progress')
            .toList();
      } else {
        return [];
      }
    }

    final filteredOffers = getFilteredOffers();
    print('Total offers: ${offerProvider.offers.length}');
    print('Filtered offers: ${filteredOffers.length}');

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.black,
      body: GradientBackground(
        // Apply the gradient background
        child: SafeArea(
          child: Column(
            children: [
              const BlurryAppBar(leading: SizedBox.shrink()),
              // Back button removed as per design request
              Padding(
                padding: EdgeInsets.all(size.width * 0.05),
                child: Image.asset('lib/assets/CTPLogo.png'),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      'PENDING OFFERS MADE',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildTab('All'),
                        const SizedBox(width: 8),
                        _buildTab('Accepted'),
                        const SizedBox(width: 8),
                        _buildTab('Rejected'),
                        const SizedBox(width: 8),
                        _buildTab('In-Progress'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Offer cards
              Expanded(
                child: offerProvider.offers.isEmpty
                    ? Center(
                        child: Image.asset(
                          'lib/assets/Loading_Logo_CTP.gif',
                          width: 100, // Adjust size as needed
                          height: 100,
                        ),
                      )
                    : ListView.builder(
                        itemCount: filteredOffers.length,
                        itemBuilder: (context, index) {
                          Offer offer = filteredOffers[index];
                          print(
                              'Displaying offer: ${offer.offerId} with status ${offer.offerStatus}');
                          return;
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: CustomBottomNavigation(
        selectedIndex: _selectedIndex,
        onItemTapped: (index) {
          setState(() {
            _selectedIndex = index;
            print('Selected tab index: $_selectedIndex');
          });
        },
      ),
    );
  }

  Widget _buildTab(String tabName) {
    final isSelected = _selectedTab == tabName;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTab = tabName;
          print('Selected tab: $_selectedTab');
        });
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            tabName.toUpperCase(),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.blue : Colors.white,
            ),
          ),
          if (isSelected)
            Container(
              margin: const EdgeInsets.only(top: 4),
              height: 2,
              width: 40,
              color: const Color(0xFFFF4E00),
            ),
        ],
      ),
    );
  }
}
