import 'package:flutter_test/flutter_test.dart';
import 'package:ctp/utils/offer_status.dart';

void main() {
  group('Offer status normalization', () {
    test('normalizeOfferStatus lowers and trims', () {
      expect(normalizeOfferStatus('  Accepted '), 'accepted');
      expect(normalizeOfferStatus('In-Progress'), 'in-progress');
      expect(normalizeOfferStatus(null), '');
    });

    test('equalStatus compares normalized values', () {
      expect(equalStatus('Accepted', OfferStatuses.accepted), true);
      expect(equalStatus('  PAYMENT Pending ', OfferStatuses.paymentPending), true);
      expect(equalStatus('Collection Location Confirmation',
          OfferStatuses.collectionLocationConfirmation), true);
      expect(equalStatus('Done', OfferStatuses.completed), false);
    });
  });
}

