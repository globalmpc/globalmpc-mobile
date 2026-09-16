import 'package:flutter_test/flutter_test.dart';
import 'package:mpc_mining_app/core/notifications/app_notification.dart';
import 'package:mpc_mining_app/core/notifications/notification_center.dart';
import 'package:mpc_mining_app/data/models/wallet_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final now = DateTime(2026, 9, 14, 10);

  WalletTransaction tx(
    String hash, {
    TxDirection direction = TxDirection.outgoing,
    TxStatus status = TxStatus.confirmed,
    double amount = 250,
  }) => WalletTransaction(
    hash: hash,
    kind: direction == TxDirection.incoming ? TxKind.receive : TxKind.send,
    direction: direction,
    amount: amount,
    timestamp: now,
    counterparty: '0xabc',
    status: status,
  );

  WalletAccount wallet(
    List<WalletTransaction> transactions, {
    bool isDemo = false,
  }) => WalletAccount(
    address: '0xAbC0000000000000000000000000000000000001',
    mpcBalance: 1000,
    network: 'BSC Testnet',
    transactions: transactions,
    allocations: const {},
    isDemo: isDemo,
  );

  Future<NotificationCenter> startCenter() async {
    final prefs = await SharedPreferences.getInstance();
    final center = NotificationCenter.forTesting(clock: () => now);
    await center.start(
      prefs: prefs,
      translate: (key) => key,
      usePlatformNotifications: false,
    );
    return center;
  }

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('the first wallet load records history without notifying', () async {
    final center = await startCenter();

    await center.reviewTransactions(
      wallet([tx('0x1'), tx('0x2', direction: TxDirection.incoming)]),
    );

    expect(center.inbox, isEmpty);
  });

  test('a confirmed outgoing transfer notifies once with its amount', () async {
    final center = await startCenter();

    await center.reviewTransactions(
      wallet([tx('0x1', status: TxStatus.pending)]),
    );
    await center.reviewTransactions(wallet([tx('0x1')]));
    await center.reviewTransactions(wallet([tx('0x1')]));

    expect(center.inbox, hasLength(1));
    final notification = center.inbox.single;
    expect(notification.category, NotificationCategory.transaction);
    expect(notification.titleKey, 'notif.tx.sent.title');
    expect(notification.fill('{amount} MPC'), '250 MPC');
  });

  test('a new incoming transfer notifies as received', () async {
    final center = await startCenter();

    await center.reviewTransactions(wallet([tx('0x1')]));
    await center.reviewTransactions(
      wallet([
        tx('0x2', direction: TxDirection.incoming, amount: 1234.5),
        tx('0x1'),
      ]),
    );

    expect(center.inbox.single.titleKey, 'notif.tx.received.title');
    expect(center.inbox.single.args['amount'], '1,234.5');
  });

  test('a demo wallet never produces notifications', () async {
    final center = await startCenter();

    await center.reviewTransactions(
      wallet([tx('0x1', status: TxStatus.pending)], isDemo: true),
    );
    await center.reviewTransactions(wallet([tx('0x1')], isDemo: true));

    expect(center.inbox, isEmpty);
  });

  test('turning transaction updates off stops them', () async {
    final center = await startCenter();
    await center.setEnabled(NotificationCategory.transaction, false);

    await center.reviewTransactions(
      wallet([tx('0x1', status: TxStatus.pending)]),
    );
    await center.reviewTransactions(wallet([tx('0x1')]));

    expect(center.isEnabled(NotificationCategory.transaction), isFalse);
    expect(center.inbox, isEmpty);
  });

  test('the project updates switch is saved like the others', () async {
    final center = await startCenter();
    expect(center.isEnabled(NotificationCategory.project), isTrue);

    await center.setEnabled(NotificationCategory.project, false);

    final restarted = await startCenter();
    expect(restarted.isEnabled(NotificationCategory.project), isFalse);
  });

  test('saved notifications survive a restart', () async {
    final first = await startCenter();
    await first.notifySecurity(
      'notif.sec.pinChanged.title',
      'notif.sec.pinChanged.body',
    );

    final second = await startCenter();

    expect(second.inbox.single.titleKey, 'notif.sec.pinChanged.title');
    expect(second.inbox.single.createdAt, now);
  });

  test('mark all read clears unread until something new arrives', () async {
    var clock = now;
    final prefs = await SharedPreferences.getInstance();
    final center = NotificationCenter.forTesting(clock: () => clock);
    await center.start(
      prefs: prefs,
      translate: (key) => key,
      usePlatformNotifications: false,
    );

    await center.notifySecurity('first.title', 'first.body');
    await center.notifySecurity('second.title', 'second.body');
    expect(center.unreadCount, 2);

    await center.markAllRead();
    expect(center.unreadCount, 0);

    clock = now.add(const Duration(minutes: 1));
    await center.notifySecurity('third.title', 'third.body');
    expect(center.unreadCount, 1);

    final restarted = NotificationCenter.forTesting(clock: () => clock);
    await restarted.start(
      prefs: prefs,
      translate: (key) => key,
      usePlatformNotifications: false,
    );
    expect(restarted.unreadCount, 1);
    expect(restarted.isUnread(restarted.inbox.first), isTrue);
    expect(restarted.isUnread(restarted.inbox.last), isFalse);
  });
}
