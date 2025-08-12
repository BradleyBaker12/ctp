import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DeepLinkTestOfferPage extends StatelessWidget {
  final String offerId;
  final String? vehicleId;
  final String notificationType;

  const DeepLinkTestOfferPage({
    super.key,
    required this.offerId,
    this.vehicleId,
    required this.notificationType,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Deep Link Test - Offer',
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFFFF4E00),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Success icon
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(50),
              ),
              child: const Icon(
                Icons.check_circle,
                size: 60,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 24),

            // Success message
            Text(
              '🎉 Deep Link Test Successful!',
              style: GoogleFonts.montserrat(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),

            Text(
              'Offer deep linking is working correctly',
              style: GoogleFonts.montserrat(
                fontSize: 16,
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Test data display
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  _buildDataRow('Notification Type:', notificationType),
                  const SizedBox(height: 12),
                  _buildDataRow('Offer ID:', offerId),
                  if (vehicleId != null) ...[
                    const SizedBox(height: 12),
                    _buildDataRow('Vehicle ID:', vehicleId!),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Notification type specific message
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _getNotificationColor().withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border:
                    Border.all(color: _getNotificationColor().withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    _getNotificationIcon(),
                    color: _getNotificationColor(),
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getNotificationTitle(),
                          style: GoogleFonts.montserrat(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _getNotificationColor(),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _getNotificationDescription(),
                          style: GoogleFonts.montserrat(
                            fontSize: 14,
                            color: _getNotificationColor().withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Test info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.amber[700],
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'This is a test page to verify offer deep linking works. In production, this would show the actual offer details or navigate to the offers page.',
                      style: GoogleFonts.montserrat(
                        fontSize: 14,
                        color: Colors.amber[800],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Navigation test buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.of(context).pushNamed('/offers'),
                    icon: const Icon(Icons.list_alt, color: Colors.white),
                    label: Text(
                      'Go to Offers',
                      style: GoogleFonts.montserrat(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.of(context)
                        .pushNamedAndRemoveUntil('/home', (route) => false),
                    icon: const Icon(Icons.home, color: Colors.white),
                    label: Text(
                      'Go Home',
                      style: GoogleFonts.montserrat(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF4E00),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.montserrat(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey[600],
          ),
        ),
        Flexible(
          child: Text(
            value,
            style: GoogleFonts.montserrat(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.blue[700],
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Color _getNotificationColor() {
    switch (notificationType) {
      case 'new_offer':
        return Colors.blue;
      case 'offer_response':
        return Colors.purple;
      case 'inspection_booked':
        return Colors.orange;
      case 'collection_booked':
        return Colors.teal;
      case 'sale_completion_dealer':
      case 'sale_completion_transporter':
        return Colors.green;
      case 'invoice_payment_reminder':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getNotificationIcon() {
    switch (notificationType) {
      case 'new_offer':
        return Icons.monetization_on;
      case 'offer_response':
        return Icons.reply;
      case 'inspection_booked':
        return Icons.search;
      case 'collection_booked':
        return Icons.local_shipping;
      case 'sale_completion_dealer':
      case 'sale_completion_transporter':
        return Icons.celebration;
      case 'invoice_payment_reminder':
        return Icons.payment;
      default:
        return Icons.notifications;
    }
  }

  String _getNotificationTitle() {
    switch (notificationType) {
      case 'new_offer':
        return 'New Offer Notification';
      case 'offer_response':
        return 'Offer Response Notification';
      case 'inspection_booked':
        return 'Inspection Booked Notification';
      case 'collection_booked':
        return 'Collection Booked Notification';
      case 'sale_completion_dealer':
        return 'Sale Completion (Dealer) Notification';
      case 'sale_completion_transporter':
        return 'Sale Completion (Transporter) Notification';
      case 'invoice_payment_reminder':
        return 'Payment Reminder Notification';
      default:
        return 'Unknown Notification Type';
    }
  }

  String _getNotificationDescription() {
    switch (notificationType) {
      case 'new_offer':
        return 'User received notification about a new offer on their vehicle';
      case 'offer_response':
        return 'User received notification about offer being accepted/rejected';
      case 'inspection_booked':
        return 'User received notification about scheduled inspection';
      case 'collection_booked':
        return 'User received notification about scheduled collection';
      case 'sale_completion_dealer':
        return 'Dealer received notification about completed sale';
      case 'sale_completion_transporter':
        return 'Transporter received notification about completed sale';
      case 'invoice_payment_reminder':
        return 'User received reminder about pending payment';
      default:
        return 'Notification type not recognized';
    }
  }
}
