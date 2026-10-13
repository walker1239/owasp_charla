import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/session.dart';
import '../../models/account.dart';
import 'account_detail_screen.dart';

class AccountsScreen extends StatelessWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final token = state.token!;
    return Scaffold(
      appBar: AppBar(title: const Text('Mis cuentas')),
      body: FutureBuilder<List<Account>>(
        future: state.api.accounts(token),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final accounts = snapshot.data!;
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: accounts.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final a = accounts[i];
              return Card(
                child: ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.savings)),
                  title: Text(a.number),
                  subtitle: Text('Saldo: ${a.balance.toStringAsFixed(2)} ${a.currency}'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => AccountDetailScreen(account: a),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
