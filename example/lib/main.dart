import 'package:flutter/material.dart';
import 'package:flutter_qr_bank_generator/flutter_qr_bank_generator.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('flutter_qr_bank_generator example')),
        body: Center(
          child: SizedBox(
            width: 250,
            height: 250,
            child: QrGeneratorView.bank(
              bankData: BankQrData(
                bankBin: '970415',
                accountNumber: '113366668888',
                amount: '79000',
                content: 'Ung Ho Quy Vac Xin',
              ),
            ),
          ),
        ),
      ),
    );
  }
}
