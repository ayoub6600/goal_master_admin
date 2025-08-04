import 'package:flutter/material.dart';

class NoInternetPage extends StatelessWidget {
  final VoidCallback onRetry;
  const NoInternetPage({Key? key, required this.onRetry}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.wifi_off, size: 80, color: Colors.grey[400]),
              const SizedBox(height: 24),
              const Text(
                'لا يوجد اتصال بالإنترنت',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'يرجى التحقق من اتصالك وحاول مرة أخرى.',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: onRetry,
                child: const Text('حاول مرة أخرى'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
