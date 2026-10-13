import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/session.dart';
import '../../models/account.dart';

class AccountDetailScreen extends StatelessWidget {
  const AccountDetailScreen({super.key, required this.account});

  final Account account;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Scaffold(
      appBar: AppBar(title: Text(account.number)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Saldo disponible'),
                    const SizedBox(height: 8),
                    Text(
                      '${account.balance.toStringAsFixed(2)} ${account.currency}',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Movimientos', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Transaction>>(
              future: state.api.transactions(state.token!, account.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                final txs = snapshot.data!;
                if (txs.isEmpty) {
                  return const Center(child: Text('Sin movimientos'));
                }
                return ListView.builder(
                  itemCount: txs.length,
                  itemBuilder: (context, i) {
                    final t = txs[i];
                    final positive = t.amount >= 0;
                    return ListTile(
                      leading: Icon(
                        positive ? Icons.arrow_downward : Icons.arrow_upward,
                        color: positive ? Colors.green : Colors.red,
                      ),
                      title: Text(t.concept),
                      subtitle: Text(t.createdAt),
                      trailing: Text(
                        '${positive ? '+' : ''}${t.amount.toStringAsFixed(2)}',
                        style: TextStyle(color: positive ? Colors.green : Colors.red),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
