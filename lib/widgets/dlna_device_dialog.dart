import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:optic_tv/services/dlna_service.dart';
import 'package:dlna_dart/dlna.dart';
import 'dart:ui';

class DlnaDeviceDialog extends ConsumerStatefulWidget {
  const DlnaDeviceDialog({super.key});

  @override
  ConsumerState<DlnaDeviceDialog> createState() => _DlnaDeviceDialogState();
}

class _DlnaDeviceDialogState extends ConsumerState<DlnaDeviceDialog> {
  @override
  void initState() {
    super.initState();
    // Start discovery when dialog opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(dlnaServiceProvider).startDiscovery();
    });
  }

  @override
  void dispose() {
    // Stop discovery when closed
    ref.read(dlnaServiceProvider).stopDiscovery();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dlna = ref.watch(dlnaServiceProvider);

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            width: 400,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A24).withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.cast_connected_rounded, color: Theme.of(context).primaryColor, size: 28),
                    const SizedBox(width: 12),
                    const Text(
                      'Cast to TV',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white54),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Select a Smart TV on your local network to cast the current video.',
                  style: TextStyle(color: Colors.white60, fontSize: 14),
                ),
                const SizedBox(height: 24),

                ValueListenableBuilder<bool>(
                  valueListenable: dlna.isSearching,
                  builder: (context, isSearching, child) {
                    return ValueListenableBuilder<List<DLNADevice>>(
                      valueListenable: dlna.devicesNotifier,
                      builder: (context, devices, child) {
                        if (devices.isEmpty && isSearching) {
                          return Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 40),
                              child: CircularProgressIndicator(color: Theme.of(context).primaryColor),
                            ),
                          );
                        }

                        if (devices.isEmpty && !isSearching) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 30),
                              child: Column(
                                children: [
                                  const Icon(Icons.tv_off_rounded, color: Colors.white30, size: 48),
                                  const SizedBox(height: 12),
                                  const Text('No devices found.', style: TextStyle(color: Colors.white60)),
                                  const SizedBox(height: 16),
                                  TextButton.icon(
                                    onPressed: () => dlna.startDiscovery(),
                                    icon: Icon(Icons.refresh_rounded, color: Theme.of(context).primaryColor),
                                    label: Text('Rescan', style: TextStyle(color: Theme.of(context).primaryColor)),
                                  )
                                ],
                              ),
                            ),
                          );
                        }

                        return ListView.builder(
                          shrinkWrap: true,
                          itemCount: devices.length,
                          itemBuilder: (context, index) {
                            final device = devices[index];
                            final isConnected = dlna.connectedDeviceName == device.info.friendlyName;

                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Icon(
                                isConnected ? Icons.cast_connected_rounded : Icons.tv_rounded,
                                color: isConnected ? Theme.of(context).primaryColor : Colors.white70,
                              ),
                              title: Text(
                                device.info.friendlyName,
                                style: TextStyle(
                                  color: isConnected ? Theme.of(context).primaryColor : Colors.white,
                                  fontWeight: isConnected ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                              trailing: isConnected
                                  ? TextButton(
                                      onPressed: () {
                                        dlna.stopCasting();
                                        dlna.disconnect();
                                        setState(() {});
                                      },
                                      child: const Text('Disconnect', style: TextStyle(color: Colors.redAccent)),
                                    )
                                  : ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Theme.of(context).primaryColor,
                                        foregroundColor: Colors.black,
                                      ),
                                      onPressed: () {
                                        dlna.connect(device);
                                        Navigator.of(context).pop(true);
                                      },
                                      child: const Text('Connect'),
                                    ),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
