// Example usage of the LoadingOverlay components in different scenarios

import 'package:flutter/material.dart';
import 'package:ctp/components/loading_overlay.dart';
import 'package:ctp/components/constants.dart';

class LoadingOverlayExamples extends StatefulWidget {
  const LoadingOverlayExamples({super.key});

  @override
  State<LoadingOverlayExamples> createState() => _LoadingOverlayExamplesState();
}

class _LoadingOverlayExamplesState extends State<LoadingOverlayExamples> {
  bool _isLoading = false;
  double _progress = 0.0;
  String _status = '';

  // Example 1: Basic loading with progress
  void _startProgressiveUpload() {
    setState(() {
      _isLoading = true;
      _progress = 0.0;
      _status = 'Starting upload...';
    });

    // Simulate progressive upload
    _simulateProgress();
  }

  void _simulateProgress() async {
    final steps = [
      (0.2, 'Preparing data...'),
      (0.4, 'Uploading images...'),
      (0.7, 'Processing documents...'),
      (0.9, 'Finalizing...'),
      (1.0, 'Complete!'),
    ];

    for (final (progress, status) in steps) {
      await Future.delayed(const Duration(seconds: 1));
      setState(() {
        _progress = progress;
        _status = status;
      });
    }

    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      _isLoading = false;
      _progress = 0.0;
      _status = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Loading Overlay Examples'),
        backgroundColor: const Color(0xFF0E4CAF),
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Loading Overlay Examples',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),

                // Example 1: Progressive Loading
                ElevatedButton(
                  onPressed: _isLoading ? null : _startProgressiveUpload,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.orange,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Start Progressive Upload'),
                ),
                const SizedBox(height: 20),

                // Example 2: Simple Loading
                ElevatedButton(
                  onPressed: () {
                    setState(() => _isLoading = true);
                    Future.delayed(const Duration(seconds: 3), () {
                      setState(() => _isLoading = false);
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.blue,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Show Simple Loading'),
                ),

                const SizedBox(height: 40),
                const Text(
                  'Usage Examples:',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    '''
// 1. Progressive Loading (with progress indicator)
LoadingOverlay(
  progress: _uploadProgress,
  status: _uploadStatus,
  isVisible: _isLoading,
)

// 2. Simple Loading (basic spinner)
SimpleLoadingOverlay(
  isVisible: _isLoading,
  message: 'Saving data...',
)

// 3. Custom Loading (fully customizable)
CustomLoadingOverlay(
  progress: _progress,
  status: _status,
  isVisible: _isLoading,
  title: 'Custom Title',
  subtitle: 'Custom subtitle',
  progressColor: Colors.green,
  backgroundColor: Colors.blue.shade50,
  borderColor: Colors.blue,
  size: 120,
)
                    ''',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Main Loading Overlay - Progressive
          LoadingOverlay(
            progress: _progress,
            status: _status,
            isVisible: _isLoading,
          ),

          // Alternative examples (uncomment to test):

          // Simple Loading Overlay
          // SimpleLoadingOverlay(
          //   isVisible: _isLoading,
          //   message: 'Processing your request...',
          // ),

          // Custom Loading Overlay
          // CustomLoadingOverlay(
          //   progress: _progress,
          //   status: _status,
          //   isVisible: _isLoading,
          //   title: 'Custom Upload',
          //   subtitle: 'Please wait while we process your data',
          //   progressColor: AppColors.blue,
          //   backgroundColor: Colors.blue.shade50,
          //   borderColor: AppColors.blue,
          //   size: 120,
          // ),
        ],
      ),
    );
  }
}

/*
Usage in your own pages:

1. Add the import:
   import 'package:ctp/components/loading_overlay.dart';

2. Add state variables:
   bool _isLoading = false;
   double _uploadProgress = 0.0;
   String _uploadStatus = '';

3. Wrap your Scaffold in a Stack and add the LoadingOverlay:
   return Stack(
     children: [
       Scaffold(...),
       LoadingOverlay(
         progress: _uploadProgress,
         status: _uploadStatus,
         isVisible: _isLoading,
       ),
     ],
   );

4. Update progress in your async operations:
   setState(() {
     _uploadProgress = 0.5;
     _uploadStatus = 'Halfway done...';
   });
*/
