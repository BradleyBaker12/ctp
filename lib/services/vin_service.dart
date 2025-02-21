import 'package:cloud_firestore/cloud_firestore.dart';

class VinService {
  static Future<bool> isVinNumberUnique(String vin) async {
    final doc = await FirebaseFirestore.instance
        .collection('VinNumbers')
        .doc(vin)
        .get();
    return !doc.exists;
  }

  static Future<void> storeVinNumber(String vin) async {
    await FirebaseFirestore.instance
        .collection('VinNumbers')
        .doc(vin)
        .set({'vin': vin});
  }
}
