import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../core/session.dart';
import '../../models/account.dart';
import '../../models/beneficiary.dart';

class TransferScreen extends StatefulWidget {
  const TransferScreen({super.key});

  @override
  State<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends State<TransferScreen> {
  final _search = TextEditingController();
  final _amount = TextEditingController();
  final _toNumber = TextEditingController();

  List<Account> _accounts = [];
  Account? _from;
  List<Beneficiary> _results = [];
  bool _busy = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadAccounts());
  }

  @override
  void dispose() {
    _search.dispose();
    _amount.dispose();
    _toNumber.dispose();
    super.dispose();
  }

  Future<void> _loadAccounts() async {
    final state = context.read<AppState>();
    final accounts = await state.api.accounts(state.token!);
    setState(() {
      _accounts = accounts;
      _from = accounts.isNotEmpty ? accounts.first : null;
    });
  }

  Future<void> _doSearch() async {
    final state = context.read<AppState>();
    setState(() => _busy = true);
    try {
      final results = await state.api.searchBeneficiaries(state.token!, _search.text);
      setState(() => _results = results);
    } catch (e) {
      setState(() => _message = 'Error: $e');
    } finally {
      setState(() => _busy = false);
    }
  }

  Future<void> _transfer() async {
    final state = context.read<AppState>();
    final amount = double.tryParse(_amount.text) ?? 0;
    if (_from == null || _toNumber.text.isEmpty || amount <= 0) {
      setState(() => _message = 'Completa los datos');
      return;
    }
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final balance = await state.api.transfer(
        state.token!,
        fromAccountId: _from!.id,
        toAccountNumber: _toNumber.text.trim(),
        amount: amount,
      );
      setState(() => _message = 'Transferido. Nuevo saldo: ${balance.toStringAsFixed(2)}');
    } on ApiException catch (e) {
      setState(() => _message = e.message);
    } catch (e) {
      setState(() => _message = 'Error: $e');
    } finally {
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Transferir')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          DropdownButtonFormField<Account>(
            initialValue: _from,
            decoration: const InputDecoration(
              labelText: 'Cuenta origen',
              border: OutlineInputBorder(),
            ),
            items: [
              for (final a in _accounts)
                DropdownMenuItem(
                  value: a,
                  child: Text('${a.number} — ${a.balance.toStringAsFixed(2)} ${a.currency}'),
                ),
            ],
            onChanged: (a) => setState(() => _from = a),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _search,
            decoration: InputDecoration(
              labelText: 'Buscar beneficiario',
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: const Icon(Icons.search),
                onPressed: _busy ? null : _doSearch,
              ),
            ),
            onSubmitted: (_) => _doSearch(),
          ),
          for (final b in _results)
            ListTile(
              dense: true,
              leading: const Icon(Icons.person_outline),
              title: Text('${b.alias} · ${b.bank}'),
              subtitle: Text(b.accountNumber),
              onTap: () => setState(() => _toNumber.text = b.accountNumber),
            ),
          const SizedBox(height: 16),
          TextField(
            controller: _toNumber,
            decoration: const InputDecoration(
              labelText: 'Cuenta destino',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _amount,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Monto',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _busy ? null : _transfer,
            child: _busy
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Transferir'),
          ),
          if (_message != null) ...[
            const SizedBox(height: 16),
            Text(_message!),
          ],
        ],
      ),
    );
  }
}
