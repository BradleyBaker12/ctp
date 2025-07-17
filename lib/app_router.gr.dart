// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouterGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

part of 'app_router.dart';

/// generated route for
/// [AcceptedOffersPage]
class AcceptedOffersRoute extends PageRouteInfo<void> {
  const AcceptedOffersRoute({List<PageRouteInfo>? children})
      : super(AcceptedOffersRoute.name, initialChildren: children);

  static const String name = 'AcceptedOffersRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const AcceptedOffersPage();
    },
  );
}

/// generated route for
/// [AccountStatusPage]
class AccountStatusRoute extends PageRouteInfo<void> {
  const AccountStatusRoute({List<PageRouteInfo>? children})
      : super(AccountStatusRoute.name, initialChildren: children);

  static const String name = 'AccountStatusRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const AccountStatusPage();
    },
  );
}

/// generated route for
/// [AddProfilePhotoAdminPage]
class AddProfilePhotoAdminRoute extends PageRouteInfo<void> {
  const AddProfilePhotoAdminRoute({List<PageRouteInfo>? children})
      : super(AddProfilePhotoAdminRoute.name, initialChildren: children);

  static const String name = 'AddProfilePhotoAdminRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const AddProfilePhotoAdminPage();
    },
  );
}

/// generated route for
/// [AddProfilePhotoPage]
class AddProfilePhotoRoute extends PageRouteInfo<void> {
  const AddProfilePhotoRoute({List<PageRouteInfo>? children})
      : super(AddProfilePhotoRoute.name, initialChildren: children);

  static const String name = 'AddProfilePhotoRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const AddProfilePhotoPage();
    },
  );
}

/// generated route for
/// [AddProfilePhotoPageTransporter]
class AddProfilePhotoRouteTransporter extends PageRouteInfo<void> {
  const AddProfilePhotoRouteTransporter({List<PageRouteInfo>? children})
      : super(AddProfilePhotoRouteTransporter.name, initialChildren: children);

  static const String name = 'AddProfilePhotoRouteTransporter';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const AddProfilePhotoPageTransporter();
    },
  );
}

/// generated route for
/// [AdjustOfferPage]
class AdjustOfferRoute extends PageRouteInfo<AdjustOfferRouteArgs> {
  AdjustOfferRoute({
    Key? key,
    required String offerId,
    List<PageRouteInfo>? children,
  }) : super(
          AdjustOfferRoute.name,
          args: AdjustOfferRouteArgs(key: key, offerId: offerId),
          initialChildren: children,
        );

  static const String name = 'AdjustOfferRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<AdjustOfferRouteArgs>();
      return AdjustOfferPage(key: args.key, offerId: args.offerId);
    },
  );
}

class AdjustOfferRouteArgs {
  const AdjustOfferRouteArgs({this.key, required this.offerId});

  final Key? key;

  final String offerId;

  @override
  String toString() {
    return 'AdjustOfferRouteArgs{key: $key, offerId: $offerId}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! AdjustOfferRouteArgs) return false;
    return key == other.key && offerId == other.offerId;
  }

  @override
  int get hashCode => key.hashCode ^ offerId.hashCode;
}

/// generated route for
/// [AdminFleetsPage]
class AdminFleetsRoute extends PageRouteInfo<void> {
  const AdminFleetsRoute({List<PageRouteInfo>? children})
      : super(AdminFleetsRoute.name, initialChildren: children);

  static const String name = 'AdminFleetsRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const AdminFleetsPage();
    },
  );
}

/// generated route for
/// [AdminHomePage]
class AdminHomeRoute extends PageRouteInfo<AdminHomeRouteArgs> {
  AdminHomeRoute({Key? key, int initialTab = 0, List<PageRouteInfo>? children})
      : super(
          AdminHomeRoute.name,
          args: AdminHomeRouteArgs(key: key, initialTab: initialTab),
          initialChildren: children,
        );

  static const String name = 'AdminHomeRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<AdminHomeRouteArgs>(
        orElse: () => const AdminHomeRouteArgs(),
      );
      return AdminHomePage(key: args.key, initialTab: args.initialTab);
    },
  );
}

class AdminHomeRouteArgs {
  const AdminHomeRouteArgs({this.key, this.initialTab = 0});

  final Key? key;

  final int initialTab;

  @override
  String toString() {
    return 'AdminHomeRouteArgs{key: $key, initialTab: $initialTab}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! AdminHomeRouteArgs) return false;
    return key == other.key && initialTab == other.initialTab;
  }

  @override
  int get hashCode => key.hashCode ^ initialTab.hashCode;
}

/// generated route for
/// [BoughtVehiclesListPage]
class BoughtVehiclesListRoute extends PageRouteInfo<void> {
  const BoughtVehiclesListRoute({List<PageRouteInfo>? children})
      : super(BoughtVehiclesListRoute.name, initialChildren: children);

  static const String name = 'BoughtVehiclesListRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const BoughtVehiclesListPage();
    },
  );
}

/// generated route for
/// [BulkOfferPage]
class BulkOfferRoute extends PageRouteInfo<void> {
  const BulkOfferRoute({List<PageRouteInfo>? children})
      : super(BulkOfferRoute.name, initialChildren: children);

  static const String name = 'BulkOfferRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const BulkOfferPage();
    },
  );
}

/// generated route for
/// [ChassisEditPage]
class ChassisEditRoute extends PageRouteInfo<ChassisEditRouteArgs> {
  ChassisEditRoute({
    Key? key,
    required String vehicleId,
    required VoidCallback onProgressUpdate,
    bool isEditing = false,
    bool inTabsPage = false,
    List<PageRouteInfo>? children,
  }) : super(
          ChassisEditRoute.name,
          args: ChassisEditRouteArgs(
            key: key,
            vehicleId: vehicleId,
            onProgressUpdate: onProgressUpdate,
            isEditing: isEditing,
            inTabsPage: inTabsPage,
          ),
          initialChildren: children,
        );

  static const String name = 'ChassisEditRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<ChassisEditRouteArgs>();
      return ChassisEditPage(
        key: args.key,
        vehicleId: args.vehicleId,
        onProgressUpdate: args.onProgressUpdate,
        isEditing: args.isEditing,
        inTabsPage: args.inTabsPage,
      );
    },
  );
}

class ChassisEditRouteArgs {
  const ChassisEditRouteArgs({
    this.key,
    required this.vehicleId,
    required this.onProgressUpdate,
    this.isEditing = false,
    this.inTabsPage = false,
  });

  final Key? key;

  final String vehicleId;

  final VoidCallback onProgressUpdate;

  final bool isEditing;

  final bool inTabsPage;

  @override
  String toString() {
    return 'ChassisEditRouteArgs{key: $key, vehicleId: $vehicleId, onProgressUpdate: $onProgressUpdate, isEditing: $isEditing, inTabsPage: $inTabsPage}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ChassisEditRouteArgs) return false;
    return key == other.key &&
        vehicleId == other.vehicleId &&
        onProgressUpdate == other.onProgressUpdate &&
        isEditing == other.isEditing &&
        inTabsPage == other.inTabsPage;
  }

  @override
  int get hashCode =>
      key.hashCode ^
      vehicleId.hashCode ^
      onProgressUpdate.hashCode ^
      isEditing.hashCode ^
      inTabsPage.hashCode;
}

/// generated route for
/// [ChassisPage]
class ChassisRoute extends PageRouteInfo<ChassisRouteArgs> {
  ChassisRoute({
    Key? key,
    required String vehicleId,
    required VoidCallback onProgressUpdate,
    bool isEditing = false,
    List<PageRouteInfo>? children,
  }) : super(
          ChassisRoute.name,
          args: ChassisRouteArgs(
            key: key,
            vehicleId: vehicleId,
            onProgressUpdate: onProgressUpdate,
            isEditing: isEditing,
          ),
          initialChildren: children,
        );

  static const String name = 'ChassisRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<ChassisRouteArgs>();
      return ChassisPage(
        key: args.key,
        vehicleId: args.vehicleId,
        onProgressUpdate: args.onProgressUpdate,
        isEditing: args.isEditing,
      );
    },
  );
}

class ChassisRouteArgs {
  const ChassisRouteArgs({
    this.key,
    required this.vehicleId,
    required this.onProgressUpdate,
    this.isEditing = false,
  });

  final Key? key;

  final String vehicleId;

  final VoidCallback onProgressUpdate;

  final bool isEditing;

  @override
  String toString() {
    return 'ChassisRouteArgs{key: $key, vehicleId: $vehicleId, onProgressUpdate: $onProgressUpdate, isEditing: $isEditing}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ChassisRouteArgs) return false;
    return key == other.key &&
        vehicleId == other.vehicleId &&
        onProgressUpdate == other.onProgressUpdate &&
        isEditing == other.isEditing;
  }

  @override
  int get hashCode =>
      key.hashCode ^
      vehicleId.hashCode ^
      onProgressUpdate.hashCode ^
      isEditing.hashCode;
}

/// generated route for
/// [CollectVehiclePage]
class CollectVehicleRoute extends PageRouteInfo<CollectVehicleRouteArgs> {
  CollectVehicleRoute({
    Key? key,
    required String offerId,
    List<PageRouteInfo>? children,
  }) : super(
          CollectVehicleRoute.name,
          args: CollectVehicleRouteArgs(key: key, offerId: offerId),
          initialChildren: children,
        );

  static const String name = 'CollectVehicleRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<CollectVehicleRouteArgs>();
      return CollectVehiclePage(key: args.key, offerId: args.offerId);
    },
  );
}

class CollectVehicleRouteArgs {
  const CollectVehicleRouteArgs({this.key, required this.offerId});

  final Key? key;

  final String offerId;

  @override
  String toString() {
    return 'CollectVehicleRouteArgs{key: $key, offerId: $offerId}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! CollectVehicleRouteArgs) return false;
    return key == other.key && offerId == other.offerId;
  }

  @override
  int get hashCode => key.hashCode ^ offerId.hashCode;
}

/// generated route for
/// [CollectionConfirmationPage]
class CollectionConfirmationRoute
    extends PageRouteInfo<CollectionConfirmationRouteArgs> {
  CollectionConfirmationRoute({
    Key? key,
    required String location,
    required String address,
    required DateTime date,
    required String time,
    required String offerId,
    String? vehicleId,
    LatLng? latLng,
    List<PageRouteInfo>? children,
  }) : super(
          CollectionConfirmationRoute.name,
          args: CollectionConfirmationRouteArgs(
            key: key,
            location: location,
            address: address,
            date: date,
            time: time,
            offerId: offerId,
            vehicleId: vehicleId,
            latLng: latLng,
          ),
          initialChildren: children,
        );

  static const String name = 'CollectionConfirmationRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<CollectionConfirmationRouteArgs>();
      return CollectionConfirmationPage(
        key: args.key,
        location: args.location,
        address: args.address,
        date: args.date,
        time: args.time,
        offerId: args.offerId,
        vehicleId: args.vehicleId,
        latLng: args.latLng,
      );
    },
  );
}

class CollectionConfirmationRouteArgs {
  const CollectionConfirmationRouteArgs({
    this.key,
    required this.location,
    required this.address,
    required this.date,
    required this.time,
    required this.offerId,
    this.vehicleId,
    this.latLng,
  });

  final Key? key;

  final String location;

  final String address;

  final DateTime date;

  final String time;

  final String offerId;

  final String? vehicleId;

  final LatLng? latLng;

  @override
  String toString() {
    return 'CollectionConfirmationRouteArgs{key: $key, location: $location, address: $address, date: $date, time: $time, offerId: $offerId, vehicleId: $vehicleId, latLng: $latLng}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! CollectionConfirmationRouteArgs) return false;
    return key == other.key &&
        location == other.location &&
        address == other.address &&
        date == other.date &&
        time == other.time &&
        offerId == other.offerId &&
        vehicleId == other.vehicleId &&
        latLng == other.latLng;
  }

  @override
  int get hashCode =>
      key.hashCode ^
      location.hashCode ^
      address.hashCode ^
      date.hashCode ^
      time.hashCode ^
      offerId.hashCode ^
      vehicleId.hashCode ^
      latLng.hashCode;
}

/// generated route for
/// [CollectionDetailsPage]
class CollectionDetailsRoute extends PageRouteInfo<CollectionDetailsRouteArgs> {
  CollectionDetailsRoute({
    Key? key,
    required String offerId,
    List<PageRouteInfo>? children,
  }) : super(
          CollectionDetailsRoute.name,
          args: CollectionDetailsRouteArgs(key: key, offerId: offerId),
          initialChildren: children,
        );

  static const String name = 'CollectionDetailsRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<CollectionDetailsRouteArgs>();
      return CollectionDetailsPage(key: args.key, offerId: args.offerId);
    },
  );
}

class CollectionDetailsRouteArgs {
  const CollectionDetailsRouteArgs({this.key, required this.offerId});

  final Key? key;

  final String offerId;

  @override
  String toString() {
    return 'CollectionDetailsRouteArgs{key: $key, offerId: $offerId}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! CollectionDetailsRouteArgs) return false;
    return key == other.key && offerId == other.offerId;
  }

  @override
  int get hashCode => key.hashCode ^ offerId.hashCode;
}

/// generated route for
/// [ComplaintDetailPage]
class ComplaintDetailRoute extends PageRouteInfo<ComplaintDetailRouteArgs> {
  ComplaintDetailRoute({
    Key? key,
    required Complaint complaint,
    List<PageRouteInfo>? children,
  }) : super(
          ComplaintDetailRoute.name,
          args: ComplaintDetailRouteArgs(key: key, complaint: complaint),
          initialChildren: children,
        );

  static const String name = 'ComplaintDetailRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<ComplaintDetailRouteArgs>();
      return ComplaintDetailPage(key: args.key, complaint: args.complaint);
    },
  );
}

class ComplaintDetailRouteArgs {
  const ComplaintDetailRouteArgs({this.key, required this.complaint});

  final Key? key;

  final Complaint complaint;

  @override
  String toString() {
    return 'ComplaintDetailRouteArgs{key: $key, complaint: $complaint}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ComplaintDetailRouteArgs) return false;
    return key == other.key && complaint == other.complaint;
  }

  @override
  int get hashCode => key.hashCode ^ complaint.hashCode;
}

/// generated route for
/// [ConfirmationPage]
class ConfirmationRoute extends PageRouteInfo<ConfirmationRouteArgs> {
  ConfirmationRoute({
    Key? key,
    required String offerId,
    required String location,
    required String address,
    required DateTime date,
    required String time,
    required LatLng latLng,
    required String brand,
    required String variant,
    required String offerAmount,
    required String vehicleId,
    List<PageRouteInfo>? children,
  }) : super(
          ConfirmationRoute.name,
          args: ConfirmationRouteArgs(
            key: key,
            offerId: offerId,
            location: location,
            address: address,
            date: date,
            time: time,
            latLng: latLng,
            brand: brand,
            variant: variant,
            offerAmount: offerAmount,
            vehicleId: vehicleId,
          ),
          initialChildren: children,
        );

  static const String name = 'ConfirmationRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<ConfirmationRouteArgs>();
      return ConfirmationPage(
        key: args.key,
        offerId: args.offerId,
        location: args.location,
        address: args.address,
        date: args.date,
        time: args.time,
        latLng: args.latLng,
        brand: args.brand,
        variant: args.variant,
        offerAmount: args.offerAmount,
        vehicleId: args.vehicleId,
      );
    },
  );
}

class ConfirmationRouteArgs {
  const ConfirmationRouteArgs({
    this.key,
    required this.offerId,
    required this.location,
    required this.address,
    required this.date,
    required this.time,
    required this.latLng,
    required this.brand,
    required this.variant,
    required this.offerAmount,
    required this.vehicleId,
  });

  final Key? key;

  final String offerId;

  final String location;

  final String address;

  final DateTime date;

  final String time;

  final LatLng latLng;

  final String brand;

  final String variant;

  final String offerAmount;

  final String vehicleId;

  @override
  String toString() {
    return 'ConfirmationRouteArgs{key: $key, offerId: $offerId, location: $location, address: $address, date: $date, time: $time, latLng: $latLng, brand: $brand, variant: $variant, offerAmount: $offerAmount, vehicleId: $vehicleId}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ConfirmationRouteArgs) return false;
    return key == other.key &&
        offerId == other.offerId &&
        location == other.location &&
        address == other.address &&
        date == other.date &&
        time == other.time &&
        latLng == other.latLng &&
        brand == other.brand &&
        variant == other.variant &&
        offerAmount == other.offerAmount &&
        vehicleId == other.vehicleId;
  }

  @override
  int get hashCode =>
      key.hashCode ^
      offerId.hashCode ^
      location.hashCode ^
      address.hashCode ^
      date.hashCode ^
      time.hashCode ^
      latLng.hashCode ^
      brand.hashCode ^
      variant.hashCode ^
      offerAmount.hashCode ^
      vehicleId.hashCode;
}

/// generated route for
/// [CreateFleetPage]
class CreateFleetRoute extends PageRouteInfo<void> {
  const CreateFleetRoute({List<PageRouteInfo>? children})
      : super(CreateFleetRoute.name, initialChildren: children);

  static const String name = 'CreateFleetRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const CreateFleetPage();
    },
  );
}

/// generated route for
/// [CropPhotoPage]
class CropPhotoRoute extends PageRouteInfo<CropPhotoRouteArgs> {
  CropPhotoRoute({
    Key? key,
    required XFile imageFile,
    required Map<String, dynamic> userData,
    List<PageRouteInfo>? children,
  }) : super(
          CropPhotoRoute.name,
          args: CropPhotoRouteArgs(
            key: key,
            imageFile: imageFile,
            userData: userData,
          ),
          initialChildren: children,
        );

  static const String name = 'CropPhotoRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<CropPhotoRouteArgs>();
      return CropPhotoPage(
        key: args.key,
        imageFile: args.imageFile,
        userData: args.userData,
      );
    },
  );
}

class CropPhotoRouteArgs {
  const CropPhotoRouteArgs({
    this.key,
    required this.imageFile,
    required this.userData,
  });

  final Key? key;

  final XFile imageFile;

  final Map<String, dynamic> userData;

  @override
  String toString() {
    return 'CropPhotoRouteArgs{key: $key, imageFile: $imageFile, userData: $userData}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! CropPhotoRouteArgs) return false;
    return key == other.key &&
        imageFile == other.imageFile &&
        const MapEquality().equals(userData, other.userData);
  }

  @override
  int get hashCode =>
      key.hashCode ^ imageFile.hashCode ^ const MapEquality().hash(userData);
}

/// generated route for
/// [DealerRegPage]
class DealerRegRoute extends PageRouteInfo<void> {
  const DealerRegRoute({List<PageRouteInfo>? children})
      : super(DealerRegRoute.name, initialChildren: children);

  static const String name = 'DealerRegRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const DealerRegPage();
    },
  );
}

/// generated route for
/// [DocumentPreviewScreen]
class DocumentPreviewRoute extends PageRouteInfo<DocumentPreviewRouteArgs> {
  DocumentPreviewRoute({
    Key? key,
    String? url,
    File? file,
    List<PageRouteInfo>? children,
  }) : super(
          DocumentPreviewRoute.name,
          args: DocumentPreviewRouteArgs(key: key, url: url, file: file),
          initialChildren: children,
        );

  static const String name = 'DocumentPreviewRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<DocumentPreviewRouteArgs>(
        orElse: () => const DocumentPreviewRouteArgs(),
      );
      return DocumentPreviewScreen(
        key: args.key,
        url: args.url,
        file: args.file,
      );
    },
  );
}

class DocumentPreviewRouteArgs {
  const DocumentPreviewRouteArgs({this.key, this.url, this.file});

  final Key? key;

  final String? url;

  final File? file;

  @override
  String toString() {
    return 'DocumentPreviewRouteArgs{key: $key, url: $url, file: $file}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! DocumentPreviewRouteArgs) return false;
    return key == other.key && url == other.url && file == other.file;
  }

  @override
  int get hashCode => key.hashCode ^ url.hashCode ^ file.hashCode;
}

/// generated route for
/// [DriveTrainEditPage]
class DriveTrainEditRoute extends PageRouteInfo<DriveTrainEditRouteArgs> {
  DriveTrainEditRoute({
    Key? key,
    required String vehicleId,
    required VoidCallback onProgressUpdate,
    bool isEditing = false,
    bool inTabsPage = false,
    List<PageRouteInfo>? children,
  }) : super(
          DriveTrainEditRoute.name,
          args: DriveTrainEditRouteArgs(
            key: key,
            vehicleId: vehicleId,
            onProgressUpdate: onProgressUpdate,
            isEditing: isEditing,
            inTabsPage: inTabsPage,
          ),
          initialChildren: children,
        );

  static const String name = 'DriveTrainEditRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<DriveTrainEditRouteArgs>();
      return DriveTrainEditPage(
        key: args.key,
        vehicleId: args.vehicleId,
        onProgressUpdate: args.onProgressUpdate,
        isEditing: args.isEditing,
        inTabsPage: args.inTabsPage,
      );
    },
  );
}

class DriveTrainEditRouteArgs {
  const DriveTrainEditRouteArgs({
    this.key,
    required this.vehicleId,
    required this.onProgressUpdate,
    this.isEditing = false,
    this.inTabsPage = false,
  });

  final Key? key;

  final String vehicleId;

  final VoidCallback onProgressUpdate;

  final bool isEditing;

  final bool inTabsPage;

  @override
  String toString() {
    return 'DriveTrainEditRouteArgs{key: $key, vehicleId: $vehicleId, onProgressUpdate: $onProgressUpdate, isEditing: $isEditing, inTabsPage: $inTabsPage}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! DriveTrainEditRouteArgs) return false;
    return key == other.key &&
        vehicleId == other.vehicleId &&
        onProgressUpdate == other.onProgressUpdate &&
        isEditing == other.isEditing &&
        inTabsPage == other.inTabsPage;
  }

  @override
  int get hashCode =>
      key.hashCode ^
      vehicleId.hashCode ^
      onProgressUpdate.hashCode ^
      isEditing.hashCode ^
      inTabsPage.hashCode;
}

/// generated route for
/// [DriveTrainPage]
class DriveTrainRoute extends PageRouteInfo<DriveTrainRouteArgs> {
  DriveTrainRoute({
    Key? key,
    required String vehicleId,
    required VoidCallback onProgressUpdate,
    bool isEditing = false,
    List<PageRouteInfo>? children,
  }) : super(
          DriveTrainRoute.name,
          args: DriveTrainRouteArgs(
            key: key,
            vehicleId: vehicleId,
            onProgressUpdate: onProgressUpdate,
            isEditing: isEditing,
          ),
          initialChildren: children,
        );

  static const String name = 'DriveTrainRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<DriveTrainRouteArgs>();
      return DriveTrainPage(
        key: args.key,
        vehicleId: args.vehicleId,
        onProgressUpdate: args.onProgressUpdate,
        isEditing: args.isEditing,
      );
    },
  );
}

class DriveTrainRouteArgs {
  const DriveTrainRouteArgs({
    this.key,
    required this.vehicleId,
    required this.onProgressUpdate,
    this.isEditing = false,
  });

  final Key? key;

  final String vehicleId;

  final VoidCallback onProgressUpdate;

  final bool isEditing;

  @override
  String toString() {
    return 'DriveTrainRouteArgs{key: $key, vehicleId: $vehicleId, onProgressUpdate: $onProgressUpdate, isEditing: $isEditing}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! DriveTrainRouteArgs) return false;
    return key == other.key &&
        vehicleId == other.vehicleId &&
        onProgressUpdate == other.onProgressUpdate &&
        isEditing == other.isEditing;
  }

  @override
  int get hashCode =>
      key.hashCode ^
      vehicleId.hashCode ^
      onProgressUpdate.hashCode ^
      isEditing.hashCode;
}

/// generated route for
/// [EditProfilePage]
class EditProfileRoute extends PageRouteInfo<void> {
  const EditProfileRoute({List<PageRouteInfo>? children})
      : super(EditProfileRoute.name, initialChildren: children);

  static const String name = 'EditProfileRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const EditProfilePage();
    },
  );
}

/// generated route for
/// [ErrorPage]
class ErrorRoute extends PageRouteInfo<void> {
  const ErrorRoute({List<PageRouteInfo>? children})
      : super(ErrorRoute.name, initialChildren: children);

  static const String name = 'ErrorRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const ErrorPage();
    },
  );
}

/// generated route for
/// [ExternalCabEditPage]
class ExternalCabEditRoute extends PageRouteInfo<ExternalCabEditRouteArgs> {
  ExternalCabEditRoute({
    Key? key,
    required String vehicleId,
    VoidCallback? onContinue,
    required VoidCallback onProgressUpdate,
    bool isEditing = false,
    bool inTabsPage = false,
    List<PageRouteInfo>? children,
  }) : super(
          ExternalCabEditRoute.name,
          args: ExternalCabEditRouteArgs(
            key: key,
            vehicleId: vehicleId,
            onContinue: onContinue,
            onProgressUpdate: onProgressUpdate,
            isEditing: isEditing,
            inTabsPage: inTabsPage,
          ),
          initialChildren: children,
        );

  static const String name = 'ExternalCabEditRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<ExternalCabEditRouteArgs>();
      return ExternalCabEditPage(
        key: args.key,
        vehicleId: args.vehicleId,
        onContinue: args.onContinue,
        onProgressUpdate: args.onProgressUpdate,
        isEditing: args.isEditing,
        inTabsPage: args.inTabsPage,
      );
    },
  );
}

class ExternalCabEditRouteArgs {
  const ExternalCabEditRouteArgs({
    this.key,
    required this.vehicleId,
    this.onContinue,
    required this.onProgressUpdate,
    this.isEditing = false,
    this.inTabsPage = false,
  });

  final Key? key;

  final String vehicleId;

  final VoidCallback? onContinue;

  final VoidCallback onProgressUpdate;

  final bool isEditing;

  final bool inTabsPage;

  @override
  String toString() {
    return 'ExternalCabEditRouteArgs{key: $key, vehicleId: $vehicleId, onContinue: $onContinue, onProgressUpdate: $onProgressUpdate, isEditing: $isEditing, inTabsPage: $inTabsPage}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ExternalCabEditRouteArgs) return false;
    return key == other.key &&
        vehicleId == other.vehicleId &&
        onContinue == other.onContinue &&
        onProgressUpdate == other.onProgressUpdate &&
        isEditing == other.isEditing &&
        inTabsPage == other.inTabsPage;
  }

  @override
  int get hashCode =>
      key.hashCode ^
      vehicleId.hashCode ^
      onContinue.hashCode ^
      onProgressUpdate.hashCode ^
      isEditing.hashCode ^
      inTabsPage.hashCode;
}

/// generated route for
/// [ExternalCabPage]
class ExternalCabRoute extends PageRouteInfo<ExternalCabRouteArgs> {
  ExternalCabRoute({
    Key? key,
    required String vehicleId,
    VoidCallback? onContinue,
    required VoidCallback onProgressUpdate,
    bool isEditing = false,
    List<PageRouteInfo>? children,
  }) : super(
          ExternalCabRoute.name,
          args: ExternalCabRouteArgs(
            key: key,
            vehicleId: vehicleId,
            onContinue: onContinue,
            onProgressUpdate: onProgressUpdate,
            isEditing: isEditing,
          ),
          initialChildren: children,
        );

  static const String name = 'ExternalCabRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<ExternalCabRouteArgs>();
      return ExternalCabPage(
        key: args.key,
        vehicleId: args.vehicleId,
        onContinue: args.onContinue,
        onProgressUpdate: args.onProgressUpdate,
        isEditing: args.isEditing,
      );
    },
  );
}

class ExternalCabRouteArgs {
  const ExternalCabRouteArgs({
    this.key,
    required this.vehicleId,
    this.onContinue,
    required this.onProgressUpdate,
    this.isEditing = false,
  });

  final Key? key;

  final String vehicleId;

  final VoidCallback? onContinue;

  final VoidCallback onProgressUpdate;

  final bool isEditing;

  @override
  String toString() {
    return 'ExternalCabRouteArgs{key: $key, vehicleId: $vehicleId, onContinue: $onContinue, onProgressUpdate: $onProgressUpdate, isEditing: $isEditing}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ExternalCabRouteArgs) return false;
    return key == other.key &&
        vehicleId == other.vehicleId &&
        onContinue == other.onContinue &&
        onProgressUpdate == other.onProgressUpdate &&
        isEditing == other.isEditing;
  }

  @override
  int get hashCode =>
      key.hashCode ^
      vehicleId.hashCode ^
      onContinue.hashCode ^
      onProgressUpdate.hashCode ^
      isEditing.hashCode;
}

/// generated route for
/// [FinalInspectionApprovalPage]
class FinalInspectionApprovalRoute
    extends PageRouteInfo<FinalInspectionApprovalRouteArgs> {
  FinalInspectionApprovalRoute({
    Key? key,
    required String offerId,
    required String oldOffer,
    required String vehicleName,
    List<PageRouteInfo>? children,
  }) : super(
          FinalInspectionApprovalRoute.name,
          args: FinalInspectionApprovalRouteArgs(
            key: key,
            offerId: offerId,
            oldOffer: oldOffer,
            vehicleName: vehicleName,
          ),
          initialChildren: children,
        );

  static const String name = 'FinalInspectionApprovalRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<FinalInspectionApprovalRouteArgs>();
      return FinalInspectionApprovalPage(
        key: args.key,
        offerId: args.offerId,
        oldOffer: args.oldOffer,
        vehicleName: args.vehicleName,
      );
    },
  );
}

class FinalInspectionApprovalRouteArgs {
  const FinalInspectionApprovalRouteArgs({
    this.key,
    required this.offerId,
    required this.oldOffer,
    required this.vehicleName,
  });

  final Key? key;

  final String offerId;

  final String oldOffer;

  final String vehicleName;

  @override
  String toString() {
    return 'FinalInspectionApprovalRouteArgs{key: $key, offerId: $offerId, oldOffer: $oldOffer, vehicleName: $vehicleName}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! FinalInspectionApprovalRouteArgs) return false;
    return key == other.key &&
        offerId == other.offerId &&
        oldOffer == other.oldOffer &&
        vehicleName == other.vehicleName;
  }

  @override
  int get hashCode =>
      key.hashCode ^
      offerId.hashCode ^
      oldOffer.hashCode ^
      vehicleName.hashCode;
}

/// generated route for
/// [FirstNamePage]
class FirstNameRoute extends PageRouteInfo<void> {
  const FirstNameRoute({List<PageRouteInfo>? children})
      : super(FirstNameRoute.name, initialChildren: children);

  static const String name = 'FirstNameRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const FirstNamePage();
    },
  );
}

/// generated route for
/// [FleetDetailPage]
class FleetDetailRoute extends PageRouteInfo<FleetDetailRouteArgs> {
  FleetDetailRoute({
    Key? key,
    required String fleetId,
    List<PageRouteInfo>? children,
  }) : super(
          FleetDetailRoute.name,
          args: FleetDetailRouteArgs(key: key, fleetId: fleetId),
          initialChildren: children,
        );

  static const String name = 'FleetDetailRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<FleetDetailRouteArgs>();
      return FleetDetailPage(key: args.key, fleetId: args.fleetId);
    },
  );
}

class FleetDetailRouteArgs {
  const FleetDetailRouteArgs({this.key, required this.fleetId});

  final Key? key;

  final String fleetId;

  @override
  String toString() {
    return 'FleetDetailRouteArgs{key: $key, fleetId: $fleetId}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! FleetDetailRouteArgs) return false;
    return key == other.key && fleetId == other.fleetId;
  }

  @override
  int get hashCode => key.hashCode ^ fleetId.hashCode;
}

/// generated route for
/// [FleetsManagementPage]
class FleetsManagementRoute extends PageRouteInfo<void> {
  const FleetsManagementRoute({List<PageRouteInfo>? children})
      : super(FleetsManagementRoute.name, initialChildren: children);

  static const String name = 'FleetsManagementRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const FleetsManagementPage();
    },
  );
}

/// generated route for
/// [HomePage]
class HomeRoute extends PageRouteInfo<void> {
  const HomeRoute({List<PageRouteInfo>? children})
      : super(HomeRoute.name, initialChildren: children);

  static const String name = 'HomeRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const HomePage();
    },
  );
}

/// generated route for
/// [HouseRulesPage]
class HouseRulesRoute extends PageRouteInfo<void> {
  const HouseRulesRoute({List<PageRouteInfo>? children})
      : super(HouseRulesRoute.name, initialChildren: children);

  static const String name = 'HouseRulesRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const HouseRulesPage();
    },
  );
}

/// generated route for
/// [InspectionDetailsPage]
class InspectionDetailsRoute extends PageRouteInfo<InspectionDetailsRouteArgs> {
  InspectionDetailsRoute({
    Key? key,
    required String offerId,
    required String brand,
    required String variant,
    required String offerAmount,
    required String vehicleId,
    List<PageRouteInfo>? children,
  }) : super(
          InspectionDetailsRoute.name,
          args: InspectionDetailsRouteArgs(
            key: key,
            offerId: offerId,
            brand: brand,
            variant: variant,
            offerAmount: offerAmount,
            vehicleId: vehicleId,
          ),
          initialChildren: children,
        );

  static const String name = 'InspectionDetailsRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<InspectionDetailsRouteArgs>();
      return InspectionDetailsPage(
        key: args.key,
        offerId: args.offerId,
        brand: args.brand,
        variant: args.variant,
        offerAmount: args.offerAmount,
        vehicleId: args.vehicleId,
      );
    },
  );
}

class InspectionDetailsRouteArgs {
  const InspectionDetailsRouteArgs({
    this.key,
    required this.offerId,
    required this.brand,
    required this.variant,
    required this.offerAmount,
    required this.vehicleId,
  });

  final Key? key;

  final String offerId;

  final String brand;

  final String variant;

  final String offerAmount;

  final String vehicleId;

  @override
  String toString() {
    return 'InspectionDetailsRouteArgs{key: $key, offerId: $offerId, brand: $brand, variant: $variant, offerAmount: $offerAmount, vehicleId: $vehicleId}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! InspectionDetailsRouteArgs) return false;
    return key == other.key &&
        offerId == other.offerId &&
        brand == other.brand &&
        variant == other.variant &&
        offerAmount == other.offerAmount &&
        vehicleId == other.vehicleId;
  }

  @override
  int get hashCode =>
      key.hashCode ^
      offerId.hashCode ^
      brand.hashCode ^
      variant.hashCode ^
      offerAmount.hashCode ^
      vehicleId.hashCode;
}

/// generated route for
/// [InternalCabEditPage]
class InternalCabEditRoute extends PageRouteInfo<InternalCabEditRouteArgs> {
  InternalCabEditRoute({
    Key? key,
    required String vehicleId,
    required VoidCallback onProgressUpdate,
    bool isEditing = false,
    bool inTabsPage = false,
    List<PageRouteInfo>? children,
  }) : super(
          InternalCabEditRoute.name,
          args: InternalCabEditRouteArgs(
            key: key,
            vehicleId: vehicleId,
            onProgressUpdate: onProgressUpdate,
            isEditing: isEditing,
            inTabsPage: inTabsPage,
          ),
          initialChildren: children,
        );

  static const String name = 'InternalCabEditRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<InternalCabEditRouteArgs>();
      return InternalCabEditPage(
        key: args.key,
        vehicleId: args.vehicleId,
        onProgressUpdate: args.onProgressUpdate,
        isEditing: args.isEditing,
        inTabsPage: args.inTabsPage,
      );
    },
  );
}

class InternalCabEditRouteArgs {
  const InternalCabEditRouteArgs({
    this.key,
    required this.vehicleId,
    required this.onProgressUpdate,
    this.isEditing = false,
    this.inTabsPage = false,
  });

  final Key? key;

  final String vehicleId;

  final VoidCallback onProgressUpdate;

  final bool isEditing;

  final bool inTabsPage;

  @override
  String toString() {
    return 'InternalCabEditRouteArgs{key: $key, vehicleId: $vehicleId, onProgressUpdate: $onProgressUpdate, isEditing: $isEditing, inTabsPage: $inTabsPage}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! InternalCabEditRouteArgs) return false;
    return key == other.key &&
        vehicleId == other.vehicleId &&
        onProgressUpdate == other.onProgressUpdate &&
        isEditing == other.isEditing &&
        inTabsPage == other.inTabsPage;
  }

  @override
  int get hashCode =>
      key.hashCode ^
      vehicleId.hashCode ^
      onProgressUpdate.hashCode ^
      isEditing.hashCode ^
      inTabsPage.hashCode;
}

/// generated route for
/// [InternalCabPage]
class InternalCabRoute extends PageRouteInfo<InternalCabRouteArgs> {
  InternalCabRoute({
    Key? key,
    required String vehicleId,
    required VoidCallback onProgressUpdate,
    bool isEditing = false,
    List<PageRouteInfo>? children,
  }) : super(
          InternalCabRoute.name,
          args: InternalCabRouteArgs(
            key: key,
            vehicleId: vehicleId,
            onProgressUpdate: onProgressUpdate,
            isEditing: isEditing,
          ),
          initialChildren: children,
        );

  static const String name = 'InternalCabRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<InternalCabRouteArgs>();
      return InternalCabPage(
        key: args.key,
        vehicleId: args.vehicleId,
        onProgressUpdate: args.onProgressUpdate,
        isEditing: args.isEditing,
      );
    },
  );
}

class InternalCabRouteArgs {
  const InternalCabRouteArgs({
    this.key,
    required this.vehicleId,
    required this.onProgressUpdate,
    this.isEditing = false,
  });

  final Key? key;

  final String vehicleId;

  final VoidCallback onProgressUpdate;

  final bool isEditing;

  @override
  String toString() {
    return 'InternalCabRouteArgs{key: $key, vehicleId: $vehicleId, onProgressUpdate: $onProgressUpdate, isEditing: $isEditing}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! InternalCabRouteArgs) return false;
    return key == other.key &&
        vehicleId == other.vehicleId &&
        onProgressUpdate == other.onProgressUpdate &&
        isEditing == other.isEditing;
  }

  @override
  int get hashCode =>
      key.hashCode ^
      vehicleId.hashCode ^
      onProgressUpdate.hashCode ^
      isEditing.hashCode;
}

/// generated route for
/// [LocalViewerPage]
class LocalViewerRoute extends PageRouteInfo<LocalViewerRouteArgs> {
  LocalViewerRoute({
    Key? key,
    required Uint8List file,
    required String title,
    List<PageRouteInfo>? children,
  }) : super(
          LocalViewerRoute.name,
          args: LocalViewerRouteArgs(key: key, file: file, title: title),
          initialChildren: children,
        );

  static const String name = 'LocalViewerRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<LocalViewerRouteArgs>();
      return LocalViewerPage(key: args.key, file: args.file, title: args.title);
    },
  );
}

class LocalViewerRouteArgs {
  const LocalViewerRouteArgs({
    this.key,
    required this.file,
    required this.title,
  });

  final Key? key;

  final Uint8List file;

  final String title;

  @override
  String toString() {
    return 'LocalViewerRouteArgs{key: $key, file: $file, title: $title}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! LocalViewerRouteArgs) return false;
    return key == other.key && file == other.file && title == other.title;
  }

  @override
  int get hashCode => key.hashCode ^ file.hashCode ^ title.hashCode;
}

/// generated route for
/// [LocationConfirmationPage]
class LocationConfirmationRoute
    extends PageRouteInfo<LocationConfirmationRouteArgs> {
  LocationConfirmationRoute({
    Key? key,
    required String offerId,
    required String location,
    required String address,
    required DateTime date,
    required String time,
    required String brand,
    required String variant,
    required String offerAmount,
    required String vehicleId,
    List<PageRouteInfo>? children,
  }) : super(
          LocationConfirmationRoute.name,
          args: LocationConfirmationRouteArgs(
            key: key,
            offerId: offerId,
            location: location,
            address: address,
            date: date,
            time: time,
            brand: brand,
            variant: variant,
            offerAmount: offerAmount,
            vehicleId: vehicleId,
          ),
          initialChildren: children,
        );

  static const String name = 'LocationConfirmationRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<LocationConfirmationRouteArgs>();
      return LocationConfirmationPage(
        key: args.key,
        offerId: args.offerId,
        location: args.location,
        address: args.address,
        date: args.date,
        time: args.time,
        brand: args.brand,
        variant: args.variant,
        offerAmount: args.offerAmount,
        vehicleId: args.vehicleId,
      );
    },
  );
}

class LocationConfirmationRouteArgs {
  const LocationConfirmationRouteArgs({
    this.key,
    required this.offerId,
    required this.location,
    required this.address,
    required this.date,
    required this.time,
    required this.brand,
    required this.variant,
    required this.offerAmount,
    required this.vehicleId,
  });

  final Key? key;

  final String offerId;

  final String location;

  final String address;

  final DateTime date;

  final String time;

  final String brand;

  final String variant;

  final String offerAmount;

  final String vehicleId;

  @override
  String toString() {
    return 'LocationConfirmationRouteArgs{key: $key, offerId: $offerId, location: $location, address: $address, date: $date, time: $time, brand: $brand, variant: $variant, offerAmount: $offerAmount, vehicleId: $vehicleId}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! LocationConfirmationRouteArgs) return false;
    return key == other.key &&
        offerId == other.offerId &&
        location == other.location &&
        address == other.address &&
        date == other.date &&
        time == other.time &&
        brand == other.brand &&
        variant == other.variant &&
        offerAmount == other.offerAmount &&
        vehicleId == other.vehicleId;
  }

  @override
  int get hashCode =>
      key.hashCode ^
      offerId.hashCode ^
      location.hashCode ^
      address.hashCode ^
      date.hashCode ^
      time.hashCode ^
      brand.hashCode ^
      variant.hashCode ^
      offerAmount.hashCode ^
      vehicleId.hashCode;
}

/// generated route for
/// [LoginPage]
class LoginRoute extends PageRouteInfo<void> {
  const LoginRoute({List<PageRouteInfo>? children})
      : super(LoginRoute.name, initialChildren: children);

  static const String name = 'LoginRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const LoginPage();
    },
  );
}

/// generated route for
/// [MaintenanceWarrantyScreen]
class MaintenanceWarrantyRoute
    extends PageRouteInfo<MaintenanceWarrantyRouteArgs> {
  MaintenanceWarrantyRoute({
    Key? key,
    required String vehicleId,
    String? natisRc1Url,
    required String maintenanceSelection,
    required String warrantySelection,
    required String requireToSettleType,
    required String vehicleRef,
    required String makeModel,
    required String mainImageUrl,
    List<PageRouteInfo>? children,
  }) : super(
          MaintenanceWarrantyRoute.name,
          args: MaintenanceWarrantyRouteArgs(
            key: key,
            vehicleId: vehicleId,
            natisRc1Url: natisRc1Url,
            maintenanceSelection: maintenanceSelection,
            warrantySelection: warrantySelection,
            requireToSettleType: requireToSettleType,
            vehicleRef: vehicleRef,
            makeModel: makeModel,
            mainImageUrl: mainImageUrl,
          ),
          initialChildren: children,
        );

  static const String name = 'MaintenanceWarrantyRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<MaintenanceWarrantyRouteArgs>();
      return MaintenanceWarrantyScreen(
        key: args.key,
        vehicleId: args.vehicleId,
        natisRc1Url: args.natisRc1Url,
        maintenanceSelection: args.maintenanceSelection,
        warrantySelection: args.warrantySelection,
        requireToSettleType: args.requireToSettleType,
        vehicleRef: args.vehicleRef,
        makeModel: args.makeModel,
        mainImageUrl: args.mainImageUrl,
      );
    },
  );
}

class MaintenanceWarrantyRouteArgs {
  const MaintenanceWarrantyRouteArgs({
    this.key,
    required this.vehicleId,
    this.natisRc1Url,
    required this.maintenanceSelection,
    required this.warrantySelection,
    required this.requireToSettleType,
    required this.vehicleRef,
    required this.makeModel,
    required this.mainImageUrl,
  });

  final Key? key;

  final String vehicleId;

  final String? natisRc1Url;

  final String maintenanceSelection;

  final String warrantySelection;

  final String requireToSettleType;

  final String vehicleRef;

  final String makeModel;

  final String mainImageUrl;

  @override
  String toString() {
    return 'MaintenanceWarrantyRouteArgs{key: $key, vehicleId: $vehicleId, natisRc1Url: $natisRc1Url, maintenanceSelection: $maintenanceSelection, warrantySelection: $warrantySelection, requireToSettleType: $requireToSettleType, vehicleRef: $vehicleRef, makeModel: $makeModel, mainImageUrl: $mainImageUrl}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! MaintenanceWarrantyRouteArgs) return false;
    return key == other.key &&
        vehicleId == other.vehicleId &&
        natisRc1Url == other.natisRc1Url &&
        maintenanceSelection == other.maintenanceSelection &&
        warrantySelection == other.warrantySelection &&
        requireToSettleType == other.requireToSettleType &&
        vehicleRef == other.vehicleRef &&
        makeModel == other.makeModel &&
        mainImageUrl == other.mainImageUrl;
  }

  @override
  int get hashCode =>
      key.hashCode ^
      vehicleId.hashCode ^
      natisRc1Url.hashCode ^
      maintenanceSelection.hashCode ^
      warrantySelection.hashCode ^
      requireToSettleType.hashCode ^
      vehicleRef.hashCode ^
      makeModel.hashCode ^
      mainImageUrl.hashCode;
}

/// generated route for
/// [OTPScreen]
class OTPRoute extends PageRouteInfo<void> {
  const OTPRoute({List<PageRouteInfo>? children})
      : super(OTPRoute.name, initialChildren: children);

  static const String name = 'OTPRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const OTPScreen();
    },
  );
}

/// generated route for
/// [OfferDetailPage]
class OfferDetailRoute extends PageRouteInfo<OfferDetailRouteArgs> {
  OfferDetailRoute({
    Key? key,
    required Offer offer,
    List<PageRouteInfo>? children,
  }) : super(
          OfferDetailRoute.name,
          args: OfferDetailRouteArgs(key: key, offer: offer),
          initialChildren: children,
        );

  static const String name = 'OfferDetailRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<OfferDetailRouteArgs>();
      return OfferDetailPage(key: args.key, offer: args.offer);
    },
  );
}

class OfferDetailRouteArgs {
  const OfferDetailRouteArgs({this.key, required this.offer});

  final Key? key;

  final Offer offer;

  @override
  String toString() {
    return 'OfferDetailRouteArgs{key: $key, offer: $offer}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! OfferDetailRouteArgs) return false;
    return key == other.key && offer == other.offer;
  }

  @override
  int get hashCode => key.hashCode ^ offer.hashCode;
}

/// generated route for
/// [OfferDetailsPage]
class OfferDetailsRoute extends PageRouteInfo<OfferDetailsRouteArgs> {
  OfferDetailsRoute({
    Key? key,
    required String offerId,
    required String vehicleName,
    required String offerAmount,
    required List<String> images,
    required Map<String, String?> additionalInfo,
    required Future<void> Function() onAccept,
    required Future<void> Function() onReject,
    required String offerStatus,
    String? year,
    String? mileage,
    String? transmission,
    List<PageRouteInfo>? children,
  }) : super(
          OfferDetailsRoute.name,
          args: OfferDetailsRouteArgs(
            key: key,
            offerId: offerId,
            vehicleName: vehicleName,
            offerAmount: offerAmount,
            images: images,
            additionalInfo: additionalInfo,
            onAccept: onAccept,
            onReject: onReject,
            offerStatus: offerStatus,
            year: year,
            mileage: mileage,
            transmission: transmission,
          ),
          initialChildren: children,
        );

  static const String name = 'OfferDetailsRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<OfferDetailsRouteArgs>();
      return OfferDetailsPage(
        key: args.key,
        offerId: args.offerId,
        vehicleName: args.vehicleName,
        offerAmount: args.offerAmount,
        images: args.images,
        additionalInfo: args.additionalInfo,
        onAccept: args.onAccept,
        onReject: args.onReject,
        offerStatus: args.offerStatus,
        year: args.year,
        mileage: args.mileage,
        transmission: args.transmission,
      );
    },
  );
}

class OfferDetailsRouteArgs {
  const OfferDetailsRouteArgs({
    this.key,
    required this.offerId,
    required this.vehicleName,
    required this.offerAmount,
    required this.images,
    required this.additionalInfo,
    required this.onAccept,
    required this.onReject,
    required this.offerStatus,
    this.year,
    this.mileage,
    this.transmission,
  });

  final Key? key;

  final String offerId;

  final String vehicleName;

  final String offerAmount;

  final List<String> images;

  final Map<String, String?> additionalInfo;

  final Future<void> Function() onAccept;

  final Future<void> Function() onReject;

  final String offerStatus;

  final String? year;

  final String? mileage;

  final String? transmission;

  @override
  String toString() {
    return 'OfferDetailsRouteArgs{key: $key, offerId: $offerId, vehicleName: $vehicleName, offerAmount: $offerAmount, images: $images, additionalInfo: $additionalInfo, onAccept: $onAccept, onReject: $onReject, offerStatus: $offerStatus, year: $year, mileage: $mileage, transmission: $transmission}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! OfferDetailsRouteArgs) return false;
    return key == other.key &&
        offerId == other.offerId &&
        vehicleName == other.vehicleName &&
        offerAmount == other.offerAmount &&
        const ListEquality().equals(images, other.images) &&
        const MapEquality().equals(additionalInfo, other.additionalInfo) &&
        offerStatus == other.offerStatus &&
        year == other.year &&
        mileage == other.mileage &&
        transmission == other.transmission;
  }

  @override
  int get hashCode =>
      key.hashCode ^
      offerId.hashCode ^
      vehicleName.hashCode ^
      offerAmount.hashCode ^
      const ListEquality().hash(images) ^
      const MapEquality().hash(additionalInfo) ^
      offerStatus.hashCode ^
      year.hashCode ^
      mileage.hashCode ^
      transmission.hashCode;
}

/// generated route for
/// [OfferSummaryPage]
class OfferSummaryRoute extends PageRouteInfo<OfferSummaryRouteArgs> {
  OfferSummaryRoute({
    Key? key,
    required String offerId,
    List<PageRouteInfo>? children,
  }) : super(
          OfferSummaryRoute.name,
          args: OfferSummaryRouteArgs(key: key, offerId: offerId),
          initialChildren: children,
        );

  static const String name = 'OfferSummaryRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<OfferSummaryRouteArgs>();
      return OfferSummaryPage(key: args.key, offerId: args.offerId);
    },
  );
}

class OfferSummaryRouteArgs {
  const OfferSummaryRouteArgs({this.key, required this.offerId});

  final Key? key;

  final String offerId;

  @override
  String toString() {
    return 'OfferSummaryRouteArgs{key: $key, offerId: $offerId}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! OfferSummaryRouteArgs) return false;
    return key == other.key && offerId == other.offerId;
  }

  @override
  int get hashCode => key.hashCode ^ offerId.hashCode;
}

/// generated route for
/// [OffersPage]
class OffersRoute extends PageRouteInfo<void> {
  const OffersRoute({List<PageRouteInfo>? children})
      : super(OffersRoute.name, initialChildren: children);

  static const String name = 'OffersRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const OffersPage();
    },
  );
}

/// generated route for
/// [PaymentApprovedPage]
class PaymentApprovedRoute extends PageRouteInfo<PaymentApprovedRouteArgs> {
  PaymentApprovedRoute({
    Key? key,
    required String offerId,
    List<PageRouteInfo>? children,
  }) : super(
          PaymentApprovedRoute.name,
          args: PaymentApprovedRouteArgs(key: key, offerId: offerId),
          initialChildren: children,
        );

  static const String name = 'PaymentApprovedRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<PaymentApprovedRouteArgs>();
      return PaymentApprovedPage(key: args.key, offerId: args.offerId);
    },
  );
}

class PaymentApprovedRouteArgs {
  const PaymentApprovedRouteArgs({this.key, required this.offerId});

  final Key? key;

  final String offerId;

  @override
  String toString() {
    return 'PaymentApprovedRouteArgs{key: $key, offerId: $offerId}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! PaymentApprovedRouteArgs) return false;
    return key == other.key && offerId == other.offerId;
  }

  @override
  int get hashCode => key.hashCode ^ offerId.hashCode;
}

/// generated route for
/// [PaymentOptionsPage]
class PaymentOptionsRoute extends PageRouteInfo<PaymentOptionsRouteArgs> {
  PaymentOptionsRoute({
    Key? key,
    required String offerId,
    List<PageRouteInfo>? children,
  }) : super(
          PaymentOptionsRoute.name,
          args: PaymentOptionsRouteArgs(key: key, offerId: offerId),
          initialChildren: children,
        );

  static const String name = 'PaymentOptionsRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<PaymentOptionsRouteArgs>();
      return PaymentOptionsPage(key: args.key, offerId: args.offerId);
    },
  );
}

class PaymentOptionsRouteArgs {
  const PaymentOptionsRouteArgs({this.key, required this.offerId});

  final Key? key;

  final String offerId;

  @override
  String toString() {
    return 'PaymentOptionsRouteArgs{key: $key, offerId: $offerId}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! PaymentOptionsRouteArgs) return false;
    return key == other.key && offerId == other.offerId;
  }

  @override
  int get hashCode => key.hashCode ^ offerId.hashCode;
}

/// generated route for
/// [PaymentPendingPage]
class PaymentPendingRoute extends PageRouteInfo<PaymentPendingRouteArgs> {
  PaymentPendingRoute({
    Key? key,
    required String offerId,
    List<PageRouteInfo>? children,
  }) : super(
          PaymentPendingRoute.name,
          args: PaymentPendingRouteArgs(key: key, offerId: offerId),
          initialChildren: children,
        );

  static const String name = 'PaymentPendingRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<PaymentPendingRouteArgs>();
      return PaymentPendingPage(key: args.key, offerId: args.offerId);
    },
  );
}

class PaymentPendingRouteArgs {
  const PaymentPendingRouteArgs({this.key, required this.offerId});

  final Key? key;

  final String offerId;

  @override
  String toString() {
    return 'PaymentPendingRouteArgs{key: $key, offerId: $offerId}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! PaymentPendingRouteArgs) return false;
    return key == other.key && offerId == other.offerId;
  }

  @override
  int get hashCode => key.hashCode ^ offerId.hashCode;
}

/// generated route for
/// [PdfViewerPage]
class PdfViewerRoute extends PageRouteInfo<PdfViewerRouteArgs> {
  PdfViewerRoute({
    Key? key,
    required String pdfUrl,
    List<PageRouteInfo>? children,
  }) : super(
          PdfViewerRoute.name,
          args: PdfViewerRouteArgs(key: key, pdfUrl: pdfUrl),
          initialChildren: children,
        );

  static const String name = 'PdfViewerRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<PdfViewerRouteArgs>();
      return PdfViewerPage(key: args.key, pdfUrl: args.pdfUrl);
    },
  );
}

class PdfViewerRouteArgs {
  const PdfViewerRouteArgs({this.key, required this.pdfUrl});

  final Key? key;

  final String pdfUrl;

  @override
  String toString() {
    return 'PdfViewerRouteArgs{key: $key, pdfUrl: $pdfUrl}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! PdfViewerRouteArgs) return false;
    return key == other.key && pdfUrl == other.pdfUrl;
  }

  @override
  int get hashCode => key.hashCode ^ pdfUrl.hashCode;
}

/// generated route for
/// [PendingOffersPage]
class PendingOffersRoute extends PageRouteInfo<void> {
  const PendingOffersRoute({List<PageRouteInfo>? children})
      : super(PendingOffersRoute.name, initialChildren: children);

  static const String name = 'PendingOffersRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const PendingOffersPage();
    },
  );
}

/// generated route for
/// [PhoneNumberPage]
class PhoneNumberRoute extends PageRouteInfo<void> {
  const PhoneNumberRoute({List<PageRouteInfo>? children})
      : super(PhoneNumberRoute.name, initialChildren: children);

  static const String name = 'PhoneNumberRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const PhoneNumberPage();
    },
  );
}

/// generated route for
/// [PreferredBrandsPage]
class PreferredBrandsRoute extends PageRouteInfo<void> {
  const PreferredBrandsRoute({List<PageRouteInfo>? children})
      : super(PreferredBrandsRoute.name, initialChildren: children);

  static const String name = 'PreferredBrandsRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const PreferredBrandsPage();
    },
  );
}

/// generated route for
/// [ProfilePage]
class ProfileRoute extends PageRouteInfo<ProfileRouteArgs> {
  ProfileRoute({Key? key, List<PageRouteInfo>? children})
      : super(
          ProfileRoute.name,
          args: ProfileRouteArgs(key: key),
          initialChildren: children,
        );

  static const String name = 'ProfileRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<ProfileRouteArgs>(
        orElse: () => const ProfileRouteArgs(),
      );
      return ProfilePage(key: args.key);
    },
  );
}

class ProfileRouteArgs {
  const ProfileRouteArgs({this.key});

  final Key? key;

  @override
  String toString() {
    return 'ProfileRouteArgs{key: $key}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ProfileRouteArgs) return false;
    return key == other.key;
  }

  @override
  int get hashCode => key.hashCode;
}

/// generated route for
/// [RateDealerPage]
class RateDealerRoute extends PageRouteInfo<RateDealerRouteArgs> {
  RateDealerRoute({
    Key? key,
    required String offerId,
    List<PageRouteInfo>? children,
  }) : super(
          RateDealerRoute.name,
          args: RateDealerRouteArgs(key: key, offerId: offerId),
          initialChildren: children,
        );

  static const String name = 'RateDealerRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<RateDealerRouteArgs>();
      return RateDealerPage(key: args.key, offerId: args.offerId);
    },
  );
}

class RateDealerRouteArgs {
  const RateDealerRouteArgs({this.key, required this.offerId});

  final Key? key;

  final String offerId;

  @override
  String toString() {
    return 'RateDealerRouteArgs{key: $key, offerId: $offerId}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! RateDealerRouteArgs) return false;
    return key == other.key && offerId == other.offerId;
  }

  @override
  int get hashCode => key.hashCode ^ offerId.hashCode;
}

/// generated route for
/// [RateDealerPageTwo]
class RateDealerRouteTwo extends PageRouteInfo<RateDealerRouteTwoArgs> {
  RateDealerRouteTwo({
    Key? key,
    required String offerId,
    List<PageRouteInfo>? children,
  }) : super(
          RateDealerRouteTwo.name,
          args: RateDealerRouteTwoArgs(key: key, offerId: offerId),
          initialChildren: children,
        );

  static const String name = 'RateDealerRouteTwo';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<RateDealerRouteTwoArgs>();
      return RateDealerPageTwo(key: args.key, offerId: args.offerId);
    },
  );
}

class RateDealerRouteTwoArgs {
  const RateDealerRouteTwoArgs({this.key, required this.offerId});

  final Key? key;

  final String offerId;

  @override
  String toString() {
    return 'RateDealerRouteTwoArgs{key: $key, offerId: $offerId}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! RateDealerRouteTwoArgs) return false;
    return key == other.key && offerId == other.offerId;
  }

  @override
  int get hashCode => key.hashCode ^ offerId.hashCode;
}

/// generated route for
/// [RateTransporterPage]
class RateTransporterRoute extends PageRouteInfo<RateTransporterRouteArgs> {
  RateTransporterRoute({
    Key? key,
    required String offerId,
    required bool fromCollectionPage,
    List<PageRouteInfo>? children,
  }) : super(
          RateTransporterRoute.name,
          args: RateTransporterRouteArgs(
            key: key,
            offerId: offerId,
            fromCollectionPage: fromCollectionPage,
          ),
          initialChildren: children,
        );

  static const String name = 'RateTransporterRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<RateTransporterRouteArgs>();
      return RateTransporterPage(
        key: args.key,
        offerId: args.offerId,
        fromCollectionPage: args.fromCollectionPage,
      );
    },
  );
}

class RateTransporterRouteArgs {
  const RateTransporterRouteArgs({
    this.key,
    required this.offerId,
    required this.fromCollectionPage,
  });

  final Key? key;

  final String offerId;

  final bool fromCollectionPage;

  @override
  String toString() {
    return 'RateTransporterRouteArgs{key: $key, offerId: $offerId, fromCollectionPage: $fromCollectionPage}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! RateTransporterRouteArgs) return false;
    return key == other.key &&
        offerId == other.offerId &&
        fromCollectionPage == other.fromCollectionPage;
  }

  @override
  int get hashCode =>
      key.hashCode ^ offerId.hashCode ^ fromCollectionPage.hashCode;
}

/// generated route for
/// [RateTransporterPageTwo]
class RateTransporterRouteTwo
    extends PageRouteInfo<RateTransporterRouteTwoArgs> {
  RateTransporterRouteTwo({
    Key? key,
    required String offerId,
    required bool fromCollectionPage,
    List<PageRouteInfo>? children,
  }) : super(
          RateTransporterRouteTwo.name,
          args: RateTransporterRouteTwoArgs(
            key: key,
            offerId: offerId,
            fromCollectionPage: fromCollectionPage,
          ),
          initialChildren: children,
        );

  static const String name = 'RateTransporterRouteTwo';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<RateTransporterRouteTwoArgs>();
      return RateTransporterPageTwo(
        key: args.key,
        offerId: args.offerId,
        fromCollectionPage: args.fromCollectionPage,
      );
    },
  );
}

class RateTransporterRouteTwoArgs {
  const RateTransporterRouteTwoArgs({
    this.key,
    required this.offerId,
    required this.fromCollectionPage,
  });

  final Key? key;

  final String offerId;

  final bool fromCollectionPage;

  @override
  String toString() {
    return 'RateTransporterRouteTwoArgs{key: $key, offerId: $offerId, fromCollectionPage: $fromCollectionPage}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! RateTransporterRouteTwoArgs) return false;
    return key == other.key &&
        offerId == other.offerId &&
        fromCollectionPage == other.fromCollectionPage;
  }

  @override
  int get hashCode =>
      key.hashCode ^ offerId.hashCode ^ fromCollectionPage.hashCode;
}

/// generated route for
/// [ReportIssuePage]
class ReportIssueRoute extends PageRouteInfo<ReportIssueRouteArgs> {
  ReportIssueRoute({
    Key? key,
    required String offerId,
    List<PageRouteInfo>? children,
  }) : super(
          ReportIssueRoute.name,
          args: ReportIssueRouteArgs(key: key, offerId: offerId),
          initialChildren: children,
        );

  static const String name = 'ReportIssueRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<ReportIssueRouteArgs>();
      return ReportIssuePage(key: args.key, offerId: args.offerId);
    },
  );
}

class ReportIssueRouteArgs {
  const ReportIssueRouteArgs({this.key, required this.offerId});

  final Key? key;

  final String offerId;

  @override
  String toString() {
    return 'ReportIssueRouteArgs{key: $key, offerId: $offerId}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ReportIssueRouteArgs) return false;
    return key == other.key && offerId == other.offerId;
  }

  @override
  int get hashCode => key.hashCode ^ offerId.hashCode;
}

/// generated route for
/// [ReportVehicleIssuePage]
class ReportVehicleIssueRoute
    extends PageRouteInfo<ReportVehicleIssueRouteArgs> {
  ReportVehicleIssueRoute({
    Key? key,
    required String vehicleId,
    List<PageRouteInfo>? children,
  }) : super(
          ReportVehicleIssueRoute.name,
          args: ReportVehicleIssueRouteArgs(key: key, vehicleId: vehicleId),
          initialChildren: children,
        );

  static const String name = 'ReportVehicleIssueRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<ReportVehicleIssueRouteArgs>();
      return ReportVehicleIssuePage(key: args.key, vehicleId: args.vehicleId);
    },
  );
}

class ReportVehicleIssueRouteArgs {
  const ReportVehicleIssueRouteArgs({this.key, required this.vehicleId});

  final Key? key;

  final String vehicleId;

  @override
  String toString() {
    return 'ReportVehicleIssueRouteArgs{key: $key, vehicleId: $vehicleId}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ReportVehicleIssueRouteArgs) return false;
    return key == other.key && vehicleId == other.vehicleId;
  }

  @override
  int get hashCode => key.hashCode ^ vehicleId.hashCode;
}

/// generated route for
/// [SetupCollectionPage]
class SetupCollectionRoute extends PageRouteInfo<SetupCollectionRouteArgs> {
  SetupCollectionRoute({
    Key? key,
    required String offerId,
    List<PageRouteInfo>? children,
  }) : super(
          SetupCollectionRoute.name,
          args: SetupCollectionRouteArgs(key: key, offerId: offerId),
          initialChildren: children,
        );

  static const String name = 'SetupCollectionRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<SetupCollectionRouteArgs>();
      return SetupCollectionPage(key: args.key, offerId: args.offerId);
    },
  );
}

class SetupCollectionRouteArgs {
  const SetupCollectionRouteArgs({this.key, required this.offerId});

  final Key? key;

  final String offerId;

  @override
  String toString() {
    return 'SetupCollectionRouteArgs{key: $key, offerId: $offerId}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! SetupCollectionRouteArgs) return false;
    return key == other.key && offerId == other.offerId;
  }

  @override
  int get hashCode => key.hashCode ^ offerId.hashCode;
}

/// generated route for
/// [SetupInspectionPage]
class SetupInspectionRoute extends PageRouteInfo<SetupInspectionRouteArgs> {
  SetupInspectionRoute({
    Key? key,
    required String offerId,
    List<PageRouteInfo>? children,
  }) : super(
          SetupInspectionRoute.name,
          args: SetupInspectionRouteArgs(key: key, offerId: offerId),
          initialChildren: children,
        );

  static const String name = 'SetupInspectionRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<SetupInspectionRouteArgs>();
      return SetupInspectionPage(key: args.key, offerId: args.offerId);
    },
  );
}

class SetupInspectionRouteArgs {
  const SetupInspectionRouteArgs({this.key, required this.offerId});

  final Key? key;

  final String offerId;

  @override
  String toString() {
    return 'SetupInspectionRouteArgs{key: $key, offerId: $offerId}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! SetupInspectionRouteArgs) return false;
    return key == other.key && offerId == other.offerId;
  }

  @override
  int get hashCode => key.hashCode ^ offerId.hashCode;
}

/// generated route for
/// [SignInPage]
class SignInRoute extends PageRouteInfo<void> {
  const SignInRoute({List<PageRouteInfo>? children})
      : super(SignInRoute.name, initialChildren: children);

  static const String name = 'SignInRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const SignInPage();
    },
  );
}

/// generated route for
/// [SignUpPage]
class SignUpRoute extends PageRouteInfo<void> {
  const SignUpRoute({List<PageRouteInfo>? children})
      : super(SignUpRoute.name, initialChildren: children);

  static const String name = 'SignUpRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const SignUpPage();
    },
  );
}

/// generated route for
/// [SoldVehiclesListPage]
class SoldVehiclesListRoute extends PageRouteInfo<void> {
  const SoldVehiclesListRoute({List<PageRouteInfo>? children})
      : super(SoldVehiclesListRoute.name, initialChildren: children);

  static const String name = 'SoldVehiclesListRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const SoldVehiclesListPage();
    },
  );
}

/// generated route for
/// [ThankYouPage]
class ThankYouRoute extends PageRouteInfo<void> {
  const ThankYouRoute({List<PageRouteInfo>? children})
      : super(ThankYouRoute.name, initialChildren: children);

  static const String name = 'ThankYouRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const ThankYouPage();
    },
  );
}

/// generated route for
/// [TradingCategoryPage]
class TradingCategoryRoute extends PageRouteInfo<void> {
  const TradingCategoryRoute({List<PageRouteInfo>? children})
      : super(TradingCategoryRoute.name, initialChildren: children);

  static const String name = 'TradingCategoryRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const TradingCategoryPage();
    },
  );
}

/// generated route for
/// [TradingInterestsPage]
class TradingInterestsRoute extends PageRouteInfo<void> {
  const TradingInterestsRoute({List<PageRouteInfo>? children})
      : super(TradingInterestsRoute.name, initialChildren: children);

  static const String name = 'TradingInterestsRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const TradingInterestsPage();
    },
  );
}

/// generated route for
/// [TransporterRegistrationPage]
class TransporterRegistrationRoute extends PageRouteInfo<void> {
  const TransporterRegistrationRoute({List<PageRouteInfo>? children})
      : super(TransporterRegistrationRoute.name, initialChildren: children);

  static const String name = 'TransporterRegistrationRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const TransporterRegistrationPage();
    },
  );
}

/// generated route for
/// [TruckConditionsTabsEditPage]
class TruckConditionsTabsEditRoute
    extends PageRouteInfo<TruckConditionsTabsEditRouteArgs> {
  TruckConditionsTabsEditRoute({
    Key? key,
    required int initialIndex,
    Uint8List? mainImageFile,
    String? mainImageUrl,
    required String vehicleId,
    required String referenceNumber,
    bool isEditing = false,
    List<PageRouteInfo>? children,
  }) : super(
          TruckConditionsTabsEditRoute.name,
          args: TruckConditionsTabsEditRouteArgs(
            key: key,
            initialIndex: initialIndex,
            mainImageFile: mainImageFile,
            mainImageUrl: mainImageUrl,
            vehicleId: vehicleId,
            referenceNumber: referenceNumber,
            isEditing: isEditing,
          ),
          initialChildren: children,
        );

  static const String name = 'TruckConditionsTabsEditRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<TruckConditionsTabsEditRouteArgs>();
      return TruckConditionsTabsEditPage(
        key: args.key,
        initialIndex: args.initialIndex,
        mainImageFile: args.mainImageFile,
        mainImageUrl: args.mainImageUrl,
        vehicleId: args.vehicleId,
        referenceNumber: args.referenceNumber,
        isEditing: args.isEditing,
      );
    },
  );
}

class TruckConditionsTabsEditRouteArgs {
  const TruckConditionsTabsEditRouteArgs({
    this.key,
    required this.initialIndex,
    this.mainImageFile,
    this.mainImageUrl,
    required this.vehicleId,
    required this.referenceNumber,
    this.isEditing = false,
  });

  final Key? key;

  final int initialIndex;

  final Uint8List? mainImageFile;

  final String? mainImageUrl;

  final String vehicleId;

  final String referenceNumber;

  final bool isEditing;

  @override
  String toString() {
    return 'TruckConditionsTabsEditRouteArgs{key: $key, initialIndex: $initialIndex, mainImageFile: $mainImageFile, mainImageUrl: $mainImageUrl, vehicleId: $vehicleId, referenceNumber: $referenceNumber, isEditing: $isEditing}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! TruckConditionsTabsEditRouteArgs) return false;
    return key == other.key &&
        initialIndex == other.initialIndex &&
        mainImageFile == other.mainImageFile &&
        mainImageUrl == other.mainImageUrl &&
        vehicleId == other.vehicleId &&
        referenceNumber == other.referenceNumber &&
        isEditing == other.isEditing;
  }

  @override
  int get hashCode =>
      key.hashCode ^
      initialIndex.hashCode ^
      mainImageFile.hashCode ^
      mainImageUrl.hashCode ^
      vehicleId.hashCode ^
      referenceNumber.hashCode ^
      isEditing.hashCode;
}

/// generated route for
/// [TruckConditionsTabsPage]
class TruckConditionsTabsRoute
    extends PageRouteInfo<TruckConditionsTabsRouteArgs> {
  TruckConditionsTabsRoute({
    Key? key,
    required int initialIndex,
    File? mainImageFile,
    String? mainImageUrl,
    required String vehicleId,
    bool isEditing = false,
    dynamic formData,
    List<PageRouteInfo>? children,
  }) : super(
          TruckConditionsTabsRoute.name,
          args: TruckConditionsTabsRouteArgs(
            key: key,
            initialIndex: initialIndex,
            mainImageFile: mainImageFile,
            mainImageUrl: mainImageUrl,
            vehicleId: vehicleId,
            isEditing: isEditing,
            formData: formData,
          ),
          initialChildren: children,
        );

  static const String name = 'TruckConditionsTabsRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<TruckConditionsTabsRouteArgs>();
      return TruckConditionsTabsPage(
        key: args.key,
        initialIndex: args.initialIndex,
        mainImageFile: args.mainImageFile,
        mainImageUrl: args.mainImageUrl,
        vehicleId: args.vehicleId,
        isEditing: args.isEditing,
        formData: args.formData,
      );
    },
  );
}

class TruckConditionsTabsRouteArgs {
  const TruckConditionsTabsRouteArgs({
    this.key,
    required this.initialIndex,
    this.mainImageFile,
    this.mainImageUrl,
    required this.vehicleId,
    this.isEditing = false,
    this.formData,
  });

  final Key? key;

  final int initialIndex;

  final File? mainImageFile;

  final String? mainImageUrl;

  final String vehicleId;

  final bool isEditing;

  final dynamic formData;

  @override
  String toString() {
    return 'TruckConditionsTabsRouteArgs{key: $key, initialIndex: $initialIndex, mainImageFile: $mainImageFile, mainImageUrl: $mainImageUrl, vehicleId: $vehicleId, isEditing: $isEditing, formData: $formData}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! TruckConditionsTabsRouteArgs) return false;
    return key == other.key &&
        initialIndex == other.initialIndex &&
        mainImageFile == other.mainImageFile &&
        mainImageUrl == other.mainImageUrl &&
        vehicleId == other.vehicleId &&
        isEditing == other.isEditing &&
        formData == other.formData;
  }

  @override
  int get hashCode =>
      key.hashCode ^
      initialIndex.hashCode ^
      mainImageFile.hashCode ^
      mainImageUrl.hashCode ^
      vehicleId.hashCode ^
      isEditing.hashCode ^
      formData.hashCode;
}

/// generated route for
/// [TruckPage]
class TruckRoute extends PageRouteInfo<TruckRouteArgs> {
  TruckRoute({
    Key? key,
    String? vehicleType,
    String? selectedBrand,
    List<PageRouteInfo>? children,
  }) : super(
          TruckRoute.name,
          args: TruckRouteArgs(
            key: key,
            vehicleType: vehicleType,
            selectedBrand: selectedBrand,
          ),
          initialChildren: children,
        );

  static const String name = 'TruckRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<TruckRouteArgs>(
        orElse: () => const TruckRouteArgs(),
      );
      return TruckPage(
        key: args.key,
        vehicleType: args.vehicleType,
        selectedBrand: args.selectedBrand,
      );
    },
  );
}

class TruckRouteArgs {
  const TruckRouteArgs({this.key, this.vehicleType, this.selectedBrand});

  final Key? key;

  final String? vehicleType;

  final String? selectedBrand;

  @override
  String toString() {
    return 'TruckRouteArgs{key: $key, vehicleType: $vehicleType, selectedBrand: $selectedBrand}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! TruckRouteArgs) return false;
    return key == other.key &&
        vehicleType == other.vehicleType &&
        selectedBrand == other.selectedBrand;
  }

  @override
  int get hashCode =>
      key.hashCode ^ vehicleType.hashCode ^ selectedBrand.hashCode;
}

/// generated route for
/// [TutorialPage]
class TutorialRoute extends PageRouteInfo<void> {
  const TutorialRoute({List<PageRouteInfo>? children})
      : super(TutorialRoute.name, initialChildren: children);

  static const String name = 'TutorialRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const TutorialPage();
    },
  );
}

/// generated route for
/// [TutorialStartedPage]
class TutorialStartedRoute extends PageRouteInfo<void> {
  const TutorialStartedRoute({List<PageRouteInfo>? children})
      : super(TutorialStartedRoute.name, initialChildren: children);

  static const String name = 'TutorialStartedRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const TutorialStartedPage();
    },
  );
}

/// generated route for
/// [TyresEditPage]
class TyresEditRoute extends PageRouteInfo<TyresEditRouteArgs> {
  TyresEditRoute({
    Key? key,
    required String vehicleId,
    required VoidCallback onProgressUpdate,
    bool isEditing = false,
    bool inTabsPage = false,
    List<PageRouteInfo>? children,
  }) : super(
          TyresEditRoute.name,
          args: TyresEditRouteArgs(
            key: key,
            vehicleId: vehicleId,
            onProgressUpdate: onProgressUpdate,
            isEditing: isEditing,
            inTabsPage: inTabsPage,
          ),
          initialChildren: children,
        );

  static const String name = 'TyresEditRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<TyresEditRouteArgs>();
      return TyresEditPage(
        key: args.key,
        vehicleId: args.vehicleId,
        onProgressUpdate: args.onProgressUpdate,
        isEditing: args.isEditing,
        inTabsPage: args.inTabsPage,
      );
    },
  );
}

class TyresEditRouteArgs {
  const TyresEditRouteArgs({
    this.key,
    required this.vehicleId,
    required this.onProgressUpdate,
    this.isEditing = false,
    this.inTabsPage = false,
  });

  final Key? key;

  final String vehicleId;

  final VoidCallback onProgressUpdate;

  final bool isEditing;

  final bool inTabsPage;

  @override
  String toString() {
    return 'TyresEditRouteArgs{key: $key, vehicleId: $vehicleId, onProgressUpdate: $onProgressUpdate, isEditing: $isEditing, inTabsPage: $inTabsPage}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! TyresEditRouteArgs) return false;
    return key == other.key &&
        vehicleId == other.vehicleId &&
        onProgressUpdate == other.onProgressUpdate &&
        isEditing == other.isEditing &&
        inTabsPage == other.inTabsPage;
  }

  @override
  int get hashCode =>
      key.hashCode ^
      vehicleId.hashCode ^
      onProgressUpdate.hashCode ^
      isEditing.hashCode ^
      inTabsPage.hashCode;
}

/// generated route for
/// [TyresPage]
class TyresRoute extends PageRouteInfo<TyresRouteArgs> {
  TyresRoute({
    Key? key,
    required String vehicleId,
    required VoidCallback onProgressUpdate,
    bool isEditing = false,
    required int numberOfTyrePositions,
    List<PageRouteInfo>? children,
  }) : super(
          TyresRoute.name,
          args: TyresRouteArgs(
            key: key,
            vehicleId: vehicleId,
            onProgressUpdate: onProgressUpdate,
            isEditing: isEditing,
            numberOfTyrePositions: numberOfTyrePositions,
          ),
          initialChildren: children,
        );

  static const String name = 'TyresRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<TyresRouteArgs>();
      return TyresPage(
        key: args.key,
        vehicleId: args.vehicleId,
        onProgressUpdate: args.onProgressUpdate,
        isEditing: args.isEditing,
        numberOfTyrePositions: args.numberOfTyrePositions,
      );
    },
  );
}

class TyresRouteArgs {
  const TyresRouteArgs({
    this.key,
    required this.vehicleId,
    required this.onProgressUpdate,
    this.isEditing = false,
    required this.numberOfTyrePositions,
  });

  final Key? key;

  final String vehicleId;

  final VoidCallback onProgressUpdate;

  final bool isEditing;

  final int numberOfTyrePositions;

  @override
  String toString() {
    return 'TyresRouteArgs{key: $key, vehicleId: $vehicleId, onProgressUpdate: $onProgressUpdate, isEditing: $isEditing, numberOfTyrePositions: $numberOfTyrePositions}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! TyresRouteArgs) return false;
    return key == other.key &&
        vehicleId == other.vehicleId &&
        onProgressUpdate == other.onProgressUpdate &&
        isEditing == other.isEditing &&
        numberOfTyrePositions == other.numberOfTyrePositions;
  }

  @override
  int get hashCode =>
      key.hashCode ^
      vehicleId.hashCode ^
      onProgressUpdate.hashCode ^
      isEditing.hashCode ^
      numberOfTyrePositions.hashCode;
}

/// generated route for
/// [UploadProofOfPaymentPage]
class UploadProofOfPaymentRoute
    extends PageRouteInfo<UploadProofOfPaymentRouteArgs> {
  UploadProofOfPaymentRoute({
    Key? key,
    required String offerId,
    List<PageRouteInfo>? children,
  }) : super(
          UploadProofOfPaymentRoute.name,
          args: UploadProofOfPaymentRouteArgs(key: key, offerId: offerId),
          initialChildren: children,
        );

  static const String name = 'UploadProofOfPaymentRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<UploadProofOfPaymentRouteArgs>();
      return UploadProofOfPaymentPage(key: args.key, offerId: args.offerId);
    },
  );
}

class UploadProofOfPaymentRouteArgs {
  const UploadProofOfPaymentRouteArgs({this.key, required this.offerId});

  final Key? key;

  final String offerId;

  @override
  String toString() {
    return 'UploadProofOfPaymentRouteArgs{key: $key, offerId: $offerId}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! UploadProofOfPaymentRouteArgs) return false;
    return key == other.key && offerId == other.offerId;
  }

  @override
  int get hashCode => key.hashCode ^ offerId.hashCode;
}

/// generated route for
/// [UserDetailPage]
class UserDetailRoute extends PageRouteInfo<UserDetailRouteArgs> {
  UserDetailRoute({
    Key? key,
    required String userId,
    List<PageRouteInfo>? children,
  }) : super(
          UserDetailRoute.name,
          args: UserDetailRouteArgs(key: key, userId: userId),
          initialChildren: children,
        );

  static const String name = 'UserDetailRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<UserDetailRouteArgs>();
      return UserDetailPage(key: args.key, userId: args.userId);
    },
  );
}

class UserDetailRouteArgs {
  const UserDetailRouteArgs({this.key, required this.userId});

  final Key? key;

  final String userId;

  @override
  String toString() {
    return 'UserDetailRouteArgs{key: $key, userId: $userId}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! UserDetailRouteArgs) return false;
    return key == other.key && userId == other.userId;
  }

  @override
  int get hashCode => key.hashCode ^ userId.hashCode;
}

/// generated route for
/// [VehiclesListPage]
class VehiclesListRoute extends PageRouteInfo<void> {
  const VehiclesListRoute({List<PageRouteInfo>? children})
      : super(VehiclesListRoute.name, initialChildren: children);

  static const String name = 'VehiclesListRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const VehiclesListPage();
    },
  );
}

/// generated route for
/// [ViewerPage]
class ViewerRoute extends PageRouteInfo<ViewerRouteArgs> {
  ViewerRoute({Key? key, required String url, List<PageRouteInfo>? children})
      : super(
          ViewerRoute.name,
          args: ViewerRouteArgs(key: key, url: url),
          initialChildren: children,
        );

  static const String name = 'ViewerRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<ViewerRouteArgs>();
      return ViewerPage(key: args.key, url: args.url);
    },
  );
}

class ViewerRouteArgs {
  const ViewerRouteArgs({this.key, required this.url});

  final Key? key;

  final String url;

  @override
  String toString() {
    return 'ViewerRouteArgs{key: $key, url: $url}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ViewerRouteArgs) return false;
    return key == other.key && url == other.url;
  }

  @override
  int get hashCode => key.hashCode ^ url.hashCode;
}

/// generated route for
/// [WishlistOffersPage]
class WishlistOffersRoute extends PageRouteInfo<void> {
  const WishlistOffersRoute({List<PageRouteInfo>? children})
      : super(WishlistOffersRoute.name, initialChildren: children);

  static const String name = 'WishlistOffersRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const WishlistOffersPage();
    },
  );
}

/// generated route for
/// [WishlistPage]
class WishlistRoute extends PageRouteInfo<void> {
  const WishlistRoute({List<PageRouteInfo>? children})
      : super(WishlistRoute.name, initialChildren: children);

  static const String name = 'WishlistRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const WishlistPage();
    },
  );
}
