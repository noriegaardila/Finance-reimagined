import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../providers/transaction_provider.dart';
import '../screens/transaction_detail_screen.dart';
import '../screens/transactions_screen.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/summary_card.dart';
import '../widgets/transaction_card.dart';
import 'add_sms_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _tab,
        children: const [
          _DashboardTab(),
          TransactionsScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        backgroundColor: Colors.white,
        indicatorColor: kPrimary.withOpacity(0.12),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home_rounded, color: kPrimary),
            label: 'Home',
          ),
          NavigationDestination(
            icon: const Icon(Icons.receipt_long_outlined),
            selectedIcon:
                const Icon(Icons.receipt_long_rounded, color: kPrimary),
            label: 'Transactions',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddSmsScreen()),
        ),
        backgroundColor: kPrimary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: Text('Add SMS', style: GoogleFonts.dmSans(fontWeight: FontWeight.w600)),
      ),
    );
  }
}

class _DashboardTab extends StatelessWidget {
  const _DashboardTab();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TransactionProvider>();
    final recent = provider.recentTransactions;

    return CustomScrollView(
      slivers: [
        // App bar
        SliverAppBar(
          pinned: false,
          floating: true,
          backgroundColor: kSurface,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _greeting(),
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  color: kTextSecondary,
                ),
              ),
              Text(
                'Finance Reimagined',
                style: GoogleFonts.dmSans(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: kTextPrimary,
                ),
              ),
            ],
          ),
          titleSpacing: 16,
        ),

        SliverToBoxAdapter(child: SummaryCard()),

        // Spending by category
        SliverToBoxAdapter(
          child: _CategoryBreakdown(),
        ),

        // Recent transactions header
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent',
                  style: GoogleFonts.dmSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: kTextPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),

        if (recent.isEmpty)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: _EmptyDashboard(),
          )
        else
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, i) {
                final t = recent[i];
                return TransactionCard(
                  transaction: t,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => TransactionDetailScreen(transaction: t)),
                  ),
                  onDelete: () =>
                      context.read<TransactionProvider>().delete(t.id),
                );
              },
              childCount: recent.length,
            ),
          ),

        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning 👋';
    if (hour < 17) return 'Good afternoon 👋';
    return 'Good evening 👋';
  }
}

class _CategoryBreakdown extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final spending = context.watch<TransactionProvider>().spendingByCategory;
    if (spending.isEmpty) return const SizedBox.shrink();

    final sorted = spending.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = sorted.take(4).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
          child: Text(
            'Spending this month',
            style: GoogleFonts.dmSans(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: kTextPrimary,
            ),
          ),
        ),
        SizedBox(
          height: 100,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: top.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, i) {
              final entry = top[i];
              return _CategoryTile(
                category: entry.key,
                amount: entry.value,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final String category;
  final double amount;

  const _CategoryTile({required this.category, required this.amount});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 130,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _iconFor(category),
            style: const TextStyle(fontSize: 24),
          ),
          const Spacer(),
          Text(
            formatAmount(amount),
            style: GoogleFonts.dmSans(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: kTextPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            category,
            style: GoogleFonts.dmSans(
              fontSize: 11,
              color: kTextSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  String _iconFor(String cat) {
    const map = {
      'Food & Drink': '🍔',
      'Shopping': '🛍️',
      'Transport': '🚗',
      'Bills & Utilities': '💡',
      'Health': '💊',
      'Travel': '✈️',
      'Entertainment': '🎬',
      'ATM / Cash': '💵',
      'Transfer': '↕️',
    };
    return map[cat] ?? '📦';
  }
}

class _EmptyDashboard extends StatelessWidget {
  const _EmptyDashboard();

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🏦', style: TextStyle(fontSize: 56)),
              const SizedBox(height: 16),
              Text(
                'No transactions yet',
                style: GoogleFonts.dmSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: kTextPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tap "Add SMS" to paste a bank message and we\'ll extract the transaction automatically.',
                style:
                    GoogleFonts.dmSans(color: kTextSecondary, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
}
