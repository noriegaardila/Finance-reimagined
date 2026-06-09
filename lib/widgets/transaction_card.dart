import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/transaction.dart';
import '../theme/app_theme.dart';
import '../utils/category_helper.dart';
import '../utils/formatters.dart';

class TransactionCard extends StatelessWidget {
  final Transaction transaction;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const TransactionCard({
    super.key,
    required this.transaction,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDebit = transaction.type == TransactionType.debit;
    final amountColor = isDebit ? kDebit : kCredit;
    final sign = isDebit ? '-' : '+';

    return Slidable(
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        extentRatio: 0.22,
        children: [
          SlidableAction(
            onPressed: (_) => onDelete?.call(),
            backgroundColor: kDebit,
            foregroundColor: Colors.white,
            icon: Icons.delete_outline,
            borderRadius: const BorderRadius.horizontal(right: Radius.circular(16)),
          ),
        ],
      ),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
          child: Row(
            children: [
              // Category icon bubble
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: kSurface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  CategoryHelper.iconFor(transaction.category),
                  style: const TextStyle(fontSize: 22),
                ),
              ),
              const SizedBox(width: 12),
              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaction.merchant,
                      style: GoogleFonts.dmSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: kTextPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${transaction.bankName.isNotEmpty ? '${transaction.bankName} · ' : ''}'
                      '${formatDate(transaction.date)}',
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        color: kTextSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Amount
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$sign${formatAmount(transaction.amount)}',
                    style: GoogleFonts.dmSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: amountColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: amountColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      transaction.category,
                      style: GoogleFonts.dmSans(
                        fontSize: 10,
                        color: amountColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
