import 'package:flutter/material.dart';

/// Semantic icon names kept behind one wrapper so the icon family can be
/// changed without touching feature screens.
///
/// Material Icons are used because the archived Phosphor package extends
/// Flutter's now-final [IconData] class and cannot compile on current Flutter.
// ignore_for_file: constant_identifier_names
class AppIcons {
  const AppIcons._();

  // Navigation (outlined = unselected, filled = selected)
  static const IconData dashboard_outlined = Icons.home_outlined;
  static const IconData dashboard_rounded = Icons.home_rounded;
  static const IconData terrain_outlined = Icons.landscape_outlined;
  static const IconData terrain_rounded = Icons.landscape_rounded;
  static const IconData account_balance_wallet_outlined =
      Icons.account_balance_wallet_outlined;
  static const IconData account_balance_wallet_rounded =
      Icons.account_balance_wallet_rounded;
  static const IconData earn_outlined = Icons.trending_up_outlined;
  static const IconData earn_rounded = Icons.trending_up_rounded;

  // Actions & affordances
  static const IconData settings_outlined = Icons.settings_outlined;
  static const IconData back = Icons.arrow_back_ios_new_rounded;
  static const IconData language = Icons.language;
  static const IconData chevron_right = Icons.chevron_right;
  static const IconData refresh = Icons.refresh;
  static const IconData open_in_new = Icons.open_in_new;
  static const IconData logout = Icons.logout;
  static const IconData copy_rounded = Icons.copy_rounded;
  static const IconData download_outlined = Icons.download_outlined;
  static const IconData add_circle_outline = Icons.add_circle_outline;
  static const IconData search_off_outlined = Icons.search_off_outlined;

  // Transfers
  static const IconData south_west = Icons.south_west; // receive
  static const IconData north_east = Icons.north_east; // send

  // Status & meta
  static const IconData verified_outlined = Icons.verified_outlined;
  static const IconData info_outline = Icons.info_outline;
  static const IconData cloud_off_outlined = Icons.cloud_off_outlined;
  static const IconData inbox_outlined = Icons.inbox_outlined;
  static const IconData check_circle = Icons.check_circle;
  static const IconData circle_outlined = Icons.circle_outlined;
  static const IconData pie_chart_outline = Icons.pie_chart_outline;

  // Domain
  static const IconData token_outlined = Icons.paid_outlined;
  static const IconData place_outlined = Icons.place_outlined;
  static const IconData diamond_outlined = Icons.diamond_outlined;
  static const IconData tag = Icons.tag;

  // Earn (planned staking / farming capabilities)
  static const IconData staking = Icons.lock_outline;
  static const IconData farming = Icons.eco_outlined;
  static const IconData notify = Icons.notifications_none;
  static const IconData kyc = Icons.verified_user_outlined;
  static const IconData listing = Icons.rocket_launch_outlined;
}
