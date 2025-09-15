// Centralized offer status constants and helpers

class OfferStatuses {
  static const String inProgress = 'in-progress';
  static const String inspectionPending = 'inspection pending';
  static const String inspectionDone = 'inspection done';
  static const String setLocationAndTime = 'set location and time';
  static const String confirmLocation = 'confirm location';
  static const String confirmCollection = 'confirm collection';
  static const String collectionLocationConfirmation =
      'collection location confirmation';
  static const String collectionDetails = 'collection details';
  static const String paymentPending = 'payment pending';
  static const String paymentOptions = 'payment options';
  static const String paymentApproved = 'payment approved';
  static const String awaitingCollection = 'awaiting collection';
  static const String collectionReady = 'collection ready';
  static const String accepted = 'accepted';
  static const String paid = 'paid';
  static const String rejected = 'rejected';
  static const String archived = 'archived';
  static const String sold = 'sold';
  static const String successful = 'successful';
  static const String completed = 'completed';
  static const String issueReported = 'issue reported';
  static const String done = 'done';

  // Invoicing specific
  static const String transporterInvoicePending =
      'transporter invoice pending';
  static const String adminInvoicePending = 'admin invoice pending';
}

String normalizeOfferStatus(String? status) {
  return (status ?? '').toLowerCase().trim();
}

bool equalStatus(String? a, String bConstant) {
  return normalizeOfferStatus(a) == bConstant;
}
