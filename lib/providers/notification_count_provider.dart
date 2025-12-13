import 'package:flutter/foundation.dart';
import '../services/api_client.dart';

class NotificationCounts {
  final int interestReceived;
  final int interestSent;
  final int unlockedProfiles;
  final int iDeclined;
  final int theyDeclined;
  final int shortlisted;
  final int ignored;
  final int blocked;
  final int total;

  NotificationCounts({
    this.interestReceived = 0,
    this.interestSent = 0,
    this.unlockedProfiles = 0,
    this.iDeclined = 0,
    this.theyDeclined = 0,
    this.shortlisted = 0,
    this.ignored = 0,
    this.blocked = 0,
    this.total = 0,
  });

  NotificationCounts copyWith({
    int? interestReceived,
    int? interestSent,
    int? unlockedProfiles,
    int? iDeclined,
    int? theyDeclined,
    int? shortlisted,
    int? ignored,
    int? blocked,
    int? total,
  }) {
    return NotificationCounts(
      interestReceived: interestReceived ?? this.interestReceived,
      interestSent: interestSent ?? this.interestSent,
      unlockedProfiles: unlockedProfiles ?? this.unlockedProfiles,
      iDeclined: iDeclined ?? this.iDeclined,
      theyDeclined: theyDeclined ?? this.theyDeclined,
      shortlisted: shortlisted ?? this.shortlisted,
      ignored: ignored ?? this.ignored,
      blocked: blocked ?? this.blocked,
      total: total ?? this.total,
    );
  }
}

class NotificationCountProvider extends ChangeNotifier {
  final ApiClient _apiClient = ApiClient();

  NotificationCounts _counts = NotificationCounts();
  bool _isLoading = true;
  String? _error;

  NotificationCounts get counts => _counts;
  bool get isLoading => _isLoading;
  String? get error => _error;

  NotificationCountProvider() {
    fetchCounts();
  }

  Future<void> fetchCounts() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Fetch all counts in parallel
      final results = await Future.wait([
        _apiClient.get<dynamic>('interest/getInterests'),
        _apiClient.get<dynamic>('dashboard/getMyInterestedProfiles'),
        _apiClient.get<dynamic>('dashboard/getMyUnlockedProfiles'),
        _apiClient.get<dynamic>('dashboard/getMyDeclinedProfiles'),
        _apiClient.get<dynamic>('dashboard/getUsersWhoHaveDeclinedMe'),
        _apiClient.get<dynamic>('dashboard/getMyShortlistedProfiles'),
        _apiClient.get<dynamic>('dashboard/getAllIgnoredProfiles'),
        _apiClient.get<dynamic>('dashboard/getMyBlockedProfiles'),
      ]);

      // Extract notification counts from responses
      int getNotificationCount(dynamic response) {
        if (response is List) {
          // Array response doesn't have notification count
          return 0;
        }
        if (response is Map<String, dynamic>) {
          // Check for notificationCount field which represents unseen/new notifications
          final count = response['notificationCount'];
          if (count is int) {
            return count;
          }
          // If notificationCount is not available, return 0
          return 0;
        }
        return 0;
      }

      final newCounts = NotificationCounts(
        interestReceived: getNotificationCount(results[0]),
        interestSent: getNotificationCount(results[1]),
        unlockedProfiles: getNotificationCount(results[2]),
        iDeclined: getNotificationCount(results[3]),
        theyDeclined: getNotificationCount(results[4]),
        shortlisted: getNotificationCount(results[5]),
        ignored: getNotificationCount(results[6]),
        blocked: getNotificationCount(results[7]),
      );

      _counts = newCounts.copyWith(
        total: newCounts.interestReceived +
            newCounts.interestSent +
            newCounts.unlockedProfiles +
            newCounts.iDeclined +
            newCounts.theyDeclined +
            newCounts.shortlisted +
            newCounts.ignored +
            newCounts.blocked,
      );

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  void refresh() {
    fetchCounts();
  }
}

