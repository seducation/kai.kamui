import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SettingPrivacyScreen extends StatelessWidget {
  const SettingPrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Privacy Policy for MyApps',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Last Updated: 24th July 2024',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
            const Text(
              'Owned & Operated By: MyApps Inc.',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 16),
            const Text(
              'MyApps (“we”, “our”, “us”) provides a social media platform that allows users to create profiles, share posts, upload media, and communicate with others. This Privacy Policy explains how we collect, use, store, and protect your information.',
            ),
            const SizedBox(height: 16),
            const Text(
              '1. Information We Collect',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'We may collect the following information when you use MyApps:',
            ),
            const SizedBox(height: 8),
            const Text(
              '1.1 Personal Information',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const Text('Name\nUsername\nEmail address\nPhone number\nProfile photo\nDate of birth (if provided)'),
            const SizedBox(height: 8),
            const Text(
              '1.2 User-Generated Content',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const Text('Posts, photos, videos, comments\nStories, status updates\nMessages and chats'),
             const SizedBox(height: 8),
            const Text(
              '1.3 Device & Usage Data',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const Text('Device model, operating system\nIP address\nApp usage information\nLog files and crash reports'),
             const SizedBox(height: 8),
            const Text(
              '1.4 Location Data',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const Text('Approximate location based on IP\n(Optional) Precise GPS location if user allows it'),
             const SizedBox(height: 8),
            const Text(
              '1.5 Third-Party Services',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const Text('If you use third-party login or analytics/ads, these services may collect data:\n\nGoogle AdMob (advertising)\nAppwrite or other backend services\nAnalytics tools (if used)'),
            const SizedBox(height: 16),
            const Text(
              '2. How We Use Your Information',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('We use the collected data to:\n\nCreate and manage user accounts\nProvide social features (posting, messaging, etc.)\nImprove app performance\nPersonalize content and recommendations\nPrevent fraud, spam, and abuse\nDisplay ads (if enabled)\nCommunicate updates, security notices, and support messages'),
            const SizedBox(height: 16),
            const Text(
              '3. How We Share Your Information',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('We do not sell user information.\n\nWe may share information only with:\n\nService Providers (hosting, database, ads, analytics)\nLaw enforcement (only if legally required)\nOther users (only content you choose to share publicly)\n\nPrivate messages are not shared publicly, except for security/legal reasons.'),
            const SizedBox(height: 16),
            const Text(
              '4. How We Protect Your Data',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('We use:\n\nEncrypted connections (HTTPS)\nSecure data storage\nAccess control and authentication\n\nHowever, no method is 100% secure. Users should keep passwords safe.'),
            const SizedBox(height: 16),
            const Text(
              '5. Your Rights',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('You may:\n\nAccess and update your information\nDelete your account\nRequest deletion of your data\nChange privacy settings inside the app'),
             const SizedBox(height: 16),
            const Text(
              '6. Children’s Privacy',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('MyApps is not intended for users under 13 years of age.\nIf we learn that a minor’s data was collected, we will delete it immediately.'),
            const SizedBox(height: 16),
            const Text(
              '7. Changes to This Policy',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('We may update this Privacy Policy from time to time. Continued use of the app after changes means you accept the updated policy.'),
             const SizedBox(height: 16),
            const Text(
              '8. Contact Information',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('For questions or concerns, contact:\nMyApps Inc.\nEmail: support@myapps.com'),
            const Divider(height: 40, thickness: 1),
            const Text(
              'Terms & Conditions for MyApps',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
             const Text(
              'Last Updated: 24th July 2024',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
            const Text(
              'Owned & Operated By: MyApps Inc.',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
             const SizedBox(height: 16),
            const Text('By using MyApps, you agree to follow these Terms & Conditions. If you do not agree, please do not use the app.'),
             const SizedBox(height: 16),
            const Text(
              '1. Use of the App',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('You must be 13 years or older.\nYou are responsible for the security of your account.\nDo not share your password with others.'),
             const SizedBox(height: 16),
            const Text(
              '2. User Responsibilities',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
             const SizedBox(height: 8),
            const Text('You agree not to:\n\nPost harmful, abusive, illegal, or inappropriate content\nImpersonate others\nSpread spam, viruses, or malware\nHarass or threaten other users\nViolate privacy of others\nUpload copyrighted content without permission'),
            const SizedBox(height: 16),
            const Text(
              '3. User Content',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('You own the content you upload.\n\nBy posting on MyApps, you give us permission to display your content within the app.\n\nWe may remove content that violates our policies.'),
            const SizedBox(height: 16),
            const Text(
              '4. Messaging & Communication',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('Users are responsible for their messages.\n\nWe may review messages if required for security, abuse, or legal reasons.'),
            const SizedBox(height: 16),
            const Text(
              '5. Advertisements & Third-Party Services',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('The app may show ads or link to third-party services.\nWe are not responsible for:\n\nThird-party content\nTheir policies\nTheir actions\n\nUse them at your own risk.'),
            const SizedBox(height: 16),
            const Text(
              '6. Termination',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('We may suspend or delete accounts that violate terms, including:\n\nPosting illegal content\nHarassment\nRepeated policy violations\nAttempting to hack or damage the app\n\nUsers can also delete their account at any time.'),
            const SizedBox(height: 16),
            const Text(
              '7. Liability',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('MyApps is provided “as-is.”\nWe are not responsible for:\n\nData loss\nService interruptions\nUser conflicts or misuse\n\nUse the app at your own risk.'),
             const SizedBox(height: 16),
            const Text(
              '8. Changes to Terms',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('We may update these Terms at any time. You will be notified of changes within the app.'),
             const SizedBox(height: 16),
            const Text(
              '9. Contact',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
             const SizedBox(height: 8),
            const Text('For any issues, contact:\nMyApps Inc.\nEmail: support@myapps.com'),
          ],
        ),
      ),
    );
  }
}
