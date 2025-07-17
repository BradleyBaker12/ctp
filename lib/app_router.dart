import 'dart:io';

import 'package:auto_route/auto_route.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ctp/adminScreens/admin_fleets_page.dart';
import 'package:ctp/adminScreens/complaint_detail_page.dart';
import 'package:ctp/adminScreens/create_fleet_page.dart';
import 'package:ctp/adminScreens/fleet_detail_page.dart';
import 'package:ctp/adminScreens/fleets_management_page.dart';
import 'package:ctp/adminScreens/local_viewer_page.dart';
import 'package:ctp/adminScreens/offer_details_page.dart';
import 'package:ctp/adminScreens/user_detail_page.dart';
import 'package:ctp/adminScreens/viewer_page.dart';
import 'package:ctp/models/trailer.dart';
import 'package:ctp/pages/accepted_offers.dart';
import 'package:ctp/pages/add_profile_photo.dart';
import 'package:ctp/pages/add_profile_photo_admin_page.dart';
import 'package:ctp/pages/add_profile_photo_transporter.dart';
import 'package:ctp/pages/adjust_offer.dart';
import 'package:ctp/pages/admin_home_page.dart';
import 'package:ctp/pages/bought_vehicles_list.dart';
import 'package:ctp/pages/bulk_offer_details_page.dart';
import 'package:ctp/pages/bulk_offer_page.dart';
import 'package:ctp/pages/collect_vehcile.dart';
import 'package:ctp/pages/collectionPages/collection_confirmationPage.dart';
import 'package:ctp/pages/collectionPages/collection_details_page.dart';
import 'package:ctp/pages/crop_photo_page.dart';
import 'package:ctp/pages/dealer_reg.dart';
import 'package:ctp/pages/document_preview_screen.dart';
import 'package:ctp/pages/editTruckForms/chassis_edit_page.dart';
import 'package:ctp/pages/editTruckForms/drive_train_edit_page.dart';
import 'package:ctp/pages/editTruckForms/external_cab_edit_page.dart';
import 'package:ctp/pages/editTruckForms/internal_cab_edit_page.dart';
import 'package:ctp/pages/editTruckForms/truck_conditions_tabs_edit_page.dart';
import 'package:ctp/pages/editTruckForms/tyres_edit_page.dart';
import 'package:ctp/pages/edit_profile_page.dart';
import 'package:ctp/pages/error_page.dart';
import 'package:ctp/pages/first_name_page.dart';
import 'package:ctp/pages/home_page.dart';
import 'package:ctp/pages/house_rules_page.dart';
import 'package:ctp/pages/inspectionPages/confirmation_page.dart';
import 'package:ctp/pages/inspectionPages/final_inspection_approval_page.dart';
import 'package:ctp/pages/inspectionPages/inspection_details_page.dart';
import 'package:ctp/pages/inspectionPages/location_confirmation_page.dart';
import 'package:ctp/pages/login.dart';
import 'package:ctp/pages/offer_details_page.dart';
import 'package:ctp/pages/offer_summary_page.dart';
import 'package:ctp/pages/offersPage.dart';
import 'package:ctp/pages/otp_page.dart';
import 'package:ctp/pages/payment_approved.dart';
import 'package:ctp/pages/payment_options_page.dart';
import 'package:ctp/pages/payment_pending_page.dart';
import 'package:ctp/pages/pdf_viewer_page.dart';
import 'package:ctp/pages/pending_offers_page.dart';
import 'package:ctp/pages/phone_number_page.dart';
import 'package:ctp/pages/prefered_brands.dart';
import 'package:ctp/pages/profile_page.dart';
import 'package:ctp/pages/rating_pages/rate_dealer_page.dart';
import 'package:ctp/pages/rating_pages/rate_dealer_page_two.dart';
import 'package:ctp/pages/rating_pages/rate_transporter_page.dart';
import 'package:ctp/pages/rating_pages/rate_transporter_page_two.dart';
import 'package:ctp/pages/report_issue.dart';
import 'package:ctp/pages/report_vehicle_issue.dart';
import 'package:ctp/pages/setup_collection.dart';
import 'package:ctp/pages/setup_inspection.dart';
import 'package:ctp/pages/sign_in_page.dart';
import 'package:ctp/pages/signup_page.dart';
import 'package:ctp/pages/sold_vehicles_list.dart';
import 'package:ctp/pages/thank_you_page.dart';
import 'package:ctp/pages/trading_category_page.dart';
import 'package:ctp/pages/trading_intrests_page.dart';
import 'package:ctp/pages/trailerForms/edit_trailer_upload_screen.dart';
import 'package:ctp/pages/trailerForms/trailer_upload_screen.dart';
import 'package:ctp/pages/transport_offer_details_page.dart';
import 'package:ctp/pages/transporter_reg.dart';
import 'package:ctp/pages/truckForms/chassis_page.dart';
import 'package:ctp/pages/truckForms/drive_train_page.dart';
import 'package:ctp/pages/truckForms/external_cab_page.dart';
import 'package:ctp/pages/truckForms/internal_cab_page.dart';
import 'package:ctp/pages/truckForms/maintenance_warrenty_screen.dart';
import 'package:ctp/pages/truckForms/truck_conditions_tabs_page.dart';
import 'package:ctp/pages/truckForms/tyres_page.dart';
import 'package:ctp/pages/truckForms/vehilce_upload_screen.dart';
import 'package:ctp/pages/truck_page.dart';
import 'package:ctp/pages/tutorial_page.dart';
import 'package:ctp/pages/tutorial_started.dart';
import 'package:ctp/pages/upload_pop.dart';
import 'package:ctp/pages/vehicle_details_page.dart';
import 'package:ctp/pages/vehicles_list.dart';
import 'package:ctp/pages/waiting_for_approval.dart';
import 'package:ctp/pages/wish_list_page.dart';
import 'package:ctp/pages/wishlist_offers_page.dart';
import 'package:ctp/providers/complaints_provider.dart';
import 'package:ctp/providers/offer_provider.dart';
import 'package:ctp/providers/vehicle_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:collection/collection.dart';
part 'app_router.gr.dart';

@AutoRouterConfig()
class AppRouter extends RootStackRouter {
  @override
  RouteType get defaultRouteType => RouteType.material();

  @override
  List<AutoRoute> get routes => [
        AutoRoute(page: AcceptedOffersRoute.page),
        AutoRoute(page: AccountStatusRoute.page),
        AutoRoute(page: AddProfilePhotoAdminRoute.page),
        AutoRoute(page: AddProfilePhotoRoute.page),
        // AutoRoute(page: AddProfilePhotoRouteTransporterRoute.page),
        AutoRoute(page: AdjustOfferRoute.page),
        AutoRoute(page: AdminFleetsRoute.page),
        AutoRoute(page: AdminHomeRoute.page),
        AutoRoute(page: BoughtVehiclesListRoute.page),
        AutoRoute(page: BulkOfferRoute.page),
        AutoRoute(page: ChassisEditRoute.page),
        AutoRoute(page: ChassisRoute.page),
        AutoRoute(page: CollectVehicleRoute.page),
        AutoRoute(page: CollectionConfirmationRoute.page),
        AutoRoute(page: CollectionDetailsRoute.page),
        AutoRoute(page: ComplaintDetailRoute.page),
        AutoRoute(page: ConfirmationRoute.page),
        AutoRoute(page: CreateFleetRoute.page),
        AutoRoute(page: CropPhotoRoute.page),
        AutoRoute(page: DealerRegRoute.page),
        AutoRoute(page: DocumentPreviewRoute.page),
        AutoRoute(page: DriveTrainEditRoute.page),
        AutoRoute(page: DriveTrainRoute.page),
        AutoRoute(page: EditProfileRoute.page),
        AutoRoute(page: ErrorRoute.page),
        AutoRoute(page: ExternalCabEditRoute.page),
        AutoRoute(page: ExternalCabRoute.page),
        AutoRoute(page: FinalInspectionApprovalRoute.page),
        AutoRoute(page: FirstNameRoute.page),
        AutoRoute(page: FleetDetailRoute.page),
        AutoRoute(page: FleetsManagementRoute.page),
        AutoRoute(page: HomeRoute.page),
        AutoRoute(page: HouseRulesRoute.page),
        AutoRoute(page: InspectionDetailsRoute.page),
        AutoRoute(page: InternalCabEditRoute.page),
        AutoRoute(page: InternalCabRoute.page),
        AutoRoute(page: LocalViewerRoute.page),
        AutoRoute(page: LocationConfirmationRoute.page),
        AutoRoute(page: LoginRoute.page),
        AutoRoute(page: MaintenanceWarrantyRoute.page),
        AutoRoute(page: OTPRoute.page),
        AutoRoute(page: OfferDetailRoute.page),
        AutoRoute(page: OfferDetailsRoute.page),
        AutoRoute(page: PendingOffersRoute.page),
        AutoRoute(page: PaymentApprovedRoute.page),
        AutoRoute(page: PaymentOptionsRoute.page),
        AutoRoute(page: PaymentPendingRoute.page),
        AutoRoute(page: PdfViewerRoute.page),
        AutoRoute(page: ProfileRoute.page),
        AutoRoute(page: RateDealerRoute.page),
        AutoRoute(page: RateTransporterRoute.page),
        AutoRoute(page: ReportIssueRoute.page),
        AutoRoute(page: ReportVehicleIssueRoute.page),
        AutoRoute(page: SetupCollectionRoute.page),
        AutoRoute(page: SetupInspectionRoute.page),
        AutoRoute(page: SignInRoute.page),
        AutoRoute(page: SoldVehiclesListRoute.page),
        AutoRoute(page: ThankYouRoute.page),
        AutoRoute(page: TradingCategoryRoute.page),
        AutoRoute(page: TradingInterestsRoute.page),
        // AutoRoute(page: TrailerUploadRoute.page),
        // AutoRoute(page: EditTrailerUploadRoute.page),
        // AutoRoute(page: TransportOfferDetailsRoute.page),
        // AutoRoute(page: TransporterRegRoute.page),
        // AutoRoute(page: TruckPageRoute.page),
        AutoRoute(page: TutorialRoute.page),
        AutoRoute(page: TutorialStartedRoute.page),
        // AutoRoute(page: UploadPopRoute.page),
        // AutoRoute(page: VehicleDetailsRoute.page),
        AutoRoute(page: VehiclesListRoute.page),
        // AutoRoute(page: WaitingForApprovalRoute.page),
        // AutoRoute(page: WishListRoute.page),
        AutoRoute(page: WishlistOffersRoute.page),
      ];
}
