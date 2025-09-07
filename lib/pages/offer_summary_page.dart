import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Import rootBundle
import 'package:ctp/components/gradient_background.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:ctp/providers/user_provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:universal_html/html.dart' as html;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import 'package:auto_route/auto_route.dart';

@RoutePage()
class OfferSummaryPage extends StatefulWidget {
  final String offerId;
  final String? viewerRoleOverride; // 'dealer' or 'transporter' (admin use)

  const OfferSummaryPage({
    super.key,
    required this.offerId,
    this.viewerRoleOverride,
  });

  @override
  State<OfferSummaryPage> createState() => _OfferSummaryPageState();
}

class _OfferSummaryPageState extends State<OfferSummaryPage> {
  String? _overrideRole; // runtime toggle for admin

  String _formatRand(num amount) {
    final formatted = NumberFormat.currency(
      locale: 'en_ZA',
      symbol: 'R',
      decimalDigits: 0,
    ).format(amount);
    final withSpaces = formatted.replaceAll(',', ' ');
    return withSpaces.replaceFirst(RegExp(r'^R\s*'), 'R ');
  }

  Future<File?> _generatePdf(
    BuildContext context,
    Map<String, dynamic> offerData,
    Map<String, dynamic> dealerData,
    Map<String, dynamic> vehicleData,
    Map<String, dynamic> transporterData,
    String viewerRole,
  ) async {
    final pdf = pw.Document();

    final robotoRegular = pw.Font.ttf(
        await rootBundle.load('lib/assets/fonts/Roboto-Regular.ttf'));
    final robotoBold =
        pw.Font.ttf(await rootBundle.load('lib/assets/fonts/Roboto-Bold.ttf'));

    final logoImage = pw.MemoryImage(
      (await rootBundle.load('lib/assets/CTPLogo.png')).buffer.asUint8List(),
    );

    final backgroundImage = pw.MemoryImage(
      (await rootBundle.load('lib/assets/Offer_SummaryImage.png'))
          .buffer
          .asUint8List(),
    );

    final vehicleImage = vehicleData['mainImageUrl'] != null
        ? await _networkImage(vehicleData['mainImageUrl'])
        : null;

    // Determine role and calculate breakdowns
    final role = viewerRole.toLowerCase().trim();
    final baseAmount =
        (offerData['typedOfferAmount'] as num?)?.toDouble() ?? 0.0;
    const double commissionAmount = 12500.0;
    // Dealer view: VAT on (base + commission), total = base + commission + VAT
    final dealerSubtotal = baseAmount + commissionAmount;
    final dealerVatAmount = dealerSubtotal * 0.15;
    final dealerTotalAmount = dealerSubtotal + dealerVatAmount;
    // Transporter view: payout after commission, VAT on the remainder
    final amountAfterCommission = baseAmount - commissionAmount;
    final transporterVat = amountAfterCommission * 0.15;
    final transporterPayout = amountAfterCommission + transporterVat;

    pdf.addPage(
      pw.Page(
        margin: const pw.EdgeInsets.all(20), // Adding margin to the page
        build: (pw.Context context) => pw.Stack(
          children: [
            pw.Positioned.fill(
              child: pw.Image(
                backgroundImage,
                fit: pw.BoxFit.cover,
              ),
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.only(left: 20, top: 10),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.start,
                    children: [
                      pw.Image(logoImage, height: 100),
                      pw.SizedBox(width: 20),
                      pw.Text('OFFER SUMMARY',
                          style: pw.TextStyle(
                              font: robotoBold,
                              fontSize: 34,
                              color: PdfColors.white)),
                    ],
                  ),
                ),
                pw.Padding(
                  padding:
                      const pw.EdgeInsets.only(left: 40, right: 20, top: 5),
                  child: pw.Divider(
                    color: PdfColors.white,
                    thickness: 2,
                  ),
                ),
                pw.SizedBox(height: 16),
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Expanded(
                      child: pw.Padding(
                        padding: const pw.EdgeInsets.only(left: 40),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text('BANKING DETAILS',
                                style: pw.TextStyle(
                                    font: robotoBold,
                                    fontSize: 16,
                                    color: PdfColors.white)),
                            pw.Text(
                                'Acc Name: Commercial Trader Portal (PTY) LTD\n'
                                'Bank: First Nation Bank\n'
                                'Branch Code: 210835\n'
                                'Acc Type: Cheque\n'
                                'Acc No: 63046523030',
                                style: pw.TextStyle(
                                    font: robotoRegular,
                                    color: PdfColors.white)),
                          ],
                        ),
                      ),
                    ),
                    pw.SizedBox(width: 40),
                    pw.Expanded(
                      child: pw.Padding(
                        padding: const pw.EdgeInsets.only(right: 40),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text('INVOICING DETAILS',
                                style: pw.TextStyle(
                                    font: robotoBold,
                                    fontSize: 16,
                                    color: PdfColors.white)),
                            pw.Text(
                                'Company Name: Commercial Trader Portal\n'
                                'Email Address: admin@ctpapp.co.za\n'
                                'VAT Number: 4780304798\n'
                                'Registration Number: 2023/642131/07\n'
                                'Address: 54 Rooibos Road, Highbury, Randvaal, 1962',
                                style: pw.TextStyle(
                                    font: robotoRegular,
                                    color: PdfColors.white)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 16),
                pw.Padding(
                  padding: const pw.EdgeInsets.only(left: 40),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('TRUCK SUMMARY',
                          style: pw.TextStyle(
                              font: robotoBold,
                              fontSize: 16,
                              color: PdfColors.white)),
                      pw.Divider(
                        color: PdfColors.white,
                        thickness: 2,
                      ),
                      pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          if (vehicleImage != null)
                            pw.Image(vehicleImage, height: 150),
                          pw.SizedBox(width: 20),
                          pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(
                                  '${vehicleData['makeModel'] ?? 'unknown'}',
                                  style: pw.TextStyle(
                                      font: robotoBold,
                                      fontSize: 16,
                                      color: PdfColors.white)),
                              pw.Text('${vehicleData['location'] ?? 'unknown'}',
                                  style: pw.TextStyle(
                                      font: robotoRegular,
                                      fontSize: 14,
                                      color: PdfColors.white)),
                              pw.SizedBox(height: 10),
                              pw.Row(
                                children: [
                                  pw.Text('Year: ',
                                      style: pw.TextStyle(
                                          font: robotoBold,
                                          fontSize: 12,
                                          color: PdfColors.white)),
                                  pw.Text('${vehicleData['year'] ?? 'unknown'}',
                                      style: pw.TextStyle(
                                          font: robotoRegular,
                                          fontSize: 12,
                                          color: PdfColors.white)),
                                ],
                              ),
                              pw.SizedBox(height: 10),
                              pw.Row(
                                children: [
                                  pw.Text('Mileage: ',
                                      style: pw.TextStyle(
                                          font: robotoBold,
                                          fontSize: 12,
                                          color: PdfColors.white)),
                                  pw.Text(
                                      '${vehicleData['mileage'] ?? 'unknown'}',
                                      style: pw.TextStyle(
                                          font: robotoRegular,
                                          fontSize: 12,
                                          color: PdfColors.white)),
                                ],
                              ),
                              pw.SizedBox(height: 10),
                              // pw.Row(
                              //   children: [
                              //     pw.Text('Transmission: ',
                              //         style: pw.TextStyle(
                              //             font: robotoBold,
                              //             fontSize: 12,
                              //             color: PdfColors.white)),
                              //     pw.Text(
                              //         '${vehicleData['transmission'] ?? 'unknown'}',
                              //         style: pw.TextStyle(
                              //             font: robotoRegular,
                              //             fontSize: 12,
                              //             color: PdfColors.white)),
                              //   ],
                              // ),
                              // pw.SizedBox(height: 10),
                              pw.Row(
                                children: [
                                  pw.Text('Config: ',
                                      style: pw.TextStyle(
                                          font: robotoBold,
                                          fontSize: 12,
                                          color: PdfColors.white)),
                                  pw.Text(
                                      '${vehicleData['config'] ?? 'unknown'}',
                                      style: pw.TextStyle(
                                          font: robotoRegular,
                                          fontSize: 12,
                                          color: PdfColors.white)),
                                ],
                              ),
                              pw.SizedBox(height: 10),
                              pw.Row(
                                children: [
                                  pw.Text('Reference Number: ',
                                      style: pw.TextStyle(
                                          font: robotoBold,
                                          fontSize: 12,
                                          color: PdfColors.white)),
                                  pw.Text(
                                      '${vehicleData['referenceNumber'] ?? 'unknown'}',
                                      style: pw.TextStyle(
                                          font: robotoRegular,
                                          fontSize: 12,
                                          color: PdfColors.white)),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 20),
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Expanded(
                      child: pw.Padding(
                        padding: const pw.EdgeInsets.only(left: 40),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text('Offer Details',
                                style: pw.TextStyle(
                                    font: robotoBold,
                                    fontSize: 16,
                                    color: PdfColors.white)),
                            if (role == 'dealer')
                              pw.Text(
                                  'Typed offer: ${_formatRand(baseAmount)}\n'
                                  'Commission: ${_formatRand(commissionAmount)}\n'
                                  'Subtotal after commission: ${_formatRand(dealerSubtotal)}\n'
                                  'VAT 15%: ${_formatRand(dealerVatAmount)}\n'
                                  'Your payout: ${_formatRand(dealerTotalAmount)}',
                                  style: pw.TextStyle(
                                      font: robotoRegular,
                                      color: PdfColors.white))
                            else
                              pw.Text(
                                  'Typed offer: ${_formatRand(baseAmount)}\n'
                                  'Commission: ${_formatRand(commissionAmount)}\n'
                                  'Subtotal after commission: ${_formatRand(amountAfterCommission)}\n'
                                  'VAT 15%: ${_formatRand(transporterVat)}\n'
                                  'Payout: ${_formatRand(transporterPayout)}',
                                  style: pw.TextStyle(
                                      font: robotoRegular,
                                      color: PdfColors.white)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 50),
                pw.Padding(
                  padding: const pw.EdgeInsets.only(left: 40, right: 40),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Center(),
                      pw.Text('Terms and Conditions',
                          style: pw.TextStyle(
                              font: robotoBold, color: PdfColors.white),
                          textAlign: pw.TextAlign.center),
                      pw.Text(
                        'Welcome to the CTP App. By accessing or using our app, you agree to be bound by the following terms and conditions. Please read them carefully.\n1. Use of the App The CTP App is provided for your personal and non-commercial use to assist in the trading of trucks and trailers. Any unauthorized use of the app is strictly prohibited.\n2. Registration Users must register to access certain features. You agree to provide accurate information and update it as necessary. Your account is for your personal use only and should not be shared.\n3. Privacy Your privacy is important to us. Please review our Privacy Policy to understand our practices.\n4. Intellectual Property All content in the app, including text, graphics, logos, and software, is the property of CTP or its content suppliers and protected by intellectual property laws.\n5. Transactions CTP is not a party to transactions between buyers and sellers. We do not guarantee the quality, safety, or legality of the items listed.\n6. Limitation of Liability CTP will not be liable for any damages arising from your use of the app or any transactions facilitated by it.\n7. Changes to Terms We reserve the right to modify these terms at any time. Your continued use of the app constitutes agreement to any changes.\n8. Governing Law These terms are governed by the laws of [Jurisdiction] without regard to its conflict of law provisions.\nContact Us For any questions or concerns about these terms, please contact us at [Contact Information].',
                        style: pw.TextStyle(
                          font: robotoRegular,
                          color: PdfColors.white,
                          fontSize: 8,
                        ),
                        textAlign: pw.TextAlign.center, // Centering the text
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 30),
              ],
            ),
          ],
        ),
      ),
    );
    final pdfBytes = await pdf.save();
    if (kIsWeb) {
      var dt = DateTime.now().millisecondsSinceEpoch.toString();
      final blob = html.Blob([pdfBytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: url)
        ..setAttribute("download", "offer_summary_$dt.pdf")
        ..click();
      html.Url.revokeObjectUrl(url);
    } else {
      final output = await getTemporaryDirectory();
      final file = File("${output.path}/offer_summary.pdf");
      await file.writeAsBytes(await pdf.save());
      return file;
    }
    return null;
  }

  // final output = await getTemporaryDirectory();
  // final file = File("${output.path}/offer_summary.pdf");
  // await file.writeAsBytes(await pdf.save());
  // return file;
  Future<String> getTemporaryDirectoryPath() async {
    if (kIsWeb) {
      // Use window.localStorage or another web-specific solution
      // For demonstration purposes, we'll just return a dummy path
      return '/tmp/web-temp-dir';
    } else {
      final tempDir = await getTemporaryDirectory();
      return tempDir.path;
    }
  }

  Future<pw.ImageProvider> _networkImage(String url) async {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      return pw.MemoryImage(response.bodyBytes);
    } else {
      throw Exception('Failed to load image');
    }
  }

  Future<Map<String, dynamic>> _fetchDocumentData(
      String collection, String docId) async {
    final docSnapshot = await FirebaseFirestore.instance
        .collection(collection)
        .doc(docId)
        .get();
    return docSnapshot.exists ? docSnapshot.data() ?? {} : {};
  }

  @override
  void initState() {
    super.initState();
    _overrideRole = widget.viewerRoleOverride;
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    return FutureBuilder(
      future: Future.wait([
        _fetchDocumentData('offers', widget.offerId),
        userProvider.fetchUserData().then((_) => userProvider.getUserData()),
      ]),
      builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.hasData) {
          final offerData = snapshot.data![0] as Map<String, dynamic>;
          final userData = snapshot.data![1] as Map<String, dynamic>;

          // Debug logs removed for production

          return FutureBuilder(
            future: Future.wait([
              _fetchDocumentData('vehicles', offerData['vehicleId']),
              _fetchDocumentData('users', offerData['transporterId']),
            ]),
            builder: (context, AsyncSnapshot<List<dynamic>> innerSnapshot) {
              if (innerSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (innerSnapshot.hasError) {
                return Center(child: Text('Error: ${innerSnapshot.error}'));
              }

              if (innerSnapshot.hasData) {
                final vehicleData =
                    innerSnapshot.data![0] as Map<String, dynamic>;
                final transporterData =
                    innerSnapshot.data![1] as Map<String, dynamic>;

                // Debug logs removed for production

                // Resolve viewer role more robustly: prefer matching offer party IDs, then fall back to userRole
                final currentUid = FirebaseAuth.instance.currentUser?.uid;
                String viewerRole =
                    (userData['userRole']?.toString().toLowerCase().trim()) ??
                        '';
                if (currentUid != null) {
                  if (offerData['dealerId'] == currentUid) {
                    viewerRole = 'dealer';
                  } else if (offerData['transporterId'] == currentUid) {
                    viewerRole = 'transporter';
                  }
                }

                // Admin default: dealer view, unless override chosen
                final userRoleLower =
                    (userData['userRole']?.toString().toLowerCase().trim()) ??
                        '';
                if (userRoleLower == 'admin' && _overrideRole == null) {
                  viewerRole = 'dealer';
                }
                if (_overrideRole != null) viewerRole = _overrideRole!;

                return Scaffold(
                  body: GradientBackground(
                    child: Column(
                      children: [
                        // Admin-only toggle row
                        if (userRoleLower == 'admin')
                          Padding(
                            padding: const EdgeInsets.only(
                                top: 16, left: 16, right: 16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ElevatedButton(
                                  onPressed: () {
                                    setState(() => _overrideRole = 'dealer');
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        (_overrideRole ?? 'dealer') == 'dealer'
                                            ? const Color(0xFFFF4E00)
                                            : Colors.black54,
                                  ),
                                  child: const Text('Dealer Summary'),
                                ),
                                const SizedBox(width: 12),
                                ElevatedButton(
                                  onPressed: () {
                                    setState(
                                        () => _overrideRole = 'transporter');
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        _overrideRole == 'transporter'
                                            ? const Color(0xFFFF4E00)
                                            : Colors.black54,
                                  ),
                                  child: const Text('Transporter Summary'),
                                ),
                              ],
                            ),
                          ),
                        Expanded(
                          child: FutureBuilder<File?>(
                            future: _generatePdf(
                              context,
                              offerData,
                              userData,
                              vehicleData,
                              transporterData,
                              viewerRole,
                            ),
                            builder: (context, pdfSnapshot) {
                              if (pdfSnapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Center(
                                    child: CircularProgressIndicator());
                              }

                              if (pdfSnapshot.hasError) {
                                return Center(
                                  child: Text(
                                      'Error generating PDF: ${pdfSnapshot.error}'),
                                );
                              }

                              final file = pdfSnapshot.data;

                              return file == null && kIsWeb
                                  ? const Center(
                                      child:
                                          Text('File downloaded successfully!'))
                                  : file == null
                                      ? const Center(
                                          child: Text('Failed to generate PDF'))
                                      : PDFView(
                                          filePath: file.path,
                                          autoSpacing: true,
                                          swipeHorizontal: true,
                                          pageFling: true,
                                        );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  floatingActionButton: FloatingActionButton(
                    onPressed: () async {
                      final currentUid = FirebaseAuth.instance.currentUser?.uid;
                      String viewerRole = (userData['userRole']
                              ?.toString()
                              .toLowerCase()
                              .trim()) ??
                          '';
                      if (currentUid != null) {
                        if (offerData['dealerId'] == currentUid) {
                          viewerRole = 'dealer';
                        } else if (offerData['transporterId'] == currentUid) {
                          viewerRole = 'transporter';
                        }
                      }
                      if (_overrideRole != null) viewerRole = _overrideRole!;
                      final file = await _generatePdf(
                        context,
                        offerData,
                        userData,
                        vehicleData,
                        transporterData,
                        viewerRole,
                      );
                      if (file != null) {
                        final xFile = XFile(file.path);
                        await Share.shareXFiles([xFile], text: 'Offer Summary');
                      }
                    },
                    tooltip: 'Share PDF',
                    child: const Icon(Icons.share),
                  ),
                );
              }
              return const Center(child: Text('No data available'));
            },
          );
        }
        return const Center(child: Text('No data available'));
      },
    );
  }
}
