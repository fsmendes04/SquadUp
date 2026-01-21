import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../widgets/header.dart';
import '../config/responsive_utils.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final darkBlue = const Color.fromARGB(255, 29, 56, 95);
  final primaryBlue = const Color.fromARGB(255, 81, 163, 230);
  bool _isLoading = false;
  bool _isMarkingAllRead = false;
  final Set<String> _processingNotifications = {};

  // Mock notifications data
  late List<Map<String, dynamic>> _notifications;

  @override
  void initState() {
    super.initState();
    _initializeMockNotifications();
  }

  void _initializeMockNotifications() {
    _notifications = [
      {
        'id': '1',
        'type': 'expense',
        'title': 'Nova despesa criada',
        'message': 'João adicionou uma despesa de €45.50',
        'groupName': 'Viagem Paris',
        'icon': Icons.monetization_on,
        'timestamp': DateTime.now().subtract(const Duration(minutes: 5)),
        'isRead': false,
        'actionData': {'groupId': '1', 'expenseId': '123'},
      },
      {
        'id': '2',
        'type': 'payment',
        'title': 'Pagamento realizado',
        'message': 'Pedro pagou €30.00 para você',
        'groupName': 'Trabalho',
        'icon': Icons.check_circle,
        'timestamp': DateTime.now().subtract(const Duration(hours: 2)),
        'isRead': true,
        'actionData': {'groupId': '3', 'paymentId': '789'},
      },
    ];
  }

  Future<void> _markAsRead(String notificationId) async {
    if (_processingNotifications.contains(notificationId)) return;
    final notification = _notifications.firstWhere((n) => n['id'] == notificationId);
    if (notification['isRead'] == true) return;
    
    setState(() {
      _processingNotifications.add(notificationId);
    });
    
    // Simulate API call
    await Future.delayed(const Duration(milliseconds: 300));
    
    if (mounted) {
      setState(() {
        final index = _notifications.indexWhere((n) => n['id'] == notificationId);
        if (index != -1) {
          _notifications[index]['isRead'] = true;
        }
        _processingNotifications.remove(notificationId);
      });
    }
  }

  Future<void> _deleteNotification(String notificationId) async {
    if (_processingNotifications.contains(notificationId)) return;
    
    setState(() {
      _processingNotifications.add(notificationId);
    });
    
    // Simulate API call
    await Future.delayed(const Duration(milliseconds: 300));
    
    if (mounted) {
      setState(() {
        _notifications.removeWhere((n) => n['id'] == notificationId);
        _processingNotifications.remove(notificationId);
      });
    }
  }

  Future<void> _markAllAsRead() async {
    if (_isMarkingAllRead || _notifications.isEmpty) return;
    
    setState(() {
      _isMarkingAllRead = true;
    });
    
    // Simulate API call
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (mounted) {
      setState(() {
        for (var notification in _notifications) {
          notification['isRead'] = true;
        }
        _isMarkingAllRead = false;
      });
    }
  }

  Future<void> _refreshNotifications() async {
    // Simulate refresh
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      setState(() {
        _initializeMockNotifications();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            CustomHeader(
              darkBlue: darkBlue,
              title: 'Notifications',
            ),
            r.verticalSpace(6),
            // Content
            Expanded(
              child: _notifications.isEmpty
                  ? _buildEmptyState()
                  : SingleChildScrollView(
                      padding: r.symmetricPadding(horizontal: 18),
                      child: Column(
                        children: [
                          r.verticalSpace(12),
                          ..._notifications.map((notification) {
                            return _buildNotificationCard(notification, r);
                          }).toList(),
                          r.verticalSpace(30),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final r = context.responsive;
    return Center(
      child: Padding(
        padding: r.symmetricPadding(horizontal: 32, vertical: 10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: r.width(400),
              height: r.height(400),
              child: Center(
                child: Opacity(
                  opacity: 0.12,
                  child: Image.asset(
                    'lib/images/logo_v3.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            Text(
              'Sem notificações',
              style: GoogleFonts.poppins(
                fontSize: r.fontSize(22),
                fontWeight: FontWeight.w400,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
            r.verticalSpace(40),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> notification, ResponsiveUtils r) {
    final isRead = notification['isRead'] as bool;
    final timestamp = notification['timestamp'] as DateTime;
    final isProcessing = _processingNotifications.contains(notification['id']);

    return Container(
      margin: r.padding(bottom: 14),
      decoration: BoxDecoration(
        color: isRead ? const Color(0xFFE0E0E0) : Colors.white,
        borderRadius: r.circularBorderRadius(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color:
                isRead
                    ? const Color(0xFFBDBDBD).withValues(alpha: .18)
                    : primaryBlue.withValues(alpha: .10),
            blurRadius: 0,
            spreadRadius: 2,
            offset: const Offset(0, 0),
          ),
        ],
        border: Border.all(
          color:
              isRead
                  ? const Color(0xFFBDBDBD)
                  : primaryBlue.withValues(alpha: .18),
          width: r.borderWidth(2.2),
        ),
      ),
      child: Padding(
        padding: r.symmetricPadding(horizontal: 10, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: r.padding(left: 10, top: 10, right: 10, bottom: 10),
                  decoration: BoxDecoration(
                    color:
                        isRead
                            ? Colors.white
                            : primaryBlue.withValues(alpha: 0.12),
                    borderRadius: r.circularBorderRadius(14),
                    border: Border.all(
                      color:
                          isRead
                              ? const Color(0xFFB2DFDB)
                              : primaryBlue.withValues(alpha: 0.18),
                      width: r.borderWidth(1.2),
                    ),
                  ),
                  child: Icon(
                    isRead ? Icons.check_circle : notification['icon'],
                    color:darkBlue,
                    size: r.iconSize(20),
                  ),
                ),
                r.horizontalSpace(10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notification['title'],
                        style: GoogleFonts.poppins(
                          fontSize: r.fontSize(15),
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                          height: 1.3,
                          letterSpacing: 0.1,
                        ),
                      ),
                      r.verticalSpace(6),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: r.iconSize(15),
                            color: darkBlue,
                          ),
                          r.horizontalSpace(5),
                          Text(
                            DateFormat('dd/MM/yyyy HH:mm').format(timestamp),
                            style: GoogleFonts.poppins(
                              fontSize: r.fontSize(10),
                              color: darkBlue,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (!isRead)
                  Padding(
                    padding: r.padding(left: 8),
                    child: IconButton(
                      icon: Icon(
                        Icons.check_circle_outline,
                        color: darkBlue,
                        size: r.iconSize(23),
                      ),
                      tooltip: 'Marcar como lida',
                      onPressed:
                          isProcessing
                              ? null
                              : () => _markAsRead(notification['id']),
                    ),
                  ),
                Padding(
                  padding: r.padding(left: 0),
                  child: IconButton(
                    icon: Icon(
                      Icons.delete_outline,
                      color: const Color(0xFFE53935),
                      size: r.iconSize(23),
                    ),
                    tooltip: 'Excluir notificação',
                    onPressed:
                        isProcessing
                            ? null
                            : () => _deleteNotification(notification['id']),
                  ),
                ),
              ],
            ),
            Container(
              padding: r.padding(left: 7, top: 7, right: 7, bottom: 7),
              decoration: BoxDecoration(
                color:
                    isRead
                        ? const Color(0xFFE0E0E0)
                        : primaryBlue.withValues(alpha: 0.04),
                borderRadius: r.circularBorderRadius(10),
              ),
              child: Text(
                notification['message'],
                style: GoogleFonts.poppins(
                  fontSize: r.fontSize(15),
                  color: Colors.black,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
