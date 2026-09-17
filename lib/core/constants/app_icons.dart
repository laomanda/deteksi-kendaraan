import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// RideCare Icon System (Single Source of Truth: DESIGN.md)
///
/// Guidelines:
/// 1. [HugeIcons] -> Domain Automotive, Kendaraan, Maintenance, Sparepart, Telemetry
///    Used via: `HugeIcon(icon: AppIcons.motorcycle, color: AppColors.primary)`
/// 2. [LucideIcons] -> Navigation, General Utility, Action, Settings, Edit, Delete
///    Used via: `Icon(AppIcons.navHome, color: AppColors.primary)`
class AppIcons {
  AppIcons._();

  // ==========================================
  // 1. AUTOMOTIVE & VEHICLE (HugeIcons)
  // ==========================================
  static const dynamic motorcycle = HugeIcons.strokeRoundedMotorbike01;
  static const dynamic car = HugeIcons.strokeRoundedCar01;
  static const dynamic scooter = HugeIcons.strokeRoundedMotorbike02;
  static const dynamic garage = HugeIcons.strokeRoundedHome01;
  static const dynamic speedometer = HugeIcons.strokeRoundedDashboardSquare01;
  static const dynamic engine = HugeIcons.strokeRoundedCpuCharge;
  static const dynamic battery = HugeIcons.strokeRoundedBatteryCharging01;
  static const dynamic oil = HugeIcons.strokeRoundedDroplet;
  static const dynamic service = HugeIcons.strokeRoundedWrench01;
  static const dynamic fuel = HugeIcons.strokeRoundedGasStove;
  static const dynamic distance = HugeIcons.strokeRoundedRoute01;

  // ==========================================
  // 2. UTILITY & NAVIGATION (LucideIcons)
  // ==========================================
  static const IconData navHome = LucideIcons.layoutDashboard;
  static const IconData navGarage = LucideIcons.car;
  static const IconData navMaintenance = LucideIcons.wrench;
  static const IconData navTracking = LucideIcons.navigation;
  static const IconData navSettings = LucideIcons.settings;

  static const IconData add = LucideIcons.plus;
  static const IconData edit = LucideIcons.pencil;
  static const IconData delete = LucideIcons.trash2;
  static const IconData close = LucideIcons.x;
  static const IconData check = LucideIcons.check;
  static const IconData chevronRight = LucideIcons.chevronRight;
  static const IconData chevronDown = LucideIcons.chevronDown;
  static const IconData chevronLeft = LucideIcons.chevronLeft;
  static const IconData search = LucideIcons.search;
  static const IconData filter = LucideIcons.filter;
  static const IconData download = LucideIcons.download;
  static const IconData upload = LucideIcons.upload;
  static const IconData share = LucideIcons.share2;
  static const IconData info = LucideIcons.info;
  static const IconData alertTriangle = LucideIcons.alertTriangle;
  static const IconData alertCircle = LucideIcons.alertCircle;
  static const IconData checkCircle = LucideIcons.checkCircle;
  static const IconData calendar = LucideIcons.calendar;
  static const IconData clock = LucideIcons.clock;
  static const IconData camera = LucideIcons.camera;
  static const IconData refresh = LucideIcons.refreshCw;
}
