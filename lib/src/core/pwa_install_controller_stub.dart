import 'package:flutter/foundation.dart';

class PwaInstallController extends ChangeNotifier {
  bool get canInstall => false;

  Future<void> initialize() async {}

  Future<void> promptInstall() async {}
}
