import 'dart:io';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class HtmlViewerScreen extends StatefulWidget {
  final String htmlContent;

  const HtmlViewerScreen({super.key, required this.htmlContent});

  @override
  State<HtmlViewerScreen> createState() => _HtmlViewerScreenState();
}

class _HtmlViewerScreenState extends State<HtmlViewerScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    final wrappedHtml = _injectPdfScript(widget.htmlContent);

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            setState(() => _isLoading = false);
          },
        ),
      )
      ..loadHtmlString(wrappedHtml);
  }

  String _injectPdfScript(String originalHtml) {
    return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <script src="https://cdnjs.cloudflare.com/ajax/libs/html2pdf.js/0.10.1/html2pdf.bundle.min.js"></script>
  <script>
    function downloadPDF() {
      var element = document.getElementById('invoice-container');
      if (element) {
        html2pdf().from(element).save('invoice.pdf');
      }
    }
  </script>
</head>
<body>
  $originalHtml
</body>
</html>
''';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('معاينة الفاتورة'),
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: () {
              _controller.runJavaScript("window.print();");
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('جاري تحميل الفاتورة كـ PDF...')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () {
              _controller.runJavaScript("downloadPDF();");
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
