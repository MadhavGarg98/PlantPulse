import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/notification_service.dart';

class PushNotificationDemoScreen extends StatefulWidget {
  const PushNotificationDemoScreen({super.key});

  @override
  State<PushNotificationDemoScreen> createState() => _PushNotificationDemoScreenState();
}

class _PushNotificationDemoScreenState extends State<PushNotificationDemoScreen> with TickerProviderStateMixin {
  final NotificationService _notificationService = NotificationService();
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  
  String? _fcmToken;
  String _permissionStatus = 'Checking...';
  List<RemoteMessage> _receivedMessages = [];
  late AnimationController _pulseController;
  late AnimationController _fadeController;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadNotificationData();
    _listenToMessages();
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
  }

  Future<void> _loadNotificationData() async {
    await _getFCMToken();
    await _checkPermissions();
    _fadeController.forward();
  }

  Future<void> _getFCMToken() async {
    final token = _notificationService.fcmToken;
    setState(() {
      _fcmToken = token;
    });
  }

  Future<void> _checkPermissions() async {
    final settings = await _messaging.getNotificationSettings();
    setState(() {
      _permissionStatus = _getPermissionStatusText(settings.authorizationStatus);
    });
  }

  String _getPermissionStatusText(AuthorizationStatus status) {
    switch (status) {
      case AuthorizationStatus.authorized:
        return '✅ Authorized';
      case AuthorizationStatus.provisional:
        return '⚠️ Provisional';
      case AuthorizationStatus.denied:
        return '❌ Denied';
      case AuthorizationStatus.notDetermined:
        return '❓ Not Determined';
      default:
        return '❓ Unknown';
    }
  }

  void _listenToMessages() {
    _notificationService.messageStream?.listen((message) {
      setState(() {
        _receivedMessages.insert(0, message);
        if (_receivedMessages.length > 10) {
          _receivedMessages.removeLast();
        }
      });
    });
  }

  Future<void> _requestPermissions() async {
    await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
    await _checkPermissions();
  }

  Future<void> _subscribeToTopic() async {
    await _notificationService.subscribeToTopic('plantpulse_demo');
    _showSnackBar('✅ Subscribed to plantpulse_demo topic');
  }

  Future<void> _unsubscribeFromTopic() async {
    await _notificationService.unsubscribeFromTopic('plantpulse_demo');
    _showSnackBar('✅ Unsubscribed from plantpulse_demo topic');
  }

  void _copyTokenToClipboard() {
    if (_fcmToken != null) {
      // In a real app, you'd use flutter/services to copy to clipboard
      _showSnackBar('📋 Token copied to clipboard (check console)');
      print('📱 FCM Token: $_fcmToken');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF1B5E20),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Push Notifications',
          style: TextStyle(
            color: Color(0xFF1B5E20),
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1B5E20)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 32),
            _buildStatusCards(),
            const SizedBox(height: 32),
            _buildTokenSection(),
            const SizedBox(height: 32),
            _buildActionButtons(),
            const SizedBox(height: 32),
            _buildMessagesSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1B5E20), Color(0xFF4CAF50)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1B5E20).withOpacity(0.2),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(
            Icons.notifications_active,
            color: Colors.white,
            size: 28,
          ),
        ).animate(controller: _pulseController).scale(
          duration: const Duration(seconds: 2),
          curve: Curves.easeInOut,
          begin: const Offset(1.0, 1.0),
          end: const Offset(1.1, 1.1),
        ).then().scale(
          duration: const Duration(seconds: 2),
          curve: Curves.easeInOut,
          begin: const Offset(1.1, 1.1),
          end: const Offset(1.0, 1.0),
        ),
        const SizedBox(height: 16),
        const Text(
          'Firebase Cloud Messaging',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1B5E20),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Manage push notifications and test FCM functionality',
          style: TextStyle(
            fontSize: 16,
            color: Color(0xFF6B7280),
          ),
        ),
      ],
    ).animate(controller: _fadeController).fadeIn(duration: const Duration(milliseconds: 600));
  }

  Widget _buildStatusCards() {
    return Row(
      children: [
        Expanded(
          child: _buildStatusCard(
            'Permission Status',
            _permissionStatus,
            Icons.security,
            const Color(0xFF4CAF50),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatusCard(
            'Messages Received',
            '${_receivedMessages.length}',
            Icons.message,
            const Color(0xFF2196F3),
          ),
        ),
      ],
    ).animate(controller: _fadeController).fadeIn(delay: const Duration(milliseconds: 200));
  }

  Widget _buildStatusCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF6B7280),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              color: Color(0xFF111111),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTokenSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'FCM Registration Token',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF111111),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _fcmToken ?? 'Loading...',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                    fontFamily: 'monospace',
                  ),
                ),
                if (_fcmToken != null) ...[
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _copyTokenToClipboard,
                    icon: const Icon(Icons.copy, size: 16),
                    label: const Text('Copy Token'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1B5E20),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 40),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    ).animate(controller: _fadeController).fadeIn(delay: const Duration(milliseconds: 400));
  }

  Widget _buildActionButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Actions',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF111111),
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            ElevatedButton.icon(
              onPressed: _requestPermissions,
              icon: const Icon(Icons.notifications, size: 18),
              label: const Text('Request Permission'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1B5E20),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
            ElevatedButton.icon(
              onPressed: _subscribeToTopic,
              icon: const Icon(Icons.add_circle, size: 18),
              label: const Text('Subscribe Topic'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
            ElevatedButton.icon(
              onPressed: _unsubscribeFromTopic,
              icon: const Icon(Icons.remove_circle, size: 18),
              label: const Text('Unsubscribe Topic'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF9800),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
          ],
        ),
      ],
    ).animate(controller: _fadeController).fadeIn(delay: const Duration(milliseconds: 600));
  }

  Widget _buildMessagesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Received Messages',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF111111),
          ),
        ),
        const SizedBox(height: 16),
        if (_receivedMessages.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Center(
              child: Column(
                children: [
                  Icon(
                    Icons.notifications_none,
                    size: 48,
                    color: Color(0xFF9CA3AF),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No messages received yet',
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Send a test notification from Firebase Console',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF9CA3AF),
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ..._receivedMessages.map((message) => _buildMessageCard(message)).toList(),
      ],
    ).animate(controller: _fadeController).fadeIn(delay: const Duration(milliseconds: 800));
  }

  Widget _buildMessageCard(RemoteMessage message) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.notifications,
                color: Color(0xFF1B5E20),
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  message.notification?.title ?? 'No Title',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111111),
                  ),
                ),
              ),
              Text(
                _formatTimestamp(message.sentTime),
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF9CA3AF),
                ),
              ),
            ],
          ),
          if (message.notification?.body != null) ...[
            const SizedBox(height: 8),
            Text(
              message.notification!.body!,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
              ),
            ),
          ],
          if (message.data.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Data: ${message.data}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF6B7280),
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime? timestamp) {
    if (timestamp == null) return 'Unknown';
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    return '${difference.inDays}d ago';
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _fadeController.dispose();
    super.dispose();
  }
}
