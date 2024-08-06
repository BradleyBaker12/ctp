import 'package:flutter/material.dart';
import 'package:ctp/components/offer_card.dart';
import 'package:ctp/providers/offer_provider.dart';
import 'package:ctp/providers/user_provider.dart';
import 'package:provider/provider.dart';
import 'package:ctp/components/custom_back_button.dart';
import 'package:ctp/components/custom_bottom_navigation.dart';
import 'package:ctp/components/blurry_app_bar.dart';

class PendingOffersPage extends StatefulWidget {
  const PendingOffersPage({super.key});

  @override
  _PendingOffersPageState createState() => _PendingOffersPageState();
}

class _PendingOffersPageState extends State<PendingOffersPage> {
  String _selectedTab = 'View All';
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    // Fetch offers when the page loads using the correct dealerId from UserProvider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final dealerId = userProvider.userId;
      if (dealerId != null) {
        Provider.of<OfferProvider>(context, listen: false)
            .fetchOffers(dealerId)
            .then((_) {
          print('Offers fetched in initState');
        });
      } else {
        print('No dealerId found');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final offerProvider = Provider.of<OfferProvider>(context);

    List<Offer> getFilteredOffers() {
      print('Filtering offers with tab: $_selectedTab');
      if (_selectedTab == 'View All') {
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
      body: SafeArea(
        child: Column(
          children: [
            const BlurryAppBar(),
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Row(
                children: [
                  CustomBackButton(),
                  Spacer(),
                ],
              ),
            ),
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
                      _buildTab('View All'),
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
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      itemCount: filteredOffers.length,
                      itemBuilder: (context, index) {
                        Offer offer = filteredOffers[index];
                        print(
                            'Displaying offer: ${offer.offerId} with status ${offer.offerStatus}');
                        return OfferCard(
                          offer: offer,
                          size: size,
                          customFont: (double fontSize, FontWeight fontWeight,
                              Color color) {
                            return TextStyle(
                              fontSize: fontSize,
                              fontWeight: fontWeight,
                              color: color,
                              fontFamily: 'Montserrat',
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
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
              color: Colors.orange,
            ),
        ],
      ),
    );
  }
}
