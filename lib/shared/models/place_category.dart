import 'package:flutter/material.dart';

/// Category for a place.
enum PlaceCategory {
  restaurant,
  cafe,
  hospital,
  clinic,
  park,
  mall,
  college,
  governmentOffice,
  hotel,
  touristAttraction,
  communityCenter,
  repairSupport;

  String get displayName {
    switch (this) {
      case PlaceCategory.restaurant:
        return 'Restaurant';
      case PlaceCategory.cafe:
        return 'Cafe';
      case PlaceCategory.hospital:
        return 'Hospital';
      case PlaceCategory.clinic:
        return 'Clinic';
      case PlaceCategory.park:
        return 'Park';
      case PlaceCategory.mall:
        return 'Shopping Mall';
      case PlaceCategory.college:
        return 'College';
      case PlaceCategory.governmentOffice:
        return 'Government Office';
      case PlaceCategory.hotel:
        return 'Hotel';
      case PlaceCategory.touristAttraction:
        return 'Tourist Attraction';
      case PlaceCategory.communityCenter:
        return 'Community Center';
      case PlaceCategory.repairSupport:
        return 'Repair & Support';
    }
  }

  IconData get icon {
    switch (this) {
      case PlaceCategory.restaurant:
        return Icons.restaurant;
      case PlaceCategory.cafe:
        return Icons.coffee;
      case PlaceCategory.hospital:
        return Icons.local_hospital;
      case PlaceCategory.clinic:
        return Icons.medical_services;
      case PlaceCategory.park:
        return Icons.park;
      case PlaceCategory.mall:
        return Icons.shopping_bag;
      case PlaceCategory.college:
        return Icons.school;
      case PlaceCategory.governmentOffice:
        return Icons.account_balance;
      case PlaceCategory.hotel:
        return Icons.hotel;
      case PlaceCategory.touristAttraction:
        return Icons.camera_alt;
      case PlaceCategory.communityCenter:
        return Icons.groups;
      case PlaceCategory.repairSupport:
        return Icons.build;
    }
  }
}
