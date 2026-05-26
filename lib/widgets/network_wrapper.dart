import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'no_network_widget.dart';

class NetworkWrapper extends StatefulWidget {
  final Widget child;

  const NetworkWrapper({super.key, required this.child});

  @override
  State<NetworkWrapper> createState() => _NetworkWrapperState();
}

class _NetworkWrapperState extends State<NetworkWrapper> {
  bool hasConnection = true;
  late StreamSubscription subscription;

  @override
  void initState() {
    super.initState();
    _checkConnection();
    subscription =
        Connectivity().onConnectivityChanged.listen((result) {
      setState(() {
        hasConnection = result != ConnectivityResult.none;
      });
    });
  }

  Future<void> _checkConnection() async {
    var result = await Connectivity().checkConnectivity();
    setState(() {
      hasConnection = result != ConnectivityResult.none;
    });
  }

  @override
  void dispose() {
    subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!hasConnection) {
      return NoNetworkWidget(onRetry: _checkConnection);
    }
    return widget.child;
  }
}
