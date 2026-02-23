import 'package:flutter/material.dart';

class ResponsiveLayout extends StatelessWidget {
  const ResponsiveLayout({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final bool isSmallScreen = size.width < 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Responsive Layout Demo'),
      ),
      body: Container(
        padding: const EdgeInsets.all(16),
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(context, isSmallScreen),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: _buildResponsiveContent(context, isSmallScreen),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isSmallScreen) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PlantPulse Responsive Layout',
            style: theme.textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            isSmallScreen
                ? 'Using a vertical Column layout for small screens.'
                : 'Using a horizontal Row layout for larger screens.',
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildResponsiveContent(BuildContext context, bool isSmallScreen) {
    final theme = Theme.of(context);

    if (isSmallScreen) {
      // Small screens: stack content vertically using Column.
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildContentSection(
            context,
            title: 'Section A',
            description:
                'On small screens, content sections are stacked vertically '
                'inside a Column. This keeps the layout readable on phones.',
            icon: Icons.spa_outlined,
            theme: theme,
          ),
          const SizedBox(height: 16),
          _buildContentSection(
            context,
            title: 'Section B',
            description:
                'Each section is wrapped in a Container and the Column is '
                'wrapped with a SingleChildScrollView to avoid overflow.',
            icon: Icons.eco_outlined,
            theme: theme,
          ),
        ],
      );
    } else {
      // Large screens: place content side‑by‑side using Row + Expanded.
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _buildContentSection(
              context,
              title: 'Section A',
              description:
                  'On larger screens (width ≥ 600), the two content sections '
                  'are displayed side‑by‑side using a Row and Expanded widgets.',
              icon: Icons.spa_outlined,
              theme: theme,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildContentSection(
              context,
              title: 'Section B',
              description:
                  'Expanded makes each section adapt to the available width so '
                  'there are no hard‑coded sizes that could cause overflow.',
              icon: Icons.eco_outlined,
              theme: theme,
            ),
          ),
        ],
      );
    }
  }

  Widget _buildContentSection(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required ThemeData theme,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.headlineMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

