import 'package:flutter/material.dart';
import 'welcome_screen.dart';
import 'counter_screen.dart';

class ResponsiveHome extends StatelessWidget {
  const ResponsiveHome({super.key});

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    bool isTablet = screenWidth > 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Responsive PlantPulse"),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Header Section
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(isTablet ? 30 : 16),
            color: Colors.green.shade100,
            child: Text(
              "Welcome to PlantPulse 🌱",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: isTablet ? 28 : 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // Main Content
          Expanded(
            child: isTablet
                ? _buildTabletLayout()
                : _buildPhoneLayout(),
          ),

          // Footer Section with Navigation Buttons
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(isTablet ? 20 : 12),
            child: Column(
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const WelcomeScreen(), // 🔁 Replace later
                      ),
                    );
                  },
                  child: const Text("Welcome"),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const CounterScreen(), // 🔁 Replace later
                      ),
                    );
                  },
                  child: const Text("Count Plant"),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  // Phone Layout (Single Column)
  Widget _buildPhoneLayout() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _cardItem("Water Reminder 💧"),
        _cardItem("Track Growth 📈"),
        _cardItem("Plant Tips 🌿"),
      ],
    );
  }

  // Tablet Layout (Grid)
  Widget _buildTabletLayout() {
    return GridView.count(
      padding: const EdgeInsets.all(20),
      crossAxisCount: 2,
      crossAxisSpacing: 20,
      mainAxisSpacing: 20,
      children: [
        _cardItem("Water Reminder 💧"),
        _cardItem("Track Growth 📈"),
        _cardItem("Plant Tips 🌿"),
        _cardItem("Weather Sync ☀️"),
      ],
    );
  }

  Widget _cardItem(String title) {
    return Card(
      elevation: 4,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18),
          ),
        ),
      ),
    );
  }
}