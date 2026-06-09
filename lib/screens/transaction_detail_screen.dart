import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../models/transaction.dart';
import '../providers/transaction_provider.dart';
import '../theme/app_theme.dart';
import '../utils/category_helper.dart';
import '../utils/formatters.dart';

class TransactionDetailScreen extends StatelessWidget {
  final Transaction transaction;

  const TransactionDetailScreen({super.key, required this.transaction});

  @override
  Widget build(BuildContext context) {
    final isDebit = transaction.type == TransactionType.debit;
    final color = isDebit ? kDebit : kCredit;
    final sign = isDebit ? '-' : '+';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: kDebit),
            onPressed: () => _confirmDelete(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Header card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: color.withOpacity(0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: color.withOpacity(0.2)),
              ),
              child: Column(
                children: [
                  Text(
                    CategoryHelper.iconFor(transaction.category),
                    style: const TextStyle(fontSize: 44),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    transaction.merchant,
                    style: GoogleFonts.dmSans(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: kTextPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$sign${formatAmount(transaction.amount)}',
                    style: GoogleFonts.dmSans(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: color,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isDebit ? 'EXPENSE' : 'INCOME',
                      style: GoogleFonts.dmSans(
                        color: color,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Details list
            _DetailCard(children: [
              _DetailRow(
                  icon: Icons.calendar_today_rounded,
                  label: 'Date',
                  value: formatDate(transaction.date)),
              _DetailRow(
                  icon: Icons.label_rounded,
                  label: 'Category',
                  value: '${CategoryHelper.iconFor(transaction.category)} ${transaction.category}'),
              if (transaction.bankName.isNotEmpty)
                _DetailRow(
                    icon: Icons.account_balance_rounded,
                    label: 'Bank',
                    value: transaction.bankName),
              if (transaction.accountLast4.isNotEmpty)
                _DetailRow(
                    icon: Icons.credit_card_rounded,
                    label: 'Account',
                    value: '···· ${transaction.accountLast4}'),
              _DetailRow(
                  icon: Icons.access_time_rounded,
                  label: 'Added',
                  value: formatDate(transaction.createdAt)),
            ]),

            const SizedBox(height: 16),

            // Raw SMS
            if (transaction.rawText.isNotEmpty) ...[
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Original SMS',
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: kTextPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: kCard,
                  borderRadius: BorderRadius.circular(14),
                  border:
                      Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Text(
                  transaction.rawText,
                  style: GoogleFonts.dmMono(
                    fontSize: 13,
                    color: kTextSecondary,
                    height: 1.5,
                  ),
                ),
              ),
            ],

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete Transaction',
            style: GoogleFonts.dmSans(fontWeight: FontWeight.w700)),
        content: Text('Are you sure you want to delete this transaction?',
            style: GoogleFonts.dmSans()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: kDebit),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await context.read<TransactionProvider>().delete(transaction.id);
      Navigator.of(context).pop();
    }
  }
}

class _DetailCard extends StatelessWidget {
  final List<Widget> children;
  const _DetailCard({required this.children});

  @override
  Widget build(BuildContext context) => Container(
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
          children: children
              .asMap()
              .entries
              .map((entry) => Column(
                    children: [
                      entry.value,
                      if (entry.key < children.length - 1)
                        const Divider(height: 1, indent: 52),
                    ],
                  ))
              .toList(),
        ),
      );
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 20, color: kPrimary),
            const SizedBox(width: 16),
            Text(
              label,
              style: GoogleFonts.dmSans(fontSize: 14, color: kTextSecondary),
            ),
            const Spacer(),
            Text(
              value,
              style: GoogleFonts.dmSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: kTextPrimary,
              ),
            ),
          ],
        ),
      );
}
