import 'package:flutter/material.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/custom_back_button.dart';

class SuccessScreen extends StatelessWidget {
  const SuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Back button
          if (Navigator.of(context).canPop())
            const Positioned(top: 50, left: 20, child: CustomBackButton()),
          Center(
            child: Card(
              elevation: 8,
              child: Container(
                width: 400,
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.check_circle,
                      size: 80,
                      color: Colors.green,
                    ),
                    const SizedBox(height: 24),
                    Text('Registration Successful!', style: AppTheme.headline),
                    const SizedBox(height: 16),
                    Text(
                      'Your registration has been submitted successfully.',
                      textAlign: TextAlign.center,
                      style: AppTheme.body,
                    ),
                    const SizedBox(height: 8),
                    Text('Registration ID: REG001', style: AppTheme.title),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.star, color: Colors.amber),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '100 bonus points have been awarded to your account!',
                              style: AppTheme.success,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pushNamedAndRemoveUntil(
                            context,
                            '/dashboard',
                            (route) => false,
                          );
                        },
                        child: Text(
                          'Go to Dashboard',
                          style: AppTheme.body.copyWith(color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton(
                      onPressed: () {
                        // Implement download functionality
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Registration details downloaded successfully',
                            ),
                          ),
                        );
                      },
                      child: Text(
                        'Download Registration Details',
                        style: AppTheme.body,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
