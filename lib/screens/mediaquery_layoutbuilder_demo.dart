import 'package:flutter/material.dart';

class AdaptiveDemoScreen extends StatelessWidget {
  const AdaptiveDemoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final Size screenSize = mediaQuery.size;
    final double screenWidth = screenSize.width;
    final double screenHeight = screenSize.height;

    return Scaffold(
      appBar: AppBar(
        title: const Text('MediaQuery & LayoutBuilder Demo'),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final double maxWidth = constraints.maxWidth;
            final bool isMobile = maxWidth < 600;

            // Proportional card width based on available width.
            final double cardWidth =
                (maxWidth * 0.8).clamp(0.0, 600.0); // 80% up to 600px

            Widget card(String title, String description, Color color) {
              return ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: cardWidth,
                ),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: color.withOpacity(0.4)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        description,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              );
            }

            final Widget header = Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Adaptive Layout Demo',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Screen width: ${screenWidth.toStringAsFixed(0)} px · '
                    'Screen height: ${screenHeight.toStringAsFixed(0)} px\n'
                    'Below layout switches between Column (mobile) and Row (tablet) '
                    'using LayoutBuilder and MediaQuery.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            );

            final Widget mobileLayout = Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 24),
                card(
                  'Mobile Layout',
                  'When the available width is less than 600 pixels, '
                  'content is stacked vertically using a Column. '
                  'Each container uses about 80% of the available width.',
                  Colors.green,
                ),
                const SizedBox(height: 16),
                card(
                  'Vertical Stacking',
                  'This layout is ideal for phones where vertical scrolling is '
                  'more natural and horizontal space is limited.',
                  Colors.teal,
                ),
                const SizedBox(height: 24),
              ],
            );

            final Widget tabletLayout = Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Center(
                    child: card(
                      'Tablet Layout',
                      'When the available width is 600 pixels or more, '
                      'content is arranged horizontally in a Row to take '
                      'advantage of extra horizontal space.',
                      Colors.indigo,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Center(
                    child: card(
                      'Horizontal Arrangement',
                      'Row + Expanded let both containers grow proportionally '
                      'without using fixed pixel widths, keeping the design '
                      'flexible on tablets and larger screens.',
                      Colors.deepPurple,
                    ),
                  ),
                ),
              ],
            );

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  header,
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: isMobile ? mobileLayout : tabletLayout,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

