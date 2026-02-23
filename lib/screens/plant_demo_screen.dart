import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PlantDemoScreen extends StatelessWidget {
  const PlantDemoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Get the arguments passed from the previous screen
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
    
    final plantName = args?['plantName'] ?? 'Unknown Plant';
    final plantType = args?['plantType'] ?? 'Unknown Type';
    final wateringDays = args?['wateringDays'] ?? 7;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F7),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: const Color(0xFF1B5E20),
        title: Text(
          'Plant Details',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Data Received Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF1B5E20),
                    const Color(0xFF4CAF50),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1B5E20).withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Data Received from Previous Screen:',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.9),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildDataRow('Plant Name', plantName),
                  _buildDataRow('Plant Type', plantType),
                  _buildDataRow('Watering Schedule', 'Every $wateringDays days'),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Plant Information Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
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
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1B5E20).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.eco,
                          color: Color(0xFF1B5E20),
                          size: 30,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              plantName,
                              style: GoogleFonts.inter(
                                fontSize: 22,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF1B5E20),
                              ),
                            ),
                            Text(
                              plantType,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  
                  Text(
                    'Care Instructions',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1B5E20),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildCareItem('Watering', 'Every $wateringDays days'),
                  _buildCareItem('Light', 'Bright, indirect sunlight'),
                  _buildCareItem('Temperature', '18-24°C'),
                  _buildCareItem('Humidity', '60-80%'),
                ],
              ),
            ),
            
            const Spacer(),
            
            // Navigation Info
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1B5E20).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Navigation Demo Complete!',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1B5E20),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You have successfully:\n'
                    '• Used Navigator.pushNamed() with arguments\n'
                    '• Passed data between screens\n'
                    '• Retrieved and displayed the data',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.grey[700],
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Navigation Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF1B5E20),
                      side: const BorderSide(color: Color(0xFF1B5E20)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      'Back',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      // Go back to home by popping twice
                      Navigator.pop(context);
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1B5E20),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      'Home',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.white.withOpacity(0.8),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCareItem(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            Icons.check_circle,
            color: const Color(0xFF4CAF50),
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$title: $description',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
