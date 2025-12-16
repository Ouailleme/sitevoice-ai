import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/theme/app_theme.dart';

/// Dashboard Web pour Managers
/// Vue d'ensemble : KPIs, Charts, Map, Facturation
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  // Navigation items
  final List<NavigationRailDestination> _destinations = const [
    NavigationRailDestination(
      icon: Icon(Icons.dashboard_outlined),
      selectedIcon: Icon(Icons.dashboard),
      label: Text('Vue d\'ensemble'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.map_outlined),
      selectedIcon: Icon(Icons.map),
      label: Text('Carte'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.receipt_long_outlined),
      selectedIcon: Icon(Icons.receipt_long),
      label: Text('Facturation'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.people_outline),
      selectedIcon: Icon(Icons.people),
      label: Text('Équipe'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.settings_outlined),
      selectedIcon: Icon(Icons.settings),
      label: Text('Paramètres'),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Navigation Rail (Sidebar)
          _buildNavigationRail(),
          
          // Main Content
          Expanded(
            child: _buildMainContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationRail() {
    return NavigationRail(
      selectedIndex: _selectedIndex,
      onDestinationSelected: (int index) {
        setState(() {
          _selectedIndex = index;
        });
      },
      extended: MediaQuery.of(context).size.width > 1200,
      destinations: _destinations,
      leading: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(
              Icons.engineering,
              size: 40,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 8),
            if (MediaQuery.of(context).size.width > 1200)
              const Text(
                'SiteVoice AI',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    switch (_selectedIndex) {
      case 0:
        return const _OverviewTab();
      case 1:
        return const _MapTab();
      case 2:
        return const _InvoicingTab();
      case 3:
        return const _TeamTab();
      case 4:
        return const _SettingsTab();
      default:
        return const _OverviewTab();
    }
  }
}

// =====================================================
// OVERVIEW TAB (Vue d'ensemble)
// =====================================================

class _OverviewTab extends StatelessWidget {
  const _OverviewTab();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Vue d\'ensemble',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Dernière mise à jour: ${DateTime.now().hour}:${DateTime.now().minute}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey,
                        ),
                  ),
                ],
              ),
              _buildPeriodSelector(),
            ],
          ),
          
          const SizedBox(height: 32),
          
          // KPI Cards
          _buildKPIRow(context),
          
          const SizedBox(height: 32),
          
          // Charts Row
          _buildChartsRow(context),
          
          const SizedBox(height: 32),
          
          // Recent Activity
          _buildRecentActivity(context),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return SegmentedButton<String>(
      segments: const [
        ButtonSegment(value: '7d', label: Text('7 jours')),
        ButtonSegment(value: '30d', label: Text('30 jours')),
        ButtonSegment(value: '90d', label: Text('3 mois')),
      ],
      selected: const {'30d'},
      onSelectionChanged: (Set<String> newSelection) {
        // TODO: Change period
      },
    );
  }

  Widget _buildKPIRow(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 1400 ? 4 : 2;
        
        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 2.5,
          children: [
            _buildKPICard(
              context,
              title: 'CA du mois',
              value: '12,450€',
              change: '+12.5%',
              isPositive: true,
              icon: Icons.euro,
              color: context.successColor,
            ),
            _buildKPICard(
              context,
              title: 'Interventions',
              value: '47',
              change: '+8',
              isPositive: true,
              icon: Icons.work_outline,
              color: context.infoColor,
            ),
            _buildKPICard(
              context,
              title: 'Temps moyen',
              value: '2h 15m',
              change: '-15m',
              isPositive: true,
              icon: Icons.timer_outlined,
              color: context.warningColor,
            ),
            _buildKPICard(
              context,
              title: 'Satisfaction',
              value: '4.8/5',
              change: '+0.2',
              isPositive: true,
              icon: Icons.star_outline,
              color: AppTheme.seedColor,
            ),
          ],
        );
      },
    );
  }

  Widget _buildKPICard(
    BuildContext context, {
    required String title,
    required String value,
    required String change,
    required bool isPositive,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey,
                      ),
                ),
                Icon(icon, color: color, size: 20),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  value,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: (isPositive ? context.successColor : context.errorColor)
                        .withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                        size: 14,
                        color: isPositive ? context.successColor : context.errorColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        change,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isPositive ? context.successColor : context.errorColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartsRow(BuildContext context) {
    return Row(
      children: [
        // Revenue Chart
        Expanded(
          flex: 2,
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Chiffre d\'affaires',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 300,
                    child: _buildRevenueChart(context),
                  ),
                ],
              ),
            ),
          ),
        ),
        
        const SizedBox(width: 16),
        
        // Interventions by Type
        Expanded(
          flex: 1,
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Par type',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 300,
                    child: _buildPieChart(context),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRevenueChart(BuildContext context) {
    return LineChart(
      LineChartData(
        gridData: FlGridData(show: true, drawVerticalLine: false),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                const days = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
                if (value.toInt() >= 0 && value.toInt() < days.length) {
                  return Text(days[value.toInt()]);
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text('${value.toInt()}€');
              },
            ),
          ),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: const [
              FlSpot(0, 1200),
              FlSpot(1, 1800),
              FlSpot(2, 1600),
              FlSpot(3, 2200),
              FlSpot(4, 1900),
              FlSpot(5, 2400),
              FlSpot(6, 2100),
            ],
            isCurved: true,
            color: AppTheme.seedColor,
            barWidth: 3,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: AppTheme.seedColor.withOpacity(0.1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPieChart(BuildContext context) {
    return PieChart(
      PieChartData(
        sections: [
          PieChartSectionData(
            value: 40,
            title: 'Plomberie\n40%',
            color: AppTheme.seedColor,
            radius: 80,
          ),
          PieChartSectionData(
            value: 30,
            title: 'Chauffage\n30%',
            color: context.successColor,
            radius: 80,
          ),
          PieChartSectionData(
            value: 20,
            title: 'Électricité\n20%',
            color: context.warningColor,
            radius: 80,
          ),
          PieChartSectionData(
            value: 10,
            title: 'Autre\n10%',
            color: Colors.grey,
            radius: 80,
          ),
        ],
        sectionsSpace: 2,
        centerSpaceRadius: 40,
      ),
    );
  }

  Widget _buildRecentActivity(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Activité récente',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 5,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppTheme.seedColor.withOpacity(0.1),
                    child: const Icon(Icons.work_outline, color: AppTheme.seedColor),
                  ),
                  title: const Text('Intervention chez M. Dupont'),
                  subtitle: const Text('12 rue Victor Hugo - Chaudière'),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '450€',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(
                        'Il y a 2h',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey,
                            ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// =====================================================
// PLACEHOLDER TABS (À implémenter)
// =====================================================

class _MapTab extends StatelessWidget {
  const _MapTab();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.map, size: 100, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'Carte des interventions',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'À venir : Google Maps avec marqueurs interactifs',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class _InvoicingTab extends StatelessWidget {
  const _InvoicingTab();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long, size: 100, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'Gestion de la facturation',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'À venir : Éditeur drag & drop de factures',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class _TeamTab extends StatelessWidget {
  const _TeamTab();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people, size: 100, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'Gestion de l\'équipe',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'À venir : Liste des techniciens, performances, planning',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class _SettingsTab extends StatelessWidget {
  const _SettingsTab();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.settings, size: 100, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'Paramètres',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'À venir : Configuration entreprise, intégrations, webhooks',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}




