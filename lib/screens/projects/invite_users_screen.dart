import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/project.dart';
import '../../models/project_invite.dart';
import '../../services/project_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class InviteUsersScreen extends StatefulWidget {
  final Project project;
  const InviteUsersScreen({super.key, required this.project});

  @override
  State<InviteUsersScreen> createState() => _InviteUsersScreenState();
}

class _InviteUsersScreenState extends State<InviteUsersScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  bool _searching = false;
  bool _sending = false;
  Map<String, dynamic>? _foundUser;
  final _db = FirebaseFirestore.instance;

  @override
  @override
  void initState() {
    super.initState();
    // Load invites from backend for this project
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProjectProvider>(context, listen: false)
          .refreshInvitesForProject(widget.project.id);
    });
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _searchUser() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) return;
    setState(() {
      _searching = true;
      _foundUser = null;
    });
    // Query Firestore users collection by email
    final snap = await _db
        .collection('users')
        .where('email', isEqualTo: email.toLowerCase())
        .limit(1)
        .get();
  final user = snap.docs.isNotEmpty
    ? () {
      final data = snap.docs.first.data();
      final id = snap.docs.first.id;
      final fullName = (data['fullName'] as String?)?.trim();
      final firstFromFull = (fullName != null && fullName.isNotEmpty)
        ? fullName.split(' ').first
        : '';
      final lastFromFull = (fullName != null && fullName.contains(' '))
        ? fullName.split(' ').skip(1).join(' ')
        : '';
      final firstName = (data['firstName'] as String?)?.trim();
      final lastName = (data['lastName'] as String?)?.trim();
      return {
        ...data,
        'id': id,
        'firstName': (firstName == null || firstName.isEmpty)
          ? firstFromFull
          : firstName,
        'lastName': (lastName == null || lastName.isEmpty)
          ? lastFromFull
          : lastName,
      };
      }()
    : null;
    if (!mounted) return;
    setState(() {
      _searching = false;
      _foundUser = user;
    });
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No user found with this email')),
      );
    }
  }

  Future<void> _sendInvite() async {
    if (!_formKey.currentState!.validate()) return;
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) return;
    setState(() => _sending = true);
  final prov = Provider.of<ProjectProvider>(context, listen: false);
  prov.sendInvites(projectId: widget.project.id, emails: [email]);
  await prov.refreshInvitesForProject(widget.project.id);
  // Also refresh my invites cache so Requests tab shows immediately
  await prov.fetchMyInvites();
    if (!mounted) return;
    setState(() => _sending = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Invite sent')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final prov = Provider.of<ProjectProvider>(context);
    final invites = prov.invites(widget.project.id);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Invite Users',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Form(
              key: _formKey,
              child: Column(
                children: [
                  CustomTextField(
                    label: 'User Email',
                    hintText: 'e.g., user@example.com',
                    controller: _emailCtrl,
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Enter an email to search'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: CustomButton(
                          text: 'Search',
                          isLoading: _searching,
                          onPressed: _searchUser,
                          height: 48,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: CustomButton(
                          text: 'Send Invite',
                          isLoading: _sending,
                          onPressed: _sendInvite, // allow sending by email even if not registered yet
                          height: 48,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _foundUser == null && !_searching && _emailCtrl.text.isNotEmpty
                          ? 'No user found for ${_emailCtrl.text.trim()}'
                          : '',
                      style: TextStyle(color: Colors.red[600], fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (_foundUser != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      child: Text(() {
                        final fn = (_foundUser!['firstName'] ?? '') as String;
                        final ln = (_foundUser!['lastName'] ?? '') as String;
                        final full = (_foundUser!['fullName'] ?? '') as String;
                        final display = ('$fn $ln').trim().isNotEmpty
                            ? ('$fn $ln').trim()
                            : (full.isNotEmpty ? full : (_foundUser!['email'] ?? '') as String);
                        return display.isNotEmpty
                            ? display[0].toUpperCase()
                            : 'U';
                      }()),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(() {
                            final fn = (_foundUser!['firstName'] ?? '') as String;
                            final ln = (_foundUser!['lastName'] ?? '') as String;
                            final full = (_foundUser!['fullName'] ?? '') as String;
                            final display = ('$fn $ln').trim().isNotEmpty
                                ? ('$fn $ln').trim()
                                : (full.isNotEmpty ? full : '');
                            return display;
                          }(),
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            _foundUser!['email'] ?? '',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.check_circle, color: Colors.green),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            const Text(
              'Invitations',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            if (invites.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
                ),
                child: Text(
                  'No invites yet',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              )
            else
              ...invites.map((i) => _inviteTile(context, i)),
          ],
        ),
      ),
    );
  }

  Widget _inviteTile(BuildContext context, ProjectInvite invite) {
    Color color;
    switch (invite.status) {
      case InviteStatus.pending:
        color = Colors.orange;
        break;
      case InviteStatus.accepted:
        color = Colors.green;
        break;
      case InviteStatus.rejected:
        color = Colors.red;
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.1),
          child: Icon(Icons.email, color: color),
        ),
        title: Text(invite.email),
        subtitle: Text('Status: ${invite.status.name}'),
        trailing: null,
      ),
    );
  }
}
