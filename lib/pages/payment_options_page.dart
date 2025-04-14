// lib/adminScreens/payment_options_page.dart

import 'package:ctp/models/user_model.dart';
import 'package:ctp/pages/payment_approved.dart';
import 'package:ctp/pages/payment_pending_page.dart';
import 'package:ctp/pages/offer_summary_page.dart';
import 'package:ctp/components/custom_bottom_navigation.dart';
import 'package:ctp/components/custom_button.dart';
import 'package:ctp/components/gradient_background.dart';
import 'package:ctp/providers/offer_provider.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:ctp/providers/user_provider.dart';
import 'package:ctp/providers/vehicle_provider.dart';
import 'package:ctp/components/web_navigation_bar.dart';
import 'package:ctp/utils/navigation.dart';
import 'package:flutter/foundation.dart';
import 'package:mime/mime.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:universal_html/html.dart' as html;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:url_launcher/url_launcher.dart'; // Add this import for launchUrl
import 'dart:io';

class PaymentOptionsPage extends StatefulWidget {
  final String offerId;

  const PaymentOptionsPage({super.key, required this.offerId});

  @override
  _PaymentOptionsPageState createState() => _PaymentOptionsPageState();
}

class _PaymentOptionsPageState extends State<PaymentOptionsPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedIndex = 0; // For bottom navigation

  // Add getter for compact navigation
  bool _isCompactNavigation(BuildContext context) =>
      MediaQuery.of(context).size.width <= 1100;

  // Add getter for large screen
  bool get _isLargeScreen => MediaQuery.of(context).size.width > 900;

  @override
  void initState() {
    super.initState();
    _updateOfferStatus(); // Update the offer status when the page loads
  }

  /// Update the offer status to 'payment options' upon page load
  Future<void> _updateOfferStatus() async {
    try {
      await FirebaseFirestore.instance
          .collection('offers')
          .doc(widget.offerId)
          .update({'offerStatus': 'payment options'});

      print('Offer status updated to "payment options"');
    } catch (e) {
      print('Failed to update offer status: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update offer status: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Navigate based on payment status
  Future<void> _navigateBasedOnStatus(
      BuildContext context, String? paymentStatus) async {
    if (paymentStatus == 'approved') {
      await MyNavigator.push(
        context,
        PaymentApprovedPage(offerId: widget.offerId),
      );
    } else if (paymentStatus == 'pending') {
      await MyNavigator.push(
          context, PaymentPendingPage(offerId: widget.offerId));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unknown payment status: $paymentStatus'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Handle "Generate Invoice" button press
  Future<void> _handleGenerateInvoice(DocumentSnapshot offerSnapshot) async {
    print(
        'DEBUG: _handleGenerateInvoice called for offerId: ${widget.offerId}');
    final offerData = offerSnapshot.data() as Map<String, dynamic>;
    final String? externalInvoice = offerData['externalInvoice'];

    if (externalInvoice != null && externalInvoice.isNotEmpty) {
      // Invoice exists, allow user to view it - this should be a Firebase URL
      await downloadAndOpenFile(externalInvoice);
    } else {
      try {
        setState(() {
          // Show loading indicator or disable button
        });

        // Create invoice via Sage API, but the returned URL is the Firebase URL
        final String firebaseInvoiceUrl =
            await _createInvoiceFromSage(offerSnapshot);

        // Store the Firebase URL in the offer document
        await FirebaseFirestore.instance
            .collection('offers')
            .doc(widget.offerId)
            .update({
          'externalInvoice': firebaseInvoiceUrl, // Store Firebase URL
          'invoiceGenerated': true,
          'invoiceGeneratedAt': FieldValue.serverTimestamp(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Invoice generated successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // Open the Firebase invoice
        await downloadAndOpenFile(firebaseInvoiceUrl);
      } catch (e) {
        print('DEBUG: Exception in _handleGenerateInvoice: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Failed to generate invoice: ${e.toString().split(':').last}'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setState(() {
          // Hide loading indicator or re-enable button
        });
      }
    }
  }

  Future<String> _createInvoiceFromSage(DocumentSnapshot offerSnapshot) async {
    final offerData = offerSnapshot.data() as Map<String, dynamic>;
    final String vehicleId = offerData['vehicleId'];
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    // Get the OfferProvider to access consistent offer data
    final offerProvider = Provider.of<OfferProvider>(context, listen: false);

    // Get the correct offer object from OfferProvider or fetch it if not available
    Offer? currentOffer = offerProvider.getOfferById(widget.offerId);

    if (currentOffer == null) {
      // If the offer isn't in the provider's cache, fetch it directly
      await offerProvider.fetchOfferById(widget.offerId);
      currentOffer = offerProvider.getOfferById(widget.offerId);
    }

    // Get the offer amount, falling back to alternatives if needed
    double offerAmount = 0;
    if (currentOffer != null && currentOffer.offerAmount != null) {
      offerAmount = currentOffer.offerAmount!;
    } else {
      // Try different field names from the document as fallbacks
      offerAmount = (offerData['offerTotal'] ??
              offerData['offerAmount'] ??
              offerData['total'] ??
              0)
          .toDouble();
    }

    // Make sure we have a valid amount
    if (offerAmount <= 0) {
      print(
          'WARNING: Offer amount is zero or negative. Using document data as fallback.');
      // Try one more direct query as last resort
      try {
        final offerDoc = await FirebaseFirestore.instance
            .collection('offers')
            .doc(widget.offerId)
            .get();
        if (offerDoc.exists) {
          final data = offerDoc.data() as Map<String, dynamic>;
          offerAmount =
              (data['offerAmount'] ?? data['offerTotal'] ?? 0).toDouble();
        }
      } catch (e) {
        print('ERROR: Failed to fetch offer directly: $e');
      }
    }

    print('DEBUG: Final offer amount being used: $offerAmount');

    // Constants for API
    const String apiKey = 'D95FB388-B362-4348-B582-F12159170FCD';
    const String companyId = '15464';
    const String baseUrl =
        'https://resellers.accounting.sageone.co.za/api/2.0.0';
    const String username = 'cajunbeeby@gmail.com';
    const String password = 'SageAccounting@1';

    // Create basic auth header
    final String basicAuth =
        'Basic ${base64Encode(utf8.encode('$username:$password'))}';

    try {
      print('DEBUG: Starting Sage invoice creation process');

      // Make sure to fetch the latest user data
      await userProvider.fetchUserDetails();

      // STEP 1: Get customer details from the current signed in user
      final currentUser = userProvider.currentUser;

      // Ensure we have customer information
      if (currentUser == null) {
        throw Exception(
            'No user information available. Unable to create invoice.');
      }

      // Get company name from UserProvider
      String companyName = userProvider.getCompanyName ?? '';
      String tradingName = userProvider.getTradingName ?? '';
      String firstName = userProvider.getFirstName ?? '';
      String lastName = userProvider.getLastName ?? '';

      // Use a cascade of fallbacks to ensure we have a valid customer name
      String customerName = '';
      if (tradingName.isNotEmpty) {
        customerName = tradingName;
      } else if (companyName.isNotEmpty) {
        customerName = companyName;
      } else if (firstName.isNotEmpty || lastName.isNotEmpty) {
        customerName = '$firstName $lastName'.trim();
      }

      // Final fallback - if still empty, use user ID
      if (customerName.isEmpty && currentUser.uid.isNotEmpty) {
        customerName = 'Customer-${currentUser.uid.substring(0, 8)}';
      }

      // Safety check - if we still have no name, we can't proceed
      if (customerName.isEmpty) {
        throw Exception(
            'Unable to determine customer name for invoice creation.');
      }

      final String customerEmail =
          userProvider.getUserEmail ?? currentUser.email ?? '';

      // For contact name, use personal name or fall back to customer name
      String customerContact = '';
      if (firstName.isNotEmpty || lastName.isNotEmpty) {
        customerContact = '$firstName $lastName'.trim();
      }

      // If contact is still empty, use the customer name
      if (customerContact.isEmpty) {
        customerContact = customerName;
      }

      print('DEBUG: Checking for customer: $customerName');

      // Check if user already has a Sage UUID stored in Firestore
      String? sageCustomerId;
      if (currentUser.uid.isNotEmpty) {
        final userData = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .get();

        if (userData.exists && userData.data()!.containsKey('sageCustomerId')) {
          sageCustomerId = userData.data()!['sageCustomerId'];
          print(
              'DEBUG: Found existing Sage customer ID in Firestore: $sageCustomerId');
        }
      }

      // If no ID in Firestore, get or create in Sage
      int customerId;
      if (sageCustomerId == null) {
        customerId = await _getOrCreateSageCustomer(customerName, customerEmail,
            customerContact, basicAuth, apiKey, companyId);

        // Save the Sage customer ID to the user's document for future use
        if (currentUser.uid.isNotEmpty) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(currentUser.uid)
              .update({'sageCustomerId': customerId.toString()});

          print('DEBUG: Saved new Sage customer ID to Firestore: $customerId');
        }
      } else {
        // Convert the stored string ID to integer
        customerId = int.parse(sageCustomerId);
      }

      print('DEBUG: Using customer ID: $customerId');

      // STEP 2: Get vehicle details to include in the item description
      final vehicleData = await FirebaseFirestore.instance
          .collection('vehicles')
          .doc(vehicleId)
          .get();

      final make = vehicleData.data()?['makeModel'] ?? '';
      final model = vehicleData.data()?['variant'] ?? '';
      final year = vehicleData.data()?['year'] ?? '';
      final registrationNumber =
          vehicleData.data()?['registrationNumber'] ?? '';

      // Create a detailed item description including vehicle details
      final String vehicleDescription =
          '${make} ${model} ${year} (Reg: ${registrationNumber})';

      // Print debug information about the amounts
      print('DEBUG: Offer amount: $offerAmount');

      // Create description for the fixed fee (12500 before tax)
      final String feeDescription = 'CTP Service Fee';
      final double feeAmount = 12500.0; // Fixed fee amount BEFORE tax

      print('DEBUG: Fee amount before tax: $feeAmount');

      // Get item IDs (either existing or new) for both the vehicle and fee
      final int vehicleItemId = await _getOrCreateSageItem(
          vehicleDescription, offerAmount, basicAuth, apiKey, companyId);

      final int feeItemId = await _getOrCreateSageItem(
          feeDescription, feeAmount, basicAuth, apiKey, companyId);

      print('DEBUG: Retrieved vehicle item ID: $vehicleItemId');
      print('DEBUG: Retrieved fee item ID: $feeItemId');

      // STEP 3: Generate invoice with Sage API including both line items
      final invoicePdfUrl = await _generateSageInvoiceWithMultipleItems(
          customerId,
          [vehicleItemId, feeItemId],
          [vehicleDescription, feeDescription],
          [offerAmount, feeAmount],
          basicAuth,
          apiKey,
          companyId);

      // STEP 4: Download the PDF and upload to Firebase Storage
      final String firebaseUrl =
          await _downloadAndUploadToFirebase(invoicePdfUrl, vehicleId);

      return firebaseUrl;
    } catch (e) {
      print('DEBUG: Exception in Sage API integration: $e');
      throw Exception('Failed to create invoice: $e');
    }
  }

  // Helper method to get or create customer in Sage
  Future<int> _getOrCreateSageCustomer(
      String customerName,
      String customerEmail,
      String customerContact,
      String basicAuth,
      String apiKey,
      String companyId) async {
    // First try to get existing customers
    final Uri customerGetUrl = Uri.parse(
        'https://resellers.accounting.sageone.co.za/api/2.0.0/Customer/Get?apikey=$apiKey&companyId=$companyId');
    print('DEBUG: Fetching customers from Sage');
    final response = await http.get(
      customerGetUrl,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': basicAuth,
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      // Check if customer exists
      if (data['TotalResults'] > 0) {
        for (var customer in data['Results']) {
          if (customer['Name'] == customerName) {
            print('DEBUG: Found existing customer with ID: ${customer['ID']}');
            return customer['ID'];
          }
        }
      }
      // Customer doesn't exist, create a new one
      print('DEBUG: Customer not found, creating new one');
      return await _createSageCustomer(customerName, customerEmail,
          customerContact, basicAuth, apiKey, companyId);
    } else {
      print(
          'DEBUG: Failed to fetch customers: ${response.statusCode} ${response.body}');
      throw Exception('Failed to fetch customers');
    }
  }

  // Helper method to create a customer in Sage
  Future<int> _createSageCustomer(
      String customerName,
      String customerEmail,
      String customerContact,
      String basicAuth,
      String apiKey,
      String companyId) async {
    final Uri customerSaveUrl = Uri.parse(
        'https://resellers.accounting.sageone.co.za/api/2.0.0/Customer/Save?apikey=$apiKey&companyId=$companyId');

    // Determine communication method based on email availability
    final int communicationMethod =
        customerEmail.isNotEmpty ? 2 : 0; // Email(2) or None(0)

    // Ensure we have a valid email if using email communication
    final String email = customerEmail.isNotEmpty
        ? customerEmail
        : communicationMethod == 2
            ? 'noreply@ctpapp.co.za'
            : '';

    // Prepare customer data
    final Map<String, dynamic> customerData = {
      'Name': customerName,
      'Email': email,
      'ContactName': customerContact,
      'Active': true,
      'CommunicationMethod': communicationMethod,
      'TaxReference': '', // Optional
      'Telephone': '', // Optional
      'Mobile': '', // Optional
    };

    print(
        'DEBUG: Creating new customer with payload: ${jsonEncode(customerData)}');
    final response = await http.post(
      customerSaveUrl,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': basicAuth,
      },
      body: jsonEncode(customerData),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      print('DEBUG: Created customer with ID: ${data['ID']}');
      return data['ID'];
    } else {
      print(
          'DEBUG: Failed to create customer: ${response.statusCode} ${response.body}');
      throw Exception('Failed to create customer: ${response.body}');
    }
  }

  // Helper method to get or create item in Sage
  Future<int> _getOrCreateSageItem(String itemDescription, double itemPrice,
      String basicAuth, String apiKey, String companyId) async {
    // First try to get existing items
    final Uri itemGetUrl = Uri.parse(
        'https://resellers.accounting.sageone.co.za/api/2.0.0/Item/Get?apikey=$apiKey&companyId=$companyId');
    print('DEBUG: Fetching items from Sage');
    final response = await http.get(
      itemGetUrl,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': basicAuth,
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      // Check if item exists
      if (data['TotalResults'] > 0) {
        for (var item in data['Results']) {
          if (item['Description'].contains(widget.offerId)) {
            print('DEBUG: Found existing item with ID: ${item['ID']}');
            return item['ID'];
          }
        }
      }
      // Item doesn't exist, create a new one
      print('DEBUG: Item not found, creating new one');
      return await _createSageItem(
          itemDescription, itemPrice, basicAuth, apiKey, companyId);
    } else {
      print(
          'DEBUG: Failed to fetch items: ${response.statusCode} ${response.body}');
      throw Exception('Failed to fetch items');
    }
  }

  // Helper method to create an item in Sage
  Future<int> _createSageItem(String itemDescription, double itemPrice,
      String basicAuth, String apiKey, String companyId) async {
    final Uri itemSaveUrl = Uri.parse(
        'https://resellers.accounting.sageone.co.za/api/2.0.0/Item/Save?apikey=$apiKey&companyId=$companyId');

    // itemPrice is now the amount BEFORE tax
    final double exclusivePrice =
        itemPrice; // No division needed - already exclusive
    final double inclusivePrice =
        itemPrice * 1.15; // Calculate inclusive price by adding VAT

    // Prepare item data
    final Map<String, dynamic> itemData = {
      'Description': itemDescription,
      'Code':
          'CTP-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
      'Active': true,
      'Physical': false, // Service item
      'PriceInclusive': inclusivePrice, // Price WITH tax
      'PriceExclusive': exclusivePrice, // Price BEFORE tax
      'TaxTypeIdSales': 139728, // Standard VAT
    };

    print('DEBUG: Creating new item with payload: ${jsonEncode(itemData)}');
    final response = await http.post(
      itemSaveUrl,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': basicAuth,
      },
      body: jsonEncode(itemData),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      print('DEBUG: Created item with ID: ${data['ID']}');
      return data['ID'];
    } else {
      print(
          'DEBUG: Failed to create item: ${response.statusCode} ${response.body}');
      throw Exception('Failed to create item');
    }
  }

  // Helper method to generate an invoice in Sage
  Future<String> _generateSageInvoice(
      int customerId,
      int itemId,
      String itemDescription,
      double itemTotal,
      String basicAuth,
      String apiKey,
      String companyId) async {
    final Uri invoiceUrl = Uri.parse(
        'https://resellers.accounting.sageone.co.za/api/2.0.0/TaxInvoice/Save?apikey=$apiKey&companyId=$companyId&useSystemDocumentNumber=true');

    // Calculate dates
    final DateTime now = DateTime.now();
    final DateTime dueDate = now.add(const Duration(days: 7)); // Due in 7 days

    // Format dates as required by the API (yyyy-MM-dd)
    final String formattedDate =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    final String formattedDueDate =
        "${dueDate.year}-${dueDate.month.toString().padLeft(2, '0')}-${dueDate.day.toString().padLeft(2, '0')}";

    // Prepare invoice data with correct pricing
    final Map<String, dynamic> invoiceData = {
      'CustomerId': customerId,
      'Date': formattedDate,
      'DueDate': formattedDueDate,
      'Inclusive': true, // This means the prices include VAT
      'DiscountPercentage': 0,
      'Message': 'Invoice for offer ${widget.offerId}',
      'Lines': [
        {
          'SelectionId': itemId,
          'TaxTypeId': 139728, // As specified in requirements
          'LineType': 0,
          'Description': itemDescription,
          'Quantity': 1,
          'Unit': 'Unit',
          // Calculate exclusive price (before VAT)
          'UnitPriceExclusive': itemTotal / 1.15,
          // Total price including VAT
          'UnitPriceInclusive': itemTotal,
          'TaxPercentage': 15.0,
          'DiscountPercentage': 0,
          'Exclusive': itemTotal / 1.15, // Price excluding VAT
          'Tax': itemTotal - (itemTotal / 1.15), // VAT amount
          'Total': itemTotal, // Total price including VAT
          'Comments': 'Generated from CTP App',
        }
      ],
    };

    print('DEBUG: Creating invoice with payload: ${jsonEncode(invoiceData)}');
    final response = await http.post(
      invoiceUrl,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': basicAuth,
      },
      body: jsonEncode(invoiceData),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      print('DEBUG: Created invoice with ID: ${data['ID']}');
      // Use the correct URL format to get the PDF from Sage
      final String invoicePdfUrl =
          'https://resellers.accounting.sageone.co.za/api/2.0.0/TaxInvoice/Export/GET?apikey=$apiKey&companyId=$companyId&id=${data['ID']}';

      return invoicePdfUrl;
    } else {
      print(
          'DEBUG: Failed to create invoice: ${response.statusCode} ${response.body}');
      throw Exception('Failed to create invoice');
    }
  }

  // Modified method to generate an invoice with multiple items
  Future<String> _generateSageInvoiceWithMultipleItems(
      int customerId,
      List<int> itemIds,
      List<String> itemDescriptions,
      List<double> itemTotals,
      String basicAuth,
      String apiKey,
      String companyId) async {
    final Uri invoiceUrl = Uri.parse(
        'https://resellers.accounting.sageone.co.za/api/2.0.0/TaxInvoice/Save?apikey=$apiKey&companyId=$companyId&useSystemDocumentNumber=true');

    // Calculate dates
    final DateTime now = DateTime.now();
    final DateTime dueDate = now.add(const Duration(days: 7)); // Due in 7 days

    // Format dates as required by the API (yyyy-MM-dd)
    final String formattedDate =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    final String formattedDueDate =
        "${dueDate.year}-${dueDate.month.toString().padLeft(2, '0')}-${dueDate.day.toString().padLeft(2, '0')}";

    // Create multiple line items
    List<Map<String, dynamic>> invoiceLines = [];
    for (int i = 0; i < itemIds.length; i++) {
      // Important: Each total is treated as the amount BEFORE tax
      final double exclusivePrice =
          itemTotals[i]; // Keep as the price BEFORE tax
      final double taxAmount = exclusivePrice * 0.15; // Calculate 15% tax
      final double inclusivePrice =
          exclusivePrice + taxAmount; // Add tax to get the total with tax

      print(
          'DEBUG: Line ${i + 1}: Exclusive price (before tax): $exclusivePrice');
      print('DEBUG: Line ${i + 1}: Tax amount: $taxAmount');
      print(
          'DEBUG: Line ${i + 1}: Inclusive price (with tax): $inclusivePrice');

      invoiceLines.add({
        'SelectionId': itemIds[i],
        'TaxTypeId': 139728, // Standard VAT rate
        'LineType': 0,
        'Description': itemDescriptions[i],
        'Quantity': 1,
        'Unit': 'Unit',
        // Price BEFORE tax (exclusive)
        'UnitPriceExclusive': exclusivePrice,
        // Price WITH tax (inclusive)
        'UnitPriceInclusive': inclusivePrice,
        'TaxPercentage': 15.0,
        'DiscountPercentage': 0,
        'Exclusive': exclusivePrice, // Price before VAT
        'Tax': taxAmount, // VAT amount
        'Total': inclusivePrice, // Total price with VAT
        'Comments': 'Generated from CTP App',
      });
    }

    // Set the invoice to be exclusive (prices entered are before tax)
    final Map<String, dynamic> invoiceData = {
      'CustomerId': customerId,
      'Date': formattedDate,
      'DueDate': formattedDueDate,
      'Inclusive':
          false, // IMPORTANT: This tells Sage that prices are entered BEFORE tax
      'DiscountPercentage': 0,
      'Message': 'Invoice for offer ${widget.offerId}',
      'Lines': invoiceLines,
    };

    print('DEBUG: Creating invoice with payload: ${jsonEncode(invoiceData)}');
    final response = await http.post(
      invoiceUrl,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': basicAuth,
      },
      body: jsonEncode(invoiceData),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      print('DEBUG: Created invoice with ID: ${data['ID']}');
      // Use the correct URL format to get the PDF from Sage
      final String invoicePdfUrl =
          'https://resellers.accounting.sageone.co.za/api/2.0.0/TaxInvoice/Export/GET?apikey=$apiKey&companyId=$companyId&id=${data['ID']}';

      return invoicePdfUrl;
    } else {
      print(
          'DEBUG: Failed to create invoice: ${response.statusCode} ${response.body}');
      throw Exception('Failed to create invoice');
    }
  }

  // Helper method to download a PDF from Sage and upload it to Firebase Storage
  Future<String> _downloadAndUploadToFirebase(
      String sageUrl, String vehicleId) async {
    try {
      print('DEBUG: Downloading invoice PDF from Sage');

      // Parse the API key and company ID from the URL
      final Uri uri = Uri.parse(sageUrl);
      final String apiKey = uri.queryParameters['apikey'] ?? '';
      final String companyId = uri.queryParameters['companyId'] ?? '';
      final String invoiceId = uri.queryParameters['id'] ?? '';

      // Create basic auth header (same as used for other Sage API calls)
      const String username = 'cajunbeeby@gmail.com';
      const String password = 'SageAccounting@1';
      final String basicAuth =
          'Basic ${base64Encode(utf8.encode('$username:$password'))}';

      // Download the PDF with proper authentication
      final response = await http.get(
        Uri.parse(sageUrl),
        headers: {
          'Accept': 'application/pdf',
          'Authorization': basicAuth,
        },
      );

      if (response.statusCode != 200) {
        print('DEBUG: Failed to download PDF: ${response.statusCode}');

        // If we can't download the PDF directly, let's create a fallback text document
        // that includes the invoice information
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final fileName = 'invoice_${widget.offerId}_$timestamp.txt';

        final String invoiceContent = """
INVOICE REFERENCE
==============================
Invoice #: ${invoiceId}
Date: ${DateTime.now().toString()}
Offer ID: ${widget.offerId}
Vehicle ID: ${vehicleId}
==============================
This is a reference document for an invoice generated in Sage One.
To view the actual invoice, please log in to the Sage One portal.
""";

        // Upload the fallback text document to Firebase Storage
        final storage = FirebaseStorage.instance;
        final invoiceRef = storage.ref('invoices/$fileName');

        await invoiceRef.putString(invoiceContent);
        final String firebaseUrl = await invoiceRef.getDownloadURL();

        print('DEBUG: Created fallback invoice document at: $firebaseUrl');

        // Still store both URLs in Firestore for reference
        final invoiceDocRef =
            await FirebaseFirestore.instance.collection('invoices').add({
          'vehicleId': vehicleId,
          'offerId': widget.offerId,
          'sageInvoiceId': invoiceId,
          'sageInvoiceUrl': sageUrl,
          'firebaseInvoiceUrl': firebaseUrl,
          'createdAt': FieldValue.serverTimestamp(),
          'status': 'generated',
          'fileType': 'txt',
          'downloadError': 'HTTP ${response.statusCode}',
        });

        await invoiceDocRef.update({'invoiceId': invoiceDocRef.id});

        // Return the Firebase URL of the fallback document
        return firebaseUrl;
      }

      // Successfully downloaded the PDF - proceed with the original flow
      final bytes = response.bodyBytes;

      // Generate a unique filename for the PDF
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'invoice_${widget.offerId}_$timestamp.pdf';

      print('DEBUG: Uploading PDF to Firebase Storage');
      final storage = FirebaseStorage.instance;
      final invoiceRef = storage.ref('invoices/$fileName');

      await invoiceRef.putData(
        bytes,
        SettableMetadata(contentType: 'application/pdf'),
      );

      final String firebaseUrl = await invoiceRef.getDownloadURL();
      print('DEBUG: Created Firebase PDF invoice at: $firebaseUrl');

      // Create a record in Firestore
      final invoiceDocRef =
          await FirebaseFirestore.instance.collection('invoices').add({
        'vehicleId': vehicleId,
        'offerId': widget.offerId,
        'sageInvoiceId': invoiceId,
        'sageInvoiceUrl': sageUrl,
        'firebaseInvoiceUrl': firebaseUrl,
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'generated',
        'fileType': 'pdf',
      });

      await invoiceDocRef.update({'invoiceId': invoiceDocRef.id});

      return firebaseUrl;
    } catch (e) {
      print('DEBUG: Error in _downloadAndUploadToFirebase: $e');

      // Create a fallback document even in case of unexpected errors
      try {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final fileName = 'invoice_error_${widget.offerId}_$timestamp.txt';

        final String errorContent = """
INVOICE GENERATION ERROR
==============================
Offer ID: ${widget.offerId}
Vehicle ID: ${vehicleId}
Date: ${DateTime.now().toString()}
Error: ${e.toString()}
==============================
An error occurred while generating your invoice.
Please contact support for assistance.
""";

        final storage = FirebaseStorage.instance;
        final errorRef = storage.ref('invoices/errors/$fileName');

        await errorRef.putString(errorContent);
        final String errorUrl = await errorRef.getDownloadURL();

        // Log the error in Firestore
        await FirebaseFirestore.instance.collection('invoices').add({
          'vehicleId': vehicleId,
          'offerId': widget.offerId,
          'errorMessage': e.toString(),
          'errorUrl': errorUrl,
          'sageInvoiceUrl': sageUrl,
          'createdAt': FieldValue.serverTimestamp(),
          'status': 'error',
        });

        return errorUrl;
      } catch (fallbackError) {
        print(
            'DEBUG: Failed to create fallback error document: $fallbackError');
        throw Exception('Failed to process invoice: $e');
      }
    }
  }

  Future<void> downloadAndOpenFile(String url) async {
    print('DEBUG: Opening invoice: $url');
    try {
      // Check if this is a Firebase URL or a Sage URL
      bool isSageUrl = url.contains('sageone.co.za');

      if (isSageUrl) {
        // For Sage URLs, look up the corresponding Firebase URL
        final String invoiceId = url.split('id=').last;

        final QuerySnapshot invoiceQuery = await FirebaseFirestore.instance
            .collection('invoices')
            .where('sageInvoiceId', isEqualTo: invoiceId)
            .limit(1)
            .get();

        if (invoiceQuery.docs.isNotEmpty) {
          final invoiceData =
              invoiceQuery.docs.first.data() as Map<String, dynamic>;
          // Use the Firebase URL if available
          url = invoiceData['firebaseInvoiceUrl'] ?? url;
        }
      }

      // Now handle opening the file based on platform
      if (kIsWeb) {
        // Open file in the browser
        html.window.open(url, '_blank');
      } else {
        try {
          // For mobile, try to download and open the file
          final response = await http.get(Uri.parse(url));
          final bytes = response.bodyBytes;

          // Get MIME type
          String? mimeType = response.headers['content-type'] ?? 'text/plain';

          // Save to a temporary file
          final directory = await getApplicationDocumentsDirectory();
          final timestamp = DateTime.now().millisecondsSinceEpoch;
          final extension = mimeType.split('/').last;
          final filePath = '${directory.path}/invoice_$timestamp.$extension';

          final file = File(filePath);
          await file.writeAsBytes(bytes);

          // Open the file
          await OpenFile.open(filePath);
        } catch (e) {
          // If direct download fails, show a dialog
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('Invoice Available'),
              content: Text(
                  'Your invoice has been generated. Tap OK to view it online.'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    // Use launchUrl properly with the imported function
                    launchUrl(Uri.parse(url));
                  },
                  child: Text('OK'),
                ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      print("DEBUG: Error opening invoice: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error opening invoice: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final UserModel? currentUser = userProvider.currentUser;
    final userRole = userProvider.getUserRole;
    final bool showBottomNav = !_isLargeScreen && !kIsWeb;

    List<NavigationItem> navigationItems = userRole == 'dealer'
        ? [
            NavigationItem(title: 'Home', route: '/home'),
            NavigationItem(title: 'Search Trucks', route: '/truckPage'),
            NavigationItem(title: 'Wishlist', route: '/wishlist'),
            NavigationItem(title: 'Pending Offers', route: '/offers'),
          ]
        : [
            NavigationItem(title: 'Home', route: '/home'),
            NavigationItem(title: 'Your Trucks', route: '/transporterList'),
            NavigationItem(title: 'Your Offers', route: '/offers'),
            NavigationItem(title: 'In-Progress', route: '/in-progress'),
          ];

    return Scaffold(
      // This ensures the body extends behind the AppBar (if present)
      extendBodyBehindAppBar: true,
      key: _scaffoldKey,
      appBar: kIsWeb
          ? PreferredSize(
              preferredSize: const Size.fromHeight(70),
              child: WebNavigationBar(
                isCompactNavigation: _isCompactNavigation(context),
                currentRoute: '/offers',
                onMenuPressed: () => _scaffoldKey.currentState?.openDrawer(),
              ),
            )
          : null,
      drawer: _isCompactNavigation(context) && kIsWeb
          ? Drawer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: const [Colors.black, Color(0xFF2F7FFD)],
                  ),
                ),
                child: Column(
                  children: [
                    DrawerHeader(
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Colors.white24, width: 1),
                        ),
                      ),
                      child: Center(
                        child: Image.network(
                          'https://firebasestorage.googleapis.com/v0/b/ctp-central-database.appspot.com/o/CTPLOGOWeb.png?alt=media&token=d85ec0b5-f2ba-4772-aa08-e9ac6d4c2253',
                          height: 50,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 50,
                              width: 50,
                              color: Colors.grey[900],
                              child: const Icon(Icons.local_shipping,
                                  color: Colors.white),
                            );
                          },
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView(
                        children: navigationItems.map((item) {
                          bool isActive = '/offers' == item.route;
                          return ListTile(
                            title: Text(
                              item.title,
                              style: TextStyle(
                                color: isActive
                                    ? const Color(0xFFFF4E00)
                                    : Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            selected: isActive,
                            selectedTileColor: Colors.black12,
                            onTap: () {
                              Navigator.pop(context);
                              if (!isActive) {
                                Navigator.pushNamed(context, item.route);
                              }
                            },
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,
      // Wrap the GradientBackground in a SizedBox.expand to fill the available space.
      body: SizedBox.expand(
        child: GradientBackground(
          child: StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('offers')
                .doc(widget.offerId)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Error fetching offer details',
                    style: GoogleFonts.montserrat(color: Colors.red),
                  ),
                );
              }

              if (!snapshot.hasData || !snapshot.data!.exists) {
                return Center(
                  child: Text(
                    'Offer not found',
                    style: GoogleFonts.montserrat(color: Colors.red),
                  ),
                );
              }

              final offerData = snapshot.data!.data() as Map<String, dynamic>;

              final String offerStatus = offerData['offerStatus'] ?? '';
              final String? externalInvoice = offerData['externalInvoice'];
              final String? paymentStatus = offerData['paymentStatus'];
              final bool needsInvoice = offerData['needsInvoice'] ?? false;

              // Determine button state and text
              String invoiceButtonText =
                  externalInvoice != null && externalInvoice.isNotEmpty
                      ? 'VIEW INVOICE'
                      : needsInvoice
                          ? 'INVOICE REQUESTED'
                          : 'REQUEST INVOICE';
              // Determine button state and text
              bool isInvoiceButtonEnabled =
                  (externalInvoice != null && externalInvoice.isNotEmpty) ||
                      !needsInvoice;
              // **Determine if "Continue" button should be enabled based on Firestore data**
              bool isContinueEnabled =
                  externalInvoice != null && externalInvoice.isNotEmpty;

              return SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                      16.0, kIsWeb ? 100 : 16.0, 16.0, 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Align(
                        alignment: Alignment.topLeft,
                        child: IconButton(
                          icon:
                              const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Image.asset('lib/assets/CTPLogo.png'),
                      const SizedBox(height: 64),
                      Text(
                        'PAYMENT OPTIONS',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        "You're almost there!",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      const SizedBox(
                        width: 350,
                        child: Text(
                          'Full payment needs to reflect before arranging collection. If payment is not made within 3 days, the transaction will be cancelled and other dealers will be able to offer again.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 32), // Spacing before buttons

                      /// **Step 1 & Step 2 Buttons**
                      CustomButton(
                        text: invoiceButtonText,
                        borderColor: const Color(0xFFFF4E00),
                        onPressed: isInvoiceButtonEnabled
                            ? () => _handleGenerateInvoice(snapshot.data!)
                            : null,
                        disabledColor: Colors.grey,
                      ),

                      if (needsInvoice &&
                          (externalInvoice == null || externalInvoice.isEmpty))
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Text(
                            'Invoice has been requested. Please wait for admin to generate it.',
                            style: TextStyle(
                              color: Colors.orange,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),

                      // CustomButton(
                      //   text: 'PAY ONLINE NOW',
                      //   borderColor: const Color(0xFFFF4E00),
                      //   onPressed: () {
                      //     // Implement online payment functionality here
                      //     // For example, navigate to a payment gateway page
                      //   },
                      // ),
                      // const SizedBox(height: 16),

                      CustomButton(
                        text: 'SEND OFFER SUMMARY',
                        borderColor: const Color(0xFFFF4E00),
                        onPressed: () async {
                          await MyNavigator.push(
                            context,
                            OfferSummaryPage(offerId: widget.offerId),
                          );
                        },
                      ),
                      const SizedBox(height: 16),

                      /// **"Continue" Button**
                      CustomButton(
                        text: 'CONTINUE',
                        borderColor: const Color(0xFFFF4E00),
                        onPressed: isContinueEnabled
                            ? () {
                                _navigateBasedOnStatus(context, paymentStatus);
                              }
                            : null, // Disable if invoice not uploaded
                        // Optionally, adjust appearance when disabled
                        disabledColor: Colors.grey,
                      ),
                      const SizedBox(height: 16), // Bottom padding
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
      bottomNavigationBar: showBottomNav
          ? CustomBottomNavigation(
              selectedIndex: _selectedIndex,
              onItemTapped: _onItemTapped,
            )
          : null,
    );
  }
}
