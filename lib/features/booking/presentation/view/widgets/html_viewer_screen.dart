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
// جزرب دا لما زياد يعدب

// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:webview_flutter/webview_flutter.dart';

// class HtmlViewerScreen extends StatefulWidget {
//   final String htmlContent;

//   const HtmlViewerScreen({super.key, required this.htmlContent});

//   @override
//   State<HtmlViewerScreen> createState() => _HtmlViewerScreenState();
// }

// class _HtmlViewerScreenState extends State<HtmlViewerScreen> {
//   late final WebViewController _controller;
//   bool _isLoading = true;
//   bool _isPdfGenerating = false;

//   @override
//   void initState() {
//     super.initState();

//     final wrappedHtml = _injectPdfScript(widget.htmlContent);

//     _controller = WebViewController()
//       ..setJavaScriptMode(JavaScriptMode.unrestricted)
//       ..setNavigationDelegate(
//         NavigationDelegate(
//           onPageFinished: (_) {
//             setState(() => _isLoading = false);
//           },
//           onWebResourceError: (error) {
//             setState(() => _isLoading = false);
//             ScaffoldMessenger.of(context).showSnackBar(
//               SnackBar(content: Text('Error loading content: ${error.description}')),
//             );
//           },
//         ),
//       )
//       ..loadHtmlString(wrappedHtml);
//   }

//   String _injectPdfScript(String originalHtml) {
//     return '''
// <!DOCTYPE html>
// <html>
// <head>
//   <meta charset="utf-8">
//   <meta name="viewport" content="width=device-width, initial-scale=1.0">
//   <script src="https://cdnjs.cloudflare.com/ajax/libs/html2pdf.js/0.10.1/html2pdf.bundle.min.js"></script>
//   <style>
//     #invoice-container {
//       padding: 20px;
//       background-color: white;
//     }
//     @media print {
//       body * {
//         visibility: hidden;
//       }
//       #invoice-container, #invoice-container * {
//         visibility: visible;
//       }
//       #invoice-container {
//         position: absolute;
//         left: 0;
//         top: 0;
//         width: 100%;
//       }
//     }
//   </style>
//   <script>
//     function downloadPDF() {
//       var element = document.getElementById('invoice-container');
//       if (element) {
//         var opt = {
//           margin: 10,
//           filename: 'invoice_${DateTime.now().millisecondsSinceEpoch}.pdf',
//           image: { type: 'jpeg', quality: 0.98 },
//           html2canvas: { scale: 2, useCORS: true },
//           jsPDF: { unit: 'mm', format: 'a4', orientation: 'portrait' }
//         };

//         return new Promise((resolve, reject) => {
//           html2pdf().set(opt).from(element).toPdf().get('pdf').then((pdf) => {
//             resolve(true);
//           }).catch((error) => {
//             reject(error);
//           });
//         });
//       }
//       return Promise.resolve(false);
//     }
//   </script>
// </head>
// <body>
//   <div id="invoice-container">
//     $originalHtml
//   </div>
// </body>
// </html>
// ''';
//   }

//   Future<void> _generateAndDownloadPdf() async {
//     setState(() => _isPdfGenerating = true);

//     try {
//       final result = await _controller.runJavaScriptReturningResult('downloadPDF();');
//       if (result != true) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Failed to generate PDF')),
//         );
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error generating PDF: ${e.toString()}')),
//       );
//     } finally {
//       setState(() => _isPdfGenerating = false);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('معاينة الفاتورة'),
//         actions: [
//           if (_isPdfGenerating)
//             const Padding(
//               padding: EdgeInsets.all(12.0),
//               child: CircularProgressIndicator(color: Colors.white),
//             )
//           else
//             IconButton(
//               icon: const Icon(Icons.download),
//               onPressed: _generateAndDownloadPdf,
//               tooltip: 'تحميل PDF',
//             ),
//           IconButton(
//             icon: const Icon(Icons.print),
//             onPressed: () => _controller.runJavaScript('window.print();'),
//             tooltip: 'طباعة',
//           ),
//         ],
//       ),
//       body: Stack(
//         children: [
//           WebViewWidget(controller: _controller),
//           if (_isLoading)
//             const Center(child: CircularProgressIndicator()),
//         ],
//       ),
//     );
//   }
// }
