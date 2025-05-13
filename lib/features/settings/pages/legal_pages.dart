import 'package:flutter/material.dart';
import 'package:reverie/utils/snackbar_utils.dart';
import 'package:url_launcher/url_launcher.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              'Data Collection',
              'Reverie collects and processes the following data:\n\n'
                  '• Photos and videos from your device\n'
                  '• Journal entries\n'
                  '• App usage statistics\n\n'
                  'All data is stored locally on your device unless explicitly shared.',
            ),
            _buildSection(
              'Data Usage',
              'Your data is used to:\n\n'
                  '• Display your media in the gallery\n'
                  '• Analyze images for object detection\n'
                  '• Generate image descriptions\n'
                  '• Improve app performance and user experience\n\n'
                  'We do not share your data with third parties.',
            ),
            _buildSection(
              'AI Features',
              'Our AI features:\n\n'
                  '• Image analysis for object detection\n'
                  '• Image description generation\n'
                  '• All processing is done locally when possible\n'
                  '• Some features may require internet connection',
            ),
            _buildSection(
              'Data Security',
              'We implement security measures to protect your data:\n\n'
                  '• Local storage encryption\n'
                  '• Secure media handling\n'
                  '• Regular security updates',
            ),
            _buildSection(
              'Your Rights',
              'You have the right to:\n\n'
                  '• Access your data\n'
                  '• Delete your data\n'
                  '• Export your data\n'
                  '• Opt out of data collection',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }
}

class TermsOfServicePage extends StatelessWidget {
  const TermsOfServicePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms of Service'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              'Acceptance of Terms',
              'By using Reverie, you agree to these terms. If you do not agree, please do not use the app.',
            ),
            _buildSection(
              'User Responsibilities',
              'You agree to:\n\n'
                  '• Use the app legally and ethically\n'
                  '• Respect intellectual property rights\n'
                  '• Maintain account security\n'
                  '• Not misuse the AI features',
            ),
            _buildSection(
              'AI Features',
              'Our AI features:\n\n'
                  '• Image analysis for object detection\n'
                  '• Image description generation\n'
                  '• May not be 100% accurate\n'
                  '• Should not be used for harmful purposes\n'
                  '• May be limited or modified at any time',
            ),
            _buildSection(
              'Limitations',
              'Reverie is not responsible for:\n\n'
                  '• Lost or corrupted data\n'
                  '• AI-generated content accuracy\n'
                  '• Third-party service issues\n'
                  '• Device compatibility problems',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }
}

class HelpAndFAQPage extends StatelessWidget {
  const HelpAndFAQPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & FAQ'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildFAQItem(
            'How do I add photos to my gallery?',
            'You can add photos by granting media access permission in the settings. '
                'The app will then display all your photos and videos.',
          ),
          _buildFAQItem(
            'How does the AI image analysis work?',
            'The AI analyzes your photos to detect objects and generate descriptions. '
                'This helps you better understand and organize your memories.',
          ),
          _buildFAQItem(
            'Can I export my journal entries?',
            'Yes, you can export your journal entries as text files or PDFs. '
                'Go to the journal settings to find export options.',
          ),
          _buildFAQItem(
            'How do I manage my privacy?',
            'You can control your privacy settings in the app settings. '
                'This includes media access, data collection, and AI features.',
          ),
          _buildFAQItem(
            'What should I do if I find a bug?',
            'Please use the "Report an Issue" feature in settings to report bugs. '
                'Include as much detail as possible to help us fix the issue.',
          ),
        ],
      ),
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              question,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              answer,
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

class ReportIssuePage extends StatefulWidget {
  const ReportIssuePage({super.key});

  @override
  State<ReportIssuePage> createState() => _ReportIssuePageState();
}

class _ReportIssuePageState extends State<ReportIssuePage> {
  final _issueController = TextEditingController();
  final _emailController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _issueController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submitFeedback() async {
    if (_issueController.text.trim().isEmpty) {
      SnackbarUtils.showError(context, 'Please describe the issue');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Create email content with proper formatting
      const subject = 'Reverie App Feedback';
      final body = '''
Issue Description:
${_issueController.text}

User Email: ${_emailController.text}

Device Info:
${Theme.of(context).platform}
''';

      // Launch email client with properly encoded parameters
      final Uri emailLaunchUri = Uri(
        scheme: 'mailto',
        path: 'support@reverie.app',
        queryParameters: {
          'subject': subject,
          'body': body,
        },
      );

      if (await launchUrl(emailLaunchUri)) {
        if (mounted) {
          SnackbarUtils.showSuccess(
            context,
            'Thank you for your feedback!',
          );
          Navigator.pop(context);
        }
      } else {
        throw 'Could not launch email client';
      }
    } catch (e) {
      if (mounted) {
        SnackbarUtils.showError(
          context,
          'Failed to submit feedback. Please try again.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report an Issue'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Help us improve Reverie',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Please describe the issue you\'re experiencing in detail. '
              'Include steps to reproduce, expected behavior, and actual behavior.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _issueController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'Describe the issue...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                hintText: 'Your email (optional)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                ),
                onPressed: _isSubmitting ? null : _submitFeedback,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('Submit'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
