import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends HookWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cameraController = MobileScannerController();
    final found = useState(false);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense'),
      ),
      body: MobileScanner(
          controller: cameraController,
          onDetect: (capture) {
            final List<Barcode> barcodes = capture.barcodes;
            final Uint8List? image = capture.image;
            for (final barcode in barcodes) {
              debugPrint('Barcode found! ${barcode.rawValue}');
            }
            if (!found.value) {
              HapticFeedback.heavyImpact();
              found.value = true;
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      PaymentPage(upiLink: barcodes.first.rawValue!),
                ),
              ).then((value) => found.value = false);
              // HapticFeedback.mediumImpact().then((value) {
              //   found.value = true;
              //   Navigator.push(
              //     context,
              //     MaterialPageRoute(
              //       builder: (_) =>
              //           PaymentPage(upiLink: barcodes.first.rawValue!),
              //     ),
              //   ).then((value) => found.value = false);
              // });
            }

            // ignore: use_build_context_synchronously
          }),
    );
  }
}

class PaymentPage extends StatelessWidget {
  final String upiLink;

  const PaymentPage({Key? key, required this.upiLink}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: Text(upiLink),
      ),
    );
  }
}
