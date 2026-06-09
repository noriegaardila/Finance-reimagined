import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../models/transaction.dart';
import '../providers/transaction_provider.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/transaction_card.dart';
import 'transaction_detail_screen.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  TransactionType? _typeFilter;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<Transaction> _filtered(List<Transaction> all) {
    return all.where((t) {
      final matchesQuery = _query.isEmpty ||
          t.merchant.toLowerCase().contains(_query.toLowerCase()) ||
          t.bankName.toLowerCase().contains(_query.toLowerCase()) ||
          t.category.toLowerCase().contains(_query.toLowerCase());
      final matchesType = _typeFilter == null || t.type == _typeFilter;
      return matchesQuery && matchesType;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final all = context.watch<TransactionProvider>().transactions;
    final filtered = _filtered(all);
    final grouped = groupByDate(filtered, (t) => t.date);
    final sortedDates = grouped.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    return Column(
      children: [
        // Search + filter row
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (v) => setState(() => _query = v),
                  style:
                      GoogleFonts.dmSans(fontSize: 14, color: kTextPrimary),
                  decoration: InputDecoration(
                    hintText: 'Search merchant, bank, category…',
                    hintStyle: GoogleFonts.dmSans(
                        color: kTextSecondary, fontSize: 13),
                    prefixIcon:
                        const Icon(Icons.search, color: kTextSecondary),
                    suffixIcon: _query.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear,
                                color: kTextSecondary, size: 18),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() => _query = '');
                            },
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Type filter chips
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Row(
            children: [
              _FilterChip(
                label: 'All',
                selected: _typeFilter == null,
                onTap: () => setState(() => _typeFilter = null),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'Expenses',
                selected: _typeFilter == TransactionType.debit,
                color: kDebit,
                onTap: () => setState(() => _typeFilter = TransactionType.debit),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'Income',
                selected: _typeFilter == TransactionType.credit,
                color: kCredit,
                onTap: () =>
                    setState(() => _typeFilter = TransactionType.credit),
              ),
            ],
          ),
        ),

        // Transaction list
        Expanded(
          child: filtered.isEmpty
              ? _EmptyState(hasTransactions: all.isNotEmpty)
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 100),
                  itemCount: sortedDates.length,
                  itemBuilder: (context, i) {
                    final date = sortedDates[i];
                    final items = grouped[date]!;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 6),
                          child: Text(
                            _dateLabel(date),
                            style: GoogleFonts.dmSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: kTextSecondary,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        ...items.map(
                          (t) => TransactionCard(
                            transaction: t,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    TransactionDetailScreen(transaction: t),
                              ),
                            ),
                            onDelete: () =>
                                context.read<TransactionProvider>().delete(t.id),
                          ),
                        ),
                      ],
                    );
                  },
                ),
        ),
      ],
    );
  }

  String _dateLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    if (date == today) return 'TODAY';
    if (date == yesterday) return 'YESTERDAY';
    return formatDate(date).toUpperCase();
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color? color;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? kPrimary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? c : c.withOpacity(0.06),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : c,
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool hasTransactions;
  const _EmptyState({required this.hasTransactions});

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              hasTransactions ? '🔍' : '📋',
              style: const TextStyle(fontSize: 48),
            ),
            const SizedBox(height: 12),
            Text(
              hasTransactions ? 'No matches' : 'No transactions yet',
              style: GoogleFonts.dmSans(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: kTextPrimary),
            ),
            const SizedBox(height: 6),
            Text(
              hasTransactions
                  ? 'Try a different search term.'
                  : 'Add your first bank SMS from the home screen.',
              style: GoogleFonts.dmSans(color: kTextSecondary, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
}
