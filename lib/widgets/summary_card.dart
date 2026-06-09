import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../providers/transaction_provider.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';

class SummaryCard extends StatelessWidget {
  const SummaryCard({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TransactionProvider>();
    final net = provider.netThisMonth;
    final netColor = net >= 0 ? kCredit : kDebit;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [kPrimary, kPrimaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: kPrimary.withOpacity(0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            formatMonthYear(DateTime.now()),
            style: GoogleFonts.dmSans(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Net Balance',
            style: GoogleFonts.dmSans(
              color: Colors.white,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            formatAmount(net.abs()),
            style: GoogleFonts.dmSans(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: netColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              net >= 0 ? '▲ surplus this month' : '▼ deficit this month',
              style: GoogleFonts.dmSans(
                color: netColor == kCredit ? Colors.greenAccent : Colors.redAccent,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _StatBox(
                  label: 'Spent',
                  value: formatAmount(provider.totalSpentThisMonth),
                  icon: Icons.arrow_upward_rounded,
                  color: kDebit,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatBox(
                  label: 'Received',
                  value: formatAmount(provider.totalReceivedThisMonth),
                  icon: Icons.arrow_downward_rounded,
                  color: kCredit,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatBox({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 14),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.dmSans(
                    color: Colors.white60,
                    fontSize: 11,
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.dmSans(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
