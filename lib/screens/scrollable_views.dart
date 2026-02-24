import 'package:flutter/material.dart';

class Plant {
  final String id;
  final String name;
  final String scientificName;
  final DateTime lastWatered;
  final String imageUrl;
  final bool isHealthy;

  Plant({
    required this.id,
    required this.name,
    required this.scientificName,
    required this.lastWatered,
    required this.imageUrl,
    required this.isHealthy,
  });
}

class ScrollableViews extends StatefulWidget {
  const ScrollableViews({super.key});

  @override
  State<ScrollableViews> createState() => _ScrollableViewsState();
}

class _ScrollableViewsState extends State<ScrollableViews> {
  final List<Plant> _plants = [
    Plant(
      id: '1',
      name: 'Monstera',
      scientificName: 'Monstera Deliciosa',
      lastWatered: DateTime.now().subtract(const Duration(days: 3)),
      imageUrl:
          'https://images.unsplash.com/photo-1416879595882-3373a0480b5b',
      isHealthy: true,
    ),
    Plant(
      id: '2',
      name: 'Peace Lily',
      scientificName: 'Spathiphyllum',
      lastWatered: DateTime.now().subtract(const Duration(days: 1)),
      imageUrl:
          'https://images.unsplash.com/photo-1520302630521-3db954e9e0c7',
      isHealthy: true,
    ),
    Plant(
      id: '3',
      name: 'Snake Plant',
      scientificName: 'Sansevieria',
      lastWatered: DateTime.now().subtract(const Duration(days: 5)),
      imageUrl:
          'https://images.unsplash.com/photo-1485955900006-10f4d324d411',
      isHealthy: false,
    ),
    Plant(
      id: '4',
      name: 'Aloe Vera',
      scientificName: 'Aloe Barbadensis',
      lastWatered: DateTime.now().subtract(const Duration(days: 2)),
      imageUrl:
          'https://images.unsplash.com/photo-1501004318641-b39e6451bec6',
      isHealthy: true,
    ),
    Plant(
      id: '5',
      name: 'Fiddle Leaf Fig',
      scientificName: 'Ficus Lyrata',
      lastWatered: DateTime.now().subtract(const Duration(days: 4)),
      imageUrl:
          'https://images.unsplash.com/photo-1587502537104-aac10f5b70e4',
      isHealthy: true,
    ),
  ];

  String getWateredDays(DateTime date) {
    final difference = DateTime.now().difference(date).inDays;
    return "Watered $difference days ago";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Plants"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ===== NEW PLANTS (HORIZONTAL LIST) =====
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                "New Plants",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),

            SizedBox(
              height: 200,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _plants.length,
                itemBuilder: (context, index) {
                  final plant = _plants[index];

                  return Container(
                    width: 160,
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      image: DecorationImage(
                        image: NetworkImage(plant.imageUrl),
                        fit: BoxFit.cover,
                      ),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(
                          colors: [
                            Colors.black.withOpacity(0.6),
                            Colors.transparent,
                          ],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                      ),
                      alignment: Alignment.bottomLeft,
                      child: Text(
                        plant.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const Divider(thickness: 2),

            // ===== YOUR PLANTS (GRID) =====
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                "Your Plants",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _plants.length,
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.8,
                ),
                itemBuilder: (context, index) {
                  final plant = _plants[index];

                  return Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      image: DecorationImage(
                        image: NetworkImage(plant.imageUrl),
                        fit: BoxFit.cover,
                      ),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(
                          colors: [
                            Colors.black.withOpacity(0.7),
                            Colors.transparent,
                          ],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                      ),
                      alignment: Alignment.bottomLeft,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                plant.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Spacer(),
                              Icon(
                                Icons.circle,
                                size: 12,
                                color: plant.isHealthy
                                    ? Colors.green
                                    : Colors.red,
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            plant.scientificName,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            getWateredDays(plant.lastWatered),
                            style: const TextStyle(
                              color: Colors.white60,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}