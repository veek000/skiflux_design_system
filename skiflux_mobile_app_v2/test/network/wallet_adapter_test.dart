import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skiflux_mobile_app_v2/features/home/data/episodes_repository.dart';
import 'package:skiflux_mobile_app_v2/features/tasks/data/models/platform_task.dart';
import 'package:skiflux_mobile_app_v2/features/tasks/data/tasks_store.dart';
import 'package:skiflux_mobile_app_v2/features/wallet/data/models/skillcoin_transaction.dart';
import 'package:skiflux_mobile_app_v2/features/wallet/data/models/wallet_financial_summary.dart';
import 'package:skiflux_mobile_app_v2/features/wallet/data/wallet_store.dart';
import 'package:skiflux_mobile_app_v2/features/profile/data/models/user_profile.dart';
import 'package:skiflux_mobile_app_v2/shared/network/json_envelope.dart';

void main() {
  group('unwrapObject', () {
    test('returns bare map as-is', () {
      final m = {'id': '1', 'balance': '10.00'};
      expect(unwrapObject(m), same(m));
    });

    test('peels data wrapper', () {
      final inner = {'id': '1'};
      expect(unwrapObject({'status': 'success', 'data': inner}), inner);
    });
  });

  group('CoinTxn.fromSkillcoin', () {
    test('maps topup credit to earned with Decimal amount', () {
      final txn = SkillcoinTransaction(
        amount: Decimal.parse('70.00'),
        transactionType: SkillcoinTransactionType.topup,
        transactionTypeLabel: 'Top-up via Payment Gateway',
        description: 'Wallet top-up',
        createdAt: DateTime.utc(2026, 7, 1),
        id: 't1',
        referenceId: 'ref-1',
      );
      final row = CoinTxn.fromSkillcoin(txn);
      expect(row.delta, 70);
      expect(row.type, CoinTxnType.earned);
      expect(row.kind, CoinTxnKind.topUp);
      expect(row.reference, 'ref-1');
      expect(row.title, 'Top-up via Payment Gateway');
    });

    test('maps withdrawal to withdrawn', () {
      final txn = SkillcoinTransaction(
        amount: Decimal.parse('-200.00'),
        transactionType: SkillcoinTransactionType.withdrawal,
        transactionTypeLabel: 'Withdrawal',
        description: 'Cash out',
        createdAt: DateTime.utc(2026, 7, 2),
      );
      final row = CoinTxn.fromSkillcoin(txn);
      expect(row.delta, -200);
      expect(row.type, CoinTxnType.withdrawn);
      expect(row.kind, CoinTxnKind.withdrawalProcessed);
    });
  });

  group('WalletFinancialSummary', () {
    test('parses decimal strings', () {
      final s = WalletFinancialSummary.fromJson({
        'total_earned': '100.00',
        'total_spent': '40.50',
        'total_withdrawn': '10.00',
      });
      expect(s.totalEarned, Decimal.parse('100.00'));
      expect(s.totalSpent, Decimal.parse('40.50'));
    });
  });

  group('UserProfile', () {
    test('parses minimal profile + money strings', () {
      final p = UserProfile.fromJson({
        'id': 'u1',
        'first_name': 'Amara',
        'last_name': 'Design',
        'email': 'amara@example.com',
        'username': 'amara',
        'xp': 2450,
        'rank': 12,
        'current_level': 'Master',
        'balance': '1500.50',
        'bonus_balance': '50.00',
      });
      expect(p.displayName, 'Amara Design');
      expect(p.handle, '@amara');
      expect(p.initials, 'AD');
      expect(p.xpLabel, '2,450');
      expect(p.balance, Decimal.parse('1500.50'));
    });
  });

  group('episodeJsonToFeedItem', () {
    test('maps video episode with creator', () {
      final item = episodeJsonToFeedItem({
        'id': 'ep-1',
        'title': 'Code',
        'description': 'Desc',
        'order': 1,
        'video_url': 'https://cdn.example/v.mp4',
        'thumbnail_url': 'https://cdn.example/t.jpg',
        'creator': {
          'first_name': 'Amara',
          'last_name': 'Design',
          'username': 'amara',
        },
      });
      expect(item.hasPlayableVideo, isTrue);
      expect(item.coverUrl, 'https://cdn.example/t.jpg');
      expect(item.epTag, 'EP 01');
      expect(item.creatorUsername, 'amara');
      expect(item.episodeId, 'ep-1');
    });

    test('image when no video_url', () {
      final item = episodeJsonToFeedItem({
        'id': 'ep-2',
        'title': 'Board',
        'description': '',
        'order': 2,
        'video_url': '',
        'thumbnail_url': 'https://cdn.example/i.jpg',
        'creator': {'username': 'nia'},
      });
      expect(item.isImage, isTrue);
      expect(item.hasPlayableVideo, isFalse);
    });
  });

  group('MissionTask.fromPlatform', () {
    test('maps claimable task', () {
      final t = PlatformTask.fromJson({
        'id': 'pt-1',
        'slug': 'follow-ig',
        'title': 'Follow & Earn',
        'description': 'Follow Instagram',
        'category': 'social',
        'trigger_type': '',
        'action_type': '',
        'verification_mode': 'manual',
        'progress_target': 1,
        'progress_current': 0,
        'icon': 'instagram',
        'metadata': <String, dynamic>{},
        'sort_order': 0,
        'xp_reward': 25,
        'skillcoin_reward': '25.00',
        'status': 'claimable',
        'claimable': true,
        'completed': false,
      });
      final m = MissionTask.fromPlatform(t);
      expect(m.coins, 25);
      expect(m.claimable, isTrue);
      expect(m.actionLabel, 'Claim');
      expect(m.fromBackend, isTrue);
    });
  });
}
