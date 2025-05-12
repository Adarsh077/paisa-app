import 'package:flutter/material.dart';
import 'package:flutter_upi_india/flutter_upi_india.dart';

class MakePaymentScreen extends StatefulWidget {
  final Map<String, String> data;

  MakePaymentScreen(this.data);

  @override
  State<MakePaymentScreen> createState() => _MakePaymentScreenState();
}

class _MakePaymentScreenState extends State<MakePaymentScreen> {
  final TextEditingController amountController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final FocusNode descriptionFocusNode = FocusNode(); // Add focus node

  double amountInputWidth = 60;
  double descInputWidth = 100;

  @override
  void initState() {
    super.initState();
    amountController.text = widget.data['amount'] ?? '';
    descriptionController.text = widget.data['transactionNote'] ?? '';
    amountController.addListener(_updateAmountWidth);
    descriptionController.addListener(_updateDescWidth);
  }

  @override
  void dispose() {
    amountController.dispose();
    descriptionController.dispose();
    descriptionFocusNode.dispose(); // Dispose focus node
    super.dispose();
  }

  void _updateAmountWidth() {
    final text = amountController.text.isEmpty ? "0" : amountController.text;
    final textWidth = _calcTextWidth(
      text,
      const TextStyle(fontSize: 50, fontWeight: FontWeight.bold),
    );
    setState(() => amountInputWidth = textWidth + 10);
  }

  void _updateDescWidth() {
    final text =
        descriptionController.text.isEmpty
            ? ""
            : '${descriptionController.text}wwww';
    final textWidth = _calcTextWidth(text, const TextStyle(fontSize: 16));

    setState(() => descInputWidth = textWidth.clamp(100, 260));
  }

  double _calcTextWidth(String text, TextStyle style) {
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout();
    return textPainter.size.width;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: colorScheme.surfaceContainerLowest,
        elevation: 0,
      ),
      backgroundColor: colorScheme.surfaceContainerLowest,
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final List<ApplicationMeta> appMetaList =
              await UpiPay.getInstalledUpiApplications(
                statusType: UpiApplicationDiscoveryAppStatusType.all,
              );
          await UpiPay.initiateTransaction(
            amount: amountController.text,
            app: appMetaList.first.upiApplication,
            receiverName: widget.data['name'] ?? '',
            receiverUpiAddress: widget.data['upiId'] ?? '',
            transactionRef: widget.data['transactionReferenceId'] ?? '',
            transactionNote: descriptionController.text,
            merchantCode: widget.data['merchantCode'] ?? '',
            url: widget.data['transactionUrl'] ?? '',
          );
          Navigator.of(context).pop();
        },
        backgroundColor: colorScheme.primary,
        elevation: 3,
        child: Icon(Icons.send, color: colorScheme.onPrimary),
      ),
      body: Column(
        children: [
          SizedBox(height: 16),
          CircleAvatar(
            radius: 36,
            backgroundColor: colorScheme.surfaceBright,
            child: Text(
              widget.data['name']?.substring(0, 1).toUpperCase() ?? '',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
          SizedBox(height: 16),
          Text(
            'Paying ${widget.data['name'] ?? ''}',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 4),
          Text(
            widget.data['upiId'] ?? '',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            // crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                "₹",
                style: TextStyle(
                  fontSize: 35,
                  fontWeight: FontWeight.w400,
                  color: colorScheme.onSurface,
                ),
              ),
              SizedBox(width: 8),
              AnimatedContainer(
                width: amountInputWidth,
                duration: Duration(milliseconds: 100),
                curve: Curves.easeOut,
                child: TextField(
                  autofocus: true,
                  controller: amountController,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  textAlign: TextAlign.left, // Changed from center to left
                  textDirection: TextDirection.ltr, // Already set
                  style: TextStyle(
                    fontSize: 50,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: "0",
                    hintStyle: TextStyle(
                      color: colorScheme.onSurface.withOpacity(0.3),
                    ),
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onSubmitted: (_) {
                    FocusScope.of(
                      context,
                    ).requestFocus(descriptionFocusNode); // Autofocus notes
                  },
                ),
              ),
            ],
          ),
          SizedBox(height: 18),
          AnimatedContainer(
            width: descInputWidth,
            duration: Duration(milliseconds: 100),
            curve: Curves.easeOut,
            child: TextField(
              maxLines: null, // Allows unlimited lines
              minLines: 1, // Starts with a single line
              controller: descriptionController,
              focusNode: descriptionFocusNode, // Attach focus node
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                filled: true,
                fillColor: colorScheme.secondaryContainer,
                hintText: 'Note',
                hintStyle: TextStyle(
                  color: colorScheme.onSecondaryContainer.withOpacity(0.7),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                contentPadding: EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 8,
                ),
              ),
              style: TextStyle(
                color: colorScheme.onSecondaryContainer,
                fontSize: 16,
              ),
            ),
          ),
          Spacer(),
        ],
      ),
    );
  }
}
