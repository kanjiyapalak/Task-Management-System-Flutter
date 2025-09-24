import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/project_invite.dart';
import '../../services/project_provider.dart';
import '../../services/firebase_auth_provider.dart';

class RequestsScreen extends StatefulWidget {
  const RequestsScreen({super.key});

  @override
  State<RequestsScreen> createState() => _RequestsScreenState();
}

class _RequestsScreenState extends State<RequestsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Requests'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Received'),
            Tab(text: 'Sent'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _ReceivedInvitesTab(),
          _SentInvitesTab(),
        ],
      ),
    );
  }
}

class _ReceivedInvitesTab extends StatelessWidget {
  const _ReceivedInvitesTab();

  @override
  Widget build(BuildContext context) {
    final prov = Provider.of<ProjectProvider>(context, listen: false);
    return FutureBuilder<List<ProjectInvite>>(
      future: prov.fetchMyInvites(),
      builder: (context, snapshot) {
        final invites = snapshot.data ?? const <ProjectInvite>[];
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (invites.isEmpty) {
          return const Center(child: Text('No invites'));
        }
        return ListView.builder(
          itemCount: invites.length,
          itemBuilder: (context, index) {
            final inv = invites[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: ListTile(
                leading: const Icon(Icons.mail_outline),
                title: Text(inv.email),
                subtitle: Text('Status: ${inv.status.name}'),
                trailing: inv.status == InviteStatus.pending
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextButton(
                            onPressed: () async {
                              final ok = await prov.respondToInvite(
                                inviteId: inv.id,
                                accept: true,
                              );
                              if (!context.mounted) return;
                              if (ok) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Invite accepted'),
                                  ),
                                );
                                // Refresh
                                (context as Element).markNeedsBuild();
                              }
                            },
                            child: const Text('Accept'),
                          ),
                          const SizedBox(width: 8),
                          TextButton(
                            onPressed: () async {
                              final ok = await prov.respondToInvite(
                                inviteId: inv.id,
                                accept: false,
                              );
                              if (!context.mounted) return;
                              if (ok) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Invite declined'),
                                  ),
                                );
                                (context as Element).markNeedsBuild();
                              }
                            },
                            child: const Text('Decline'),
                          ),
                        ],
                      )
                    : null,
              ),
            );
          },
        );
      },
    );
  }
}

class _SentInvitesTab extends StatelessWidget {
  const _SentInvitesTab();

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final prov = Provider.of<ProjectProvider>(context, listen: false);
    final uid = auth.currentUser?.id;
    if (uid == null) return const Center(child: Text('Sign in to view'));

    return FutureBuilder<List<ProjectInvite>>(
      future: prov.fetchSentInvitesBy(uid),
      builder: (context, snapshot) {
        final invites = snapshot.data ?? const <ProjectInvite>[];
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (invites.isEmpty) {
          return const Center(child: Text('No sent invites'));
        }
        return ListView.builder(
          itemCount: invites.length,
          itemBuilder: (context, index) {
            final inv = invites[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: ListTile(
                leading: const Icon(Icons.outgoing_mail),
                title: Text(inv.email),
                subtitle: Text('Status: ${inv.status.name}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (inv.status == InviteStatus.pending)
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        tooltip: 'Delete invite',
                        onPressed: () async {
                          final ok = await prov.deleteInvite(inv.id);
                          if (!context.mounted) return;
                          if (ok) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Invite deleted'),
                              ),
                            );
                            (context as Element).markNeedsBuild();
                          }
                        },
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
