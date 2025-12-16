import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/routes/app_router.dart';
import '../../../data/services/auth_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _handleLogout(BuildContext context) async {
    // Afficher une confirmation
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Voulez-vous vraiment vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Déconnexion'),
          ),
        ],
      ),
    );

    if (shouldLogout == true && context.mounted) {
      try {
        await AuthService().signOut();
        if (context.mounted) {
          context.go(AppRouter.login);
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur lors de la déconnexion: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paramètres'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: ListView(
        children: [
          const SizedBox(height: 20),
          
          // Section Compte
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'COMPTE',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          
          ListTile(
            leading: const Icon(Icons.person_outline, color: Colors.blue),
            title: const Text('Profil'),
            subtitle: const Text('Gérer vos informations personnelles'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Fonctionnalité à venir')),
              );
            },
          ),
          
          const Divider(height: 1),
          
          ListTile(
            leading: const Icon(Icons.business, color: Colors.blue),
            title: const Text('Entreprise'),
            subtitle: const Text('Informations de votre entreprise'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Fonctionnalité à venir')),
              );
            },
          ),
          
          const SizedBox(height: 20),
          
          // Section App
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'APPLICATION',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          
          ListTile(
            leading: const Icon(Icons.notifications, color: Colors.blue),
            title: const Text('Notifications'),
            subtitle: const Text('Gérer les notifications'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Fonctionnalité à venir')),
              );
            },
          ),
          
          const Divider(height: 1),
          
          ListTile(
            leading: const Icon(Icons.help_outline, color: Colors.blue),
            title: const Text('Aide & Support'),
            subtitle: const Text('Besoin d\'aide ?'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Fonctionnalité à venir')),
              );
            },
          ),
          
          const SizedBox(height: 20),
          
          // Section Déconnexion
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'SESSION',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text(
              'Déconnexion',
              style: TextStyle(color: Colors.red),
            ),
            onTap: () => _handleLogout(context),
          ),
          
          const SizedBox(height: 40),
          
          // Version de l'app
          const Center(
            child: Text(
              'SiteVoice AI v1.0.0',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}


