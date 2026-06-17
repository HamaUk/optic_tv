import 'dart:io';

/// Enforces strict SSL validation and ignores system HTTP proxies 
/// to prevent packet sniffers like Charles, Fiddler, or HttpCanary 
/// from intercepting Dart network traffic.
class GlobalSecurityHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client = super.createHttpClient(context);
    
    // Force the client to ignore the system proxy completely
    client.findProxy = (uri) {
      return 'DIRECT';
    };

    // Strictly reject ALL bad certificates. 
    // Packet sniffers generate fake self-signed certificates for MITM attacks.
    // By returning false, we instantly drop the connection if a fake cert is detected.
    client.badCertificateCallback = (X509Certificate cert, String host, int port) {
      return false; // NEVER accept bad certificates
    };

    return client;
  }
}
