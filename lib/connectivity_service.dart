import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'sync_service.dart';

class ConnectivityService {
  static void startListening() {
    Connectivity().onConnectivityChanged.listen((result) async {
      if (result != ConnectivityResult.none) {
        debugPrint("Internet connected → auto sync");

        // 🔥 USE THIS
        // SyncService.syncAll();
        await SyncService.syncAll();
      }
    });
  }
}