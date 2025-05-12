import 'package:flutter/material.dart';
import 'package:flutter_upi_india/flutter_upi_india.dart';
import 'package:paisa_app/routes.dart' as routes;
import 'package:mobile_scanner/mobile_scanner.dart';

class ScanQrCode extends StatefulWidget {
  const ScanQrCode({super.key});

  @override
  State<ScanQrCode> createState() => _ScanQrCodeState();
}

class _ScanQrCodeState extends State<ScanQrCode> {
  final MobileScannerController controller = MobileScannerController(
    autoZoom: true,
  );

  @override
  Widget build(BuildContext context) {
    return MobileScanner(
      controller: controller,
      onDetect: (result) async {
        final String upiUrl = result.barcodes.first.rawValue ?? '';

        if (upiUrl.isNotEmpty) {
          final uri = Uri.tryParse(upiUrl);
          if (uri != null && uri.queryParameters.isNotEmpty) {
            final params = uri.queryParameters;
            final upiId = params['pa'] ?? '';
            final name = params['pn'] ?? '';
            final amount = params['am'] ?? '';
            final currency = params['cu'] ?? '';
            final transactionNote = params['tn'] ?? '';
            final merchantCode = params['mc'] ?? '';
            final transactionReferenceId = params['tr'] ?? '';
            final transactionUrl = params['url'] ?? '';
            await controller.stop();

            if (amount.isEmpty) {
              Navigator.of(context).pushReplacementNamed(
                routes.pay,
                arguments: {
                  'upiId': upiId,
                  'name': name,
                  'amount': amount,
                  'currency': currency,
                  'transactionNote': transactionNote,
                  'merchantCode': merchantCode,
                  'transactionReferenceId': transactionReferenceId,
                  'transactionUrl': transactionUrl,
                },
              );
            } else {
              final List<ApplicationMeta> appMetaList =
                  await UpiPay.getInstalledUpiApplications(
                    statusType: UpiApplicationDiscoveryAppStatusType.all,
                  );
              await UpiPay.initiateTransaction(
                amount: amount,
                app: appMetaList.first.upiApplication,
                receiverName: name,
                receiverUpiAddress: upiId,
                transactionRef: transactionReferenceId,
                transactionNote: transactionNote,
                merchantCode: merchantCode,
                url: transactionUrl,
              );
              Navigator.of(context).pop();
            }
          }
        }
      },
    );
  }
}
