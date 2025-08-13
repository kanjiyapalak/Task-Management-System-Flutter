import 'package:flutter/material.dart';

void main() {
  runApp(const TaskManagerApp());
}

class TaskManagerApp extends StatelessWidget {
  const TaskManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TMS Demo',
      theme: ThemeData(primarySwatch: Colors.indigo),
      home: const DemoScreen(),
    );
  }
}

class DemoScreen extends StatelessWidget {
  const DemoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('TMS - Task Management System')),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Task Management System Features:',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            FeatureCard(
              title: '🔐 Authentication',
              features: [
                'User Registration with email validation',
                'Secure Login with JWT simulation',
                'Password management',
                'Demo login functionality',
              ],
            ),
            FeatureCard(
              title: '📊 Dashboard',
              features: [
                'Task statistics overview',
                'Recent tasks display',
                'Priority and status indicators',
                'Quick action buttons',
              ],
            ),
            FeatureCard(
              title: '👤 Profile Management',
              features: [
                'Personal information editing',
                'Profile picture upload',
                'Password change functionality',
                'Account statistics display',
              ],
            ),
            FeatureCard(
              title: '🎨 UI/UX Features',
              features: [
                'Modern Material Design',
                'Custom reusable widgets',
                'Responsive layouts',
                'Clean navigation patterns',
              ],
            ),
            SizedBox(height: 20),
            Text(
              'Technical Implementation:',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text('• Provider state management'),
            Text('• Custom service layers'),
            Text('• Local data persistence'),
            Text('• Form validation'),
            Text('• Image picker integration'),
            Text('• HTTP service simulation'),
          ],
        ),
      ),
    );
  }
}

class FeatureCard extends StatelessWidget {
  final String title;
  final List<String> features;

  const FeatureCard({super.key, required this.title, required this.features});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...features.map(
              (feature) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text('• $feature'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
