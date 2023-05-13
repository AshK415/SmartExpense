import 'dart:convert';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'features/upi_payment/domain/upi.dart';

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
      theme: FlexThemeData.light(scheme: FlexScheme.mandyRed),
      darkTheme: FlexThemeData.dark(scheme: FlexScheme.mandyRed),
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
            //final Uint8List? image = capture.image;
            for (final barcode in barcodes) {
              debugPrint('Barcode found! ${barcode.rawValue}');
            }
            if (!found.value) {
              HapticFeedback.vibrate();
              found.value = true;
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      PaymentPage(upiLink: barcodes.first.rawValue!),
                ),
              ).then((value) => found.value = false);
            }
          }),
    );
  }
}

class PaymentPage extends HookWidget {
  final String upiLink;
  static const platform = MethodChannel('example.com/channel');

  const PaymentPage({Key? key, required this.upiLink}) : super(key: key);

  Future<List<Map<dynamic, dynamic>>?> getApps() async {
    try {
      return platform.invokeListMethod('getApps', {});
    } on PlatformException catch (e) {
      print(e);
      return Future.value(List.empty());
    }
  }

  @override
  Widget build(BuildContext context) {
    final amountFieldController = TextEditingController(text: '');
    final descriptionFieldController = TextEditingController(text: '');
    //final payee = upiLink.split('?').last.split('&').first.split('=').last;
    final upiObj = UPI.fromString(upiLink);
    final payee = upiObj.pn ?? upiObj.pa;
    final upi = useState("");
    return Scaffold(
      appBar: AppBar(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: FutureBuilder(
            future: getApps(),
            builder:
                (ctx, AsyncSnapshot<List<Map<dynamic, dynamic>>?> snapshot) {
              if (snapshot.hasData) {
                final List<Map<dynamic, dynamic>>? apps = snapshot.data;
                if (apps != null) {
                  return Column(
                    children: [
                      const SizedBox(height: 8),
                      const Text('Paying to',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(
                        height: 8,
                      ),
                      Text(
                        payee,
                        style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            color: Colors.blueGrey),
                      ),
                      const SizedBox(
                        height: 16,
                      ),
                      TextField(
                        controller: amountFieldController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          hintText: '0.0',
                          label: Text(
                            'Amount',
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(
                        height: 8,
                      ),
                      TextField(
                        controller: descriptionFieldController,
                        keyboardType: TextInputType.text,
                        decoration: const InputDecoration(
                            label: Text(
                              'Description',
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            hintText: 'Payment description',
                            border: OutlineInputBorder()),
                      ),
                      const SizedBox(
                        height: 16,
                      ),
                      const Text(
                        'Pay Using',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(
                        height: 8,
                      ),
                      SizedBox(
                        height: 90,
                        child: Scrollbar(
                          thickness: 0,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: apps.length,
                            shrinkWrap: true,
                            itemBuilder: (c, i) => _appIcon(
                                apps[i],
                                amountFieldController,
                                descriptionFieldController,
                                context,
                                upiObj,
                                upi),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ValueListenableBuilder<String>(
                        valueListenable: upi,
                        builder: (c, d, w) => Text(d),
                      ),
                    ],
                  );
                } else {
                  return const Center(
                    child: Text('No apps installed'),
                  );
                }
              } else if (snapshot.hasError) {
                return const Center(
                  child: Text('Got some error'),
                );
              }
              return const Center(
                child: CircularProgressIndicator(),
              );
            }),
      ),
    );
  }

  Uint8List convertImage(String str) {
    final List<int> codeUnits = str.codeUnits;
    final Uint8List uint8list = Uint8List.fromList(codeUnits);
    return uint8list;
  }

  void _showMessage(BuildContext context, String content, String type) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          content,
          style: TextStyle(
              fontWeight: FontWeight.bold,
              color: type == 'Error'
                  ? Colors.red
                  : Theme.of(context).colorScheme.secondary),
        ),
      ),
    );
  }

  Widget _appIcon(
      Map<dynamic, dynamic> app,
      TextEditingController amountCtrl,
      TextEditingController descCtrl,
      BuildContext context,
      UPI upiObj,
      ValueNotifier<String> upi) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: GestureDetector(
        onTap: () async {
          if (amountCtrl.text.isNotEmpty && amountCtrl.text != '0') {
            upiObj.setAmount(amountCtrl.text);
            final finalUrl = upiObj.getEncodedUrl();
            upi.value = finalUrl;
            platform.invokeMethod('initiateTransaction',
                {'package': app['packageName'], 'url': finalUrl}).then((value) {
              _showMessage(context, value, 'Success');
              amountCtrl.clear();
            });
          } else {
            _showMessage(context, 'Amount Required', 'Error');
          }
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Builder(
                builder: (c) => app['icon'] != null
                    ? Image.memory(
                        base64.decode(app['icon']),
                        width: 64,
                        height: 64,
                      )
                    : Container()),
            Container(
              alignment: Alignment.center,
              child: Text(
                app['appName'] ?? app['packageName'],
                textAlign: TextAlign.center,
              ),
            )
          ],
        ),
      ),
    );
  }
}
