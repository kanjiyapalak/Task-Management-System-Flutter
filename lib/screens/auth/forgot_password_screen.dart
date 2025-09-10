import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:email_validator/email_validator.dart';
import '../../services/firebase_auth_provider.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_button.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _sent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final res = await auth.resetPassword(email: _emailController.text.trim());
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(res['message']),
        backgroundColor: res['success'] ? Colors.green : Colors.red,
      ),
    );
    if (res['success']) {
      setState(() => _sent = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Forgot Password')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _sent ? 'Check Your Email' : 'Reset Your Password',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _sent
                    ? 'If an account exists for that email, you\'ll get a reset link shortly.'
                    : 'Enter your registered email. We\'ll send a reset link if the account exists.',
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 32),
              if (!_sent)
                CustomTextField(
                  label: 'Email',
                  hintText: 'you@example.com',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: const Icon(Icons.email_outlined),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Email required';
                    if (!EmailValidator.validate(v)) return 'Invalid email';
                    return null;
                  },
                ),
              const Spacer(),
              Consumer<AuthProvider>(
                builder: (context, auth, _) => CustomButton(
                  text: _sent ? 'Back to Login' : 'Send Reset Link',
                  onPressed: auth.isLoading
                      ? null
                      : () {
                          if (_sent) {
                            Navigator.of(context).pop();
                          } else {
                            _submit();
                          }
                        },
                  isLoading: auth.isLoading,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
