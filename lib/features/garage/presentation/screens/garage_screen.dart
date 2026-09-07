import 'package:flutter/material.dart';
import '../../../vehicle/presentation/pages/garage_page.dart';

/// Legacy GarageScreen forwarding to the new clean architecture GaragePage
class GarageScreen extends StatelessWidget {
  const GarageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const GaragePage();
  }
}
