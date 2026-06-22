import 'package:flutter/foundation.dart';

import '../models/app_notification.dart';
import '../models/errand.dart';
import '../models/errand_offer.dart';
import 'supabase_service.dart';

class DatabaseService {
  DatabaseService._();

  static final DatabaseService instance = DatabaseService._();

  final ValueNotifier<int> changes = ValueNotifier<int>(0);
  final ValueNotifier<int?> unreadNotificationCount = ValueNotifier<int?>(null);

  Future<List<Errand>> getErrands() async {
    final rows = await SupabaseService.client
        .from('errands')
        .select()
        .order('created_at', ascending: false);
    return rows.map(Errand.fromMap).toList();
  }

  Future<List<Errand>> getOpenErrands() async {
    final rows = await SupabaseService.client
        .from('errands')
        .select()
        .eq('status', 'Open')
        .filter('runner_id', 'is', null)
        .order('created_at', ascending: false);
    return rows.map(Errand.fromMap).toList();
  }

  Future<List<Errand>> getUserPostedErrands(String userId) async {
    final rows = await SupabaseService.client
        .from('errands')
        .select()
        .eq('is_seed', false)
        .or('poster_id.eq.$userId,user_id.eq.$userId')
        .order('created_at', ascending: false);
    return rows.map(Errand.fromMap).toList();
  }

  Future<List<Errand>> getAssignedErrands(String runnerId) async {
    final rows = await SupabaseService.client
        .from('errands')
        .select()
        .eq('runner_id', runnerId)
        .order('accepted_at', ascending: false)
        .order('created_at', ascending: false);
    return rows.map(Errand.fromMap).toList();
  }

  Future<Errand?> getErrand(int id) async {
    final row = await SupabaseService.client
        .from('errands')
        .select()
        .eq('id', id)
        .maybeSingle();
    return row == null ? null : Errand.fromMap(row);
  }

  Future<Errand> insertErrand({
    required String title,
    required double reward,
    required String description,
    required String timeToComplete,
    String? posterId,
    String? posterName,
  }) async {
    final row = await SupabaseService.client
        .from('errands')
        .insert({
          'title': title,
          'reward': reward,
          'description': description,
          'time_to_complete': timeToComplete,
          'status': 'Open',
          'user_id': posterId,
          'poster_id': posterId,
          'poster_name': posterName,
          'is_seed': false,
        })
        .select()
        .single();
    changes.value++;
    return Errand.fromMap(row);
  }

  Future<void> updateErrand({
    required int id,
    required String posterId,
    required String title,
    required double reward,
    required String description,
    required String timeToComplete,
    required String status,
  }) async {
    await SupabaseService.client
        .from('errands')
        .update({
          'title': title,
          'reward': reward,
          'description': description,
          'time_to_complete': timeToComplete,
          'status': status,
        })
        .eq('id', id)
        .or('poster_id.eq.$posterId,user_id.eq.$posterId')
        .eq('is_seed', false);
    changes.value++;
  }

  Future<void> updateErrandStatus({
    required int id,
    required String posterId,
    required String status,
  }) async {
    await SupabaseService.client
        .from('errands')
        .update({'status': status})
        .eq('id', id)
        .or('poster_id.eq.$posterId,user_id.eq.$posterId')
        .eq('is_seed', false);
    changes.value++;
  }

  Future<bool> createOffer({
    required int errandId,
    required String runnerId,
    required String runnerName,
    required String message,
    required double proposedReward,
    required String estimatedTime,
  }) async {
    final errand = await getErrand(errandId);
    if (errand == null ||
        errand.status != 'Open' ||
        errand.isAssigned ||
        errand.posterId == runnerId) {
      return false;
    }

    final existing = await getRunnerOffer(
      errandId: errandId,
      runnerId: runnerId,
    );
    final offerData = {
      'errand_id': errandId,
      'runner_id': runnerId,
      'runner_name': runnerName,
      'message': message,
      'proposed_reward': proposedReward,
      'estimated_time': estimatedTime,
      'status': 'Pending',
    };

    if (existing == null) {
      await SupabaseService.client.from('errand_offers').insert(offerData);
    } else if (existing.status == 'Rejected' ||
        existing.status == 'Withdrawn') {
      await SupabaseService.client
          .from('errand_offers')
          .update({
            ...offerData,
            'created_at': DateTime.now().toIso8601String(),
          })
          .eq('id', existing.id)
          .eq('runner_id', runnerId);
    } else {
      return false;
    }

    final posterId = errand.posterId;
    if (posterId != null && posterId.isNotEmpty) {
      await _createNotification(
        userId: posterId,
        errandId: errandId,
        title: 'New runner request',
        message: '$runnerName wants to do "${errand.title}".',
      );
    }

    changes.value++;
    return true;
  }

  Future<List<ErrandOffer>> getOffersForErrand(int errandId) async {
    final rows = await SupabaseService.client
        .from('errand_offers')
        .select()
        .eq('errand_id', errandId)
        .order('created_at', ascending: false);
    final offers = rows.map(ErrandOffer.fromMap).toList();
    offers.sort((a, b) {
      final statusCompare = _offerStatusRank(
        a.status,
      ).compareTo(_offerStatusRank(b.status));
      if (statusCompare != 0) return statusCompare;
      return b.createdAt.compareTo(a.createdAt);
    });
    return offers;
  }

  Future<List<ErrandOffer>> getOffersByRunner(String runnerId) async {
    final rows = await SupabaseService.client
        .from('errand_offers')
        .select('*, errands!inner(title)')
        .eq('runner_id', runnerId)
        .order('created_at', ascending: false);

    return rows.map((row) {
      final mapped = Map<String, Object?>.from(row);
      final errand = mapped.remove('errands');
      if (errand is Map) {
        mapped['errand_title'] = errand['title'] as String?;
      }
      return ErrandOffer.fromMap(mapped);
    }).toList();
  }

  Future<ErrandOffer?> getRunnerOffer({
    required int errandId,
    required String runnerId,
  }) async {
    final row = await SupabaseService.client
        .from('errand_offers')
        .select()
        .eq('errand_id', errandId)
        .eq('runner_id', runnerId)
        .maybeSingle();
    return row == null ? null : ErrandOffer.fromMap(row);
  }

  Future<bool> acceptOffer({
    required int offerId,
    required String posterId,
  }) async {
    final offerRow = await SupabaseService.client
        .from('errand_offers')
        .select()
        .eq('id', offerId)
        .eq('status', 'Pending')
        .maybeSingle();
    if (offerRow == null) return false;

    final offer = ErrandOffer.fromMap(offerRow);
    final errand = await getErrand(offer.errandId);
    if (errand == null ||
        errand.posterId != posterId ||
        errand.status != 'Open' ||
        errand.isAssigned) {
      return false;
    }

    await SupabaseService.client
        .from('errands')
        .update({
          'runner_id': offer.runnerId,
          'runner_name': offer.runnerName,
          'accepted_at': DateTime.now().toIso8601String(),
        })
        .eq('id', offer.errandId)
        .or('poster_id.eq.$posterId,user_id.eq.$posterId')
        .eq('status', 'Open')
        .filter('runner_id', 'is', null);

    await SupabaseService.client
        .from('errand_offers')
        .update({'status': 'Accepted'})
        .eq('id', offerId);
    await SupabaseService.client
        .from('errand_offers')
        .update({'status': 'Rejected'})
        .eq('errand_id', offer.errandId)
        .neq('id', offerId)
        .eq('status', 'Pending');

    await _createNotification(
      userId: offer.runnerId,
      errandId: offer.errandId,
      title: 'Request accepted',
      message: 'Your request for "${errand.title}" was accepted.',
    );

    changes.value++;
    return true;
  }

  Future<bool> rejectOffer({
    required int offerId,
    required String posterId,
  }) async {
    final offerRow = await SupabaseService.client
        .from('errand_offers')
        .select('*, errands!inner(title, poster_id, user_id)')
        .eq('id', offerId)
        .eq('status', 'Pending')
        .maybeSingle();
    if (offerRow == null) return false;

    final errand = offerRow['errands'] as Map;
    final ownerId = errand['poster_id'] ?? errand['user_id'];
    if (ownerId != posterId) return false;

    final offer = ErrandOffer.fromMap(offerRow);
    await SupabaseService.client
        .from('errand_offers')
        .update({'status': 'Rejected'})
        .eq('id', offerId);
    await _createNotification(
      userId: offer.runnerId,
      errandId: offer.errandId,
      title: 'Request rejected',
      message: 'Your request for "${errand['title']}" was rejected.',
    );

    changes.value++;
    return true;
  }

  Future<List<AppNotification>> getNotifications(String userId) async {
    final rows = await SupabaseService.client
        .from('notifications')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return rows.map(AppNotification.fromMap).toList();
  }

  Future<int> getUnreadNotificationCount(String userId) async {
    final rows = await SupabaseService.client
        .from('notifications')
        .select('id')
        .eq('user_id', userId)
        .eq('is_read', false);
    final count = rows.length;
    unreadNotificationCount.value = count;
    return count;
  }

  Future<void> markNotificationRead(int notificationId) async {
    await SupabaseService.client
        .from('notifications')
        .update({'is_read': true})
        .eq('id', notificationId);
    final currentCount = unreadNotificationCount.value;
    if (currentCount != null && currentCount > 0) {
      unreadNotificationCount.value = currentCount - 1;
    }
    changes.value++;
  }

  Future<void> markAllNotificationsRead(String userId) async {
    await SupabaseService.client
        .from('notifications')
        .update({'is_read': true})
        .eq('user_id', userId)
        .eq('is_read', false);
    unreadNotificationCount.value = 0;
    changes.value++;
  }

  Future<void> updateAssignedErrandStatus({
    required int id,
    required String runnerId,
    required String status,
  }) async {
    await SupabaseService.client
        .from('errands')
        .update({'status': status})
        .eq('id', id)
        .eq('runner_id', runnerId);
    changes.value++;
  }

  Future<void> deleteErrand({required int id, required String posterId}) async {
    await SupabaseService.client
        .from('errands')
        .delete()
        .eq('id', id)
        .or('poster_id.eq.$posterId,user_id.eq.$posterId')
        .eq('is_seed', false);
    changes.value++;
  }

  Future<int> insertUser(
    String name,
    String email,
    String password,
    String phone,
  ) {
    throw UnsupportedError('Users are managed by Supabase Auth.');
  }

  Future<int> updateUser({
    required int id,
    required String name,
    required String email,
    required String phone,
    String? password,
  }) {
    throw UnsupportedError('Users are managed by Supabase Auth.');
  }

  Future<Map<String, Object?>?> getUser() async {
    final user = SupabaseService.client.auth.currentUser;
    if (user == null) return null;
    return {
      'id': user.id,
      'name': user.userMetadata?['name'],
      'email': user.email,
      'phone': user.userMetadata?['phone_number'],
    };
  }

  Future<void> _createNotification({
    required String userId,
    required int errandId,
    required String title,
    required String message,
  }) {
    return SupabaseService.client.from('notifications').insert({
      'user_id': userId,
      'errand_id': errandId,
      'title': title,
      'message': message,
      'is_read': false,
    });
  }

  int _offerStatusRank(String status) {
    return switch (status) {
      'Pending' => 0,
      'Accepted' => 1,
      _ => 2,
    };
  }
}
