import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/session.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final user = state.user;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: () => context.read<AppState>().logout(),
          ),
        ],
      ),
      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const CircleAvatar(radius: 40, child: Icon(Icons.person, size: 40)),
                const SizedBox(height: 16),
                Center(child: Text(user.name, style: Theme.of(context).textTheme.titleLarge)),
                const SizedBox(height: 24),
                ListTile(
                  leading: const Icon(Icons.email_outlined),
                  title: const Text('Correo'),
                  subtitle: Text(user.email),
                ),
                ListTile(
                  leading: const Icon(Icons.badge_outlined),
                  title: const Text('Rol'),
                  subtitle: Text(user.role),
                ),
                const Divider(),
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'La sesión se guarda en el almacén seguro del sistema '
                    '(Keystore / Keychain).',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ),
              ],
            ),
    );
  }
}
