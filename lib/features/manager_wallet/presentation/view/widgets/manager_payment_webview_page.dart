import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goal_master_admin/core/components/bottom_sheet/base_bottom_sheet.dart';
import 'package:goal_master_admin/features/manager_wallet/data/model/topup_checkout.dart';
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

  /// The server's checkout: reference, amount and signature all come from
  /// it. Null until the server has opened the top-up.
  TopUpCheckout? _checkout;
  bool isPageLoading = true;
  bool _resultHandled = false;
  bool _isLeaving = false;

  @override
  void initState() {
    super.initState();

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
              _showError('لم تتم عملية الدفع. لم يُخصم أي مبلغ من المحفظة.');
            } else if (status == 'cancel') {
              _showError('تم إلغاء عملية الدفع.');
            } else {
              _showError();
            }
          } catch (_) {
            if (raw == 'success') {
              _onSuccess();
            } else if (raw == 'error') {
              _showError('لم تتم عملية الدفع. لم يُخصم أي مبلغ من المحفظة.');
            } else if (raw == 'cancel') {
              _showError('تم إلغاء عملية الدفع.');
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
            _showError('تعذر تحميل صفحة الدفع. تحقق من الإنترنت وحاول مرة أخرى.');
          },
        ),
      );

    WidgetsBinding.instance.addPostFrameCallback((_) => _prepare());
  }

  /// Asks the server to open the top-up, then shows the Lightbox it signed.
  Future<void> _prepare() async {
    final cubit = context.read<ManagerWalletTopUpCubit>();
    await cubit.start(widget.amount);
    if (!mounted) return;

    final state = cubit.state;
    if (state is ManagerWalletTopUpReady) {
      _checkout = state.checkout;
      await webViewController.loadHtmlString(_buildPaymentHtml(state.checkout));
      return;
    }

    await _showError(state is ManagerWalletTopUpFailure
        ? state.message
        : 'تعذر بدء عملية الدفع. حاول مرة أخرى.');
  }

  Future<void> _onSuccess() async {
    if (_resultHandled || _checkout == null) return;
    _resultHandled = true;

    final cubit = context.read<ManagerWalletTopUpCubit>();
    await cubit.confirm(_checkout!.merchantReference);

    if (!mounted) return;

    final state = cubit.state;
    if (state is ManagerWalletTopUpSuccess || state is ManagerWalletTopUpPending) {
      final pending = state is ManagerWalletTopUpPending;
      await baseBottomSheet(
        context: context,
        hideNavBar: true,
        showDragHandle: false,
        child: _ManagerPaymentResultSheet(
          success: true,
          pending: pending,
          title: pending
              ? (state as ManagerWalletTopUpPending).message
              : null,
        ),
      );
      if (!mounted) return;
      Navigator.pop(context, pending ? 'pending' : 'success');
      return;
    }

    final errorMessage = state is ManagerWalletTopUpFailure
        ? state.message
        : 'حدث خطأ أثناء تثبيت عملية الشحن';
    _resultHandled = false;
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

  String _buildPaymentHtml(TopUpCheckout c) {
    // Every value is the server's, already signed. No key, no hashing here.
    final config = jsonEncode({
      'MID': c.mid,
      'TID': c.tid,
      'AmountTrxn': c.amountTrxn,
      'MerchantReference': c.merchantReference,
      'TrxDateTime': c.trxDateTime,
      'SecureHash': c.secureHash,
    });

    return """
<!DOCTYPE html>
<html lang="ar">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Moamalat Payment</title>
  <script src="${c.lightboxUrl}"></script>
  <style>
    body { font-family: Arial, sans-serif; text-align: center; background: #f9f9f9; }
  </style>
</head>
<body>
  <h3>جارٍ فتح صفحة الدفع...</h3>
  <script>
    function callLightbox() {
      var config = $config;
      config.showCloseButton = true;
      config.allowCancel = true;
      config.completeCallback = function () {
        PaymentChannel.postMessage("success");
      };
      config.errorCallback = function (data) {
        PaymentChannel.postMessage(JSON.stringify({ status: "error", details: data }));
      };
      config.cancelCallback = function () {
        PaymentChannel.postMessage("cancel");
      };
      Lightbox.Checkout.configure = config;
      Lightbox.Checkout.showLightbox();
    }

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
    this.pending = false,
    this.title,
    this.buttonText,
  });

  final bool success;

  /// Paid, waiting for the bank's confirmation.
  final bool pending;
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
            pending
                ? Icons.hourglass_top_rounded
                : success
                    ? Icons.check_circle_rounded
                    : Icons.cancel_rounded,
            color: pending
                ? Colors.orange
                : success
                    ? Colors.green
                    : Colors.red,
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
