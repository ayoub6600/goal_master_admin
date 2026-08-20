import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goal_master_admin/core/components/bottom_sheet/base_bottom_sheet.dart';
import 'package:goal_master_admin/features/manager_wallet/presentation/manager/manager_wallet_topup_cubit/manager_wallet_topup_cubit.dart';
import 'package:goal_master_admin/features/manager_wallet/presentation/manager/manager_wallet_topup_cubit/manager_wallet_topup_state.dart';
import 'package:webview_flutter/webview_flutter.dart';

class ManagerPaymentScreen extends StatefulWidget {
  final String amount;

  const ManagerPaymentScreen({
    super.key,
    required this.amount,
  });

  @override
  State<ManagerPaymentScreen> createState() => _ManagerPaymentScreenState();
}

class _ManagerPaymentScreenState extends State<ManagerPaymentScreen> {
  late final WebViewController webViewController;
  late final String _merchantReference;
  bool isPageLoading = true;
  bool _resultHandled = false;
  bool _isLeaving = false;

  @override
  void initState() {
    super.initState();
    _merchantReference = 'ORDER_${DateTime.now().millisecondsSinceEpoch}';

    webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'PaymentChannel',
        onMessageReceived: (message) async {
          final raw = message.message;

          try {
            final data = jsonDecode(raw);
            final status = data['status'];

            if (status == 'success') {
              _onSuccess();
            } else if (status == 'error') {
              _showError('Payment failed: ${data["details"]}');
            } else if (status == 'cancel') {
              _showError('Payment cancelled');
            } else {
              _showError('Unknown status: $raw');
            }
          } catch (_) {
            if (raw == 'success') {
              _onSuccess();
            } else if (raw == 'error') {
              _showError('Payment failed');
            } else if (raw == 'cancel') {
              _showError('Payment cancelled');
            }
          }
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() => isPageLoading = true),
          onPageFinished: (_) => setState(() => isPageLoading = false),
          onWebResourceError: (_) {
            setState(() => isPageLoading = false);
            _showError('Failed to load page');
          },
        ),
      )
      ..loadHtmlString(_buildPaymentHtml());
  }

  Future<void> _onSuccess() async {
    if (_resultHandled) return;
    _resultHandled = true;

    final cubit = context.read<ManagerWalletTopUpCubit>();
    await cubit.confirmTopUp(
      widget.amount,
      status: 'true',
      reference: _merchantReference,
    );

    if (!mounted) return;

    final state = cubit.state;
    if (state is ManagerWalletTopUpSuccess) {
      await baseBottomSheet(
        context: context,
        hideNavBar: true,
        showDragHandle: false,
        child: const _ManagerPaymentResultSheet(success: true),
      );
      if (!mounted) return;
      Navigator.pop(context, 'success');
      return;
    }

    final errorMessage = state is ManagerWalletTopUpFailure
        ? state.message
        : 'حدث خطأ أثناء تثبيت عملية الشحن';
    await _showError(errorMessage);
  }

  Future<void> _showError([String? title]) async {
    if (_resultHandled) return;
    _resultHandled = true;

    await baseBottomSheet(
      context: context,
      hideNavBar: true,
      showDragHandle: false,
      child: _ManagerPaymentResultSheet(
        success: false,
        title: title ?? 'حدث خطأ أثناء الدفع',
        buttonText: 'حسناً',
      ),
    );

    if (!mounted) return;
    Navigator.pop(context, 'failed');
  }

  Future<void> _confirmExit() async {
    if (_isLeaving || !mounted) return;

    final shouldLeave = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('إلغاء الدفع؟'),
          content: const Text(
            'إذا رجعت الآن فسيتم إلغاء عملية الدفع الحالية ولن يتم شحن المحفظة.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('متابعة الدفع'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('نعم، رجوع'),
            ),
          ],
        );
      },
    );

    if (shouldLeave == true && mounted) {
      _isLeaving = true;
      Navigator.pop(context, 'cancelled');
    }
  }

  String _buildPaymentHtml() {
    const mID = '10765981238';
    const tID = '34152540';
    const merchantKey = 'effed1712b370f7d8011092861879bc7';
    final amount = double.tryParse(widget.amount) ?? 0.0;
    final merchRef = _merchantReference;

    return """
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>Moamalat Payment</title>
  <script src="https://cdnjs.cloudflare.com/ajax/libs/crypto-js/4.1.1/crypto-js.min.js"></script>
  <script src="https://npg.moamalat.net:6006/js/lightbox.js"></script>
  <style>
    body { font-family: Arial, sans-serif; text-align: center; background: #f9f9f9; }
  </style>
</head>
<body>
  <h3>Processing Payment...</h3>
  <script>
    function callLightbox() {
      var mID = '$mID';
      var tID = '$tID';
      var amount = $amount;
      var merchRef = '$merchRef';
      var merchantKey = "$merchantKey";
      var keyBytes = CryptoJS.enc.Hex.parse(merchantKey);
      var dt = new Date().YYYYMMDDHHMMSS();

      var strToHash = 'Amount=' + amount + '000' +
                      '&DateTimeLocalTrxn=' + dt +
                      '&MerchantId=' + mID +
                      '&MerchantReference=' + merchRef +
                      '&TerminalId=' + tID;

      var secureHash = CryptoJS.HmacSHA256(strToHash, keyBytes)
                               .toString(CryptoJS.enc.Hex)
                               .toUpperCase();

      Lightbox.Checkout.configure = {
        MID: mID,
        TID: tID,
        AmountTrxn: amount + '000',
        MerchantReference: merchRef,
        TrxDateTime: dt,
        SecureHash: secureHash,
        showCloseButton: true,
        allowCancel: true,
        completeCallback: function () {
          PaymentChannel.postMessage("success");
        },
        errorCallback: function (data) {
          PaymentChannel.postMessage(JSON.stringify({
            status: "error",
            details: data
          }));
        },
        cancelCallback: function () {
          PaymentChannel.postMessage("cancel");
        }
      };

      Lightbox.Checkout.showLightbox();
    }

    Object.defineProperty(Date.prototype, 'YYYYMMDDHHMMSS', {
      value: function () {
        function pad2(n) { return (n < 10 ? '0' : '') + n; }
        return this.getFullYear().toString() +
          pad2(this.getMonth() + 1) +
          pad2(this.getDate()) +
          pad2(this.getHours()) +
          pad2(this.getMinutes()) +
          pad2(this.getSeconds());
      }
    });

    window.onload = function() {
      callLightbox();
    };
  </script>
</body>
</html>
""";
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        await _confirmExit();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            onPressed: _confirmExit,
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
          ),
          title: const Text('الدفع الإلكتروني'),
          centerTitle: true,
        ),
        body: SafeArea(
          child: Stack(
            children: [
              WebViewWidget(controller: webViewController),
              if (isPageLoading)
                const Center(child: CircularProgressIndicator()),
            ],
          ),
        ),
      ),
    );
  }
}

class _ManagerPaymentResultSheet extends StatelessWidget {
  const _ManagerPaymentResultSheet({
    required this.success,
    this.title,
    this.buttonText,
  });

  final bool success;
  final String? title;
  final String? buttonText;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            success ? Icons.check_circle_rounded : Icons.cancel_rounded,
            color: success ? Colors.green : Colors.red,
            size: 72,
          ),
          const SizedBox(height: 16),
          Text(
            title ?? (success ? 'تم شحن المحفظة بنجاح' : 'فشلت عملية الشحن'),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(buttonText ?? 'حسناً'),
            ),
          ),
        ],
      ),
    );
  }
}
