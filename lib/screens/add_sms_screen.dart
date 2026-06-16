import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/transaction.dart';
import '../providers/transaction_provider.dart';
import '../services/sms_parser.dart';
import '../theme/app_theme.dart';
import '../utils/category_helper.dart';
import '../utils/formatters.dart';

class AddSmsScreen extends StatefulWidget {
  /// Pre-filled SMS text from an iOS Shortcut deep link.
  final String? prefillText;

  const AddSmsScreen({super.key, this.prefillText});

  @override
  State<AddSmsScreen> createState() => _AddSmsScreenState();
}

class _AddSmsScreenState extends State<AddSmsScreen> {
  final _smsController = TextEditingController();
  ParsedSms? _parsed;
  bool _parseAttempted = false;

  // Editable fields after parsing
  late TextEditingController _merchantCtrl;
  late TextEditingController _amountCtrl;
  late TextEditingController _accountCtrl;
  late TextEditingController _bankCtrl;
  TransactionType _type = TransactionType.debit;
  DateTime _date = DateTime.now();
  String _category = 'Other';

  @override
  void initState() {
    super.initState();
    _merchantCtrl = TextEditingController();
    _amountCtrl = TextEditingController();
    _accountCtrl = TextEditingController();
    _bankCtrl = TextEditingController();

    // Auto-parse if launched via iOS Shortcut deep link
    if (widget.prefillText != null) {
      _smsController.text = widget.prefillText!;
      WidgetsBinding.instance.addPostFrameCallback((_) => _parse());
    }
  }

  @override
  void dispose() {
    _smsController.dispose();
    _merchantCtrl.dispose();
    _amountCtrl.dispose();
    _accountCtrl.dispose();
    _bankCtrl.dispose();
    super.dispose();
  }

  void _parse() {
    final text = _smsController.text.trim();
    if (text.isEmpty) return;

    final result = SmsParser.parse(text);
    setState(() {
      _parsed = result;
      _parseAttempted = true;
      if (result != null) {
        _merchantCtrl.text = result.merchant;
        _amountCtrl.text = result.amount.toStringAsFixed(2);
        _accountCtrl.text = result.accountLast4;
        _bankCtrl.text = result.bankName;
        _type = result.type;
        _date = result.date;
        _category = result.category;
      }
    });
  }

  Future<void> _save() async {
    final amount = double.tryParse(_amountCtrl.text.replaceAll(',', ''));
    if (amount == null || amount <= 0) {
      _showError('Please enter a valid amount.');
      return;
    }
    if (_merchantCtrl.text.trim().isEmpty) {
      _showError('Merchant name is required.');
      return;
    }

    final transaction = Transaction(
      amount: amount,
      type: _type,
      merchant: _merchantCtrl.text.trim(),
      date: _date,
      accountLast4: _accountCtrl.text.trim(),
      bankName: _bankCtrl.text.trim(),
      rawText: _smsController.text.trim(),
      category: _category,
    );

    await context.read<TransactionProvider>().add(transaction);

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Transaction saved!',
            style: GoogleFonts.dmSans(),
          ),
          backgroundColor: kCredit,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.dmSans()),
        backgroundColor: kDebit,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: kPrimary),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _date = picked);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Bank SMS'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SectionLabel('Paste your bank SMS'),
            const SizedBox(height: 8),
            TextField(
              controller: _smsController,
              maxLines: 5,
              style: GoogleFonts.dmSans(fontSize: 14, color: kTextPrimary),
              decoration: InputDecoration(
                hintText:
                    'e.g. "A charge of \$42.50 has been authorized on your Chase card ending 1234 at Amazon on 06/05/2026."',
                hintStyle: GoogleFonts.dmSans(
                    color: kTextSecondary, fontSize: 13),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.content_paste_rounded,
                      color: kPrimary),
                  tooltip: 'Paste from clipboard',
                  onPressed: () async {
                    final data = await Clipboard.getData('text/plain');
                    if (data?.text != null) {
                      _smsController.text = data!.text!;
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _parse,
              icon: const Icon(Icons.auto_fix_high_rounded),
              label: const Text('Extract Transaction'),
            ),

            // ── Parse result ──────────────────────────────────────────────
            if (_parseAttempted && _parsed == null) ...[
              const SizedBox(height: 16),
              _ParseFailBanner(),
            ],
            if (_parsed != null) ...[
              const SizedBox(height: 24),
              _SectionLabel('Transaction Details'),
              const SizedBox(height: 4),
              Text(
                'Review and edit before saving.',
                style:
                    GoogleFonts.dmSans(fontSize: 13, color: kTextSecondary),
              ),
              const SizedBox(height: 16),

              // Type toggle
              _TypeToggle(
                value: _type,
                onChanged: (v) => setState(() => _type = v),
              ),
              const SizedBox(height: 12),

              // Merchant
              _Field(
                label: 'Merchant',
                controller: _merchantCtrl,
                icon: Icons.store_rounded,
              ),
              const SizedBox(height: 12),

              // Amount
              _Field(
                label: 'Amount (\$)',
                controller: _amountCtrl,
                icon: Icons.attach_money_rounded,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 12),

              // Date
              _DateField(
                date: _date,
                onTap: _pickDate,
              ),
              const SizedBox(height: 12),

              // Category
              _CategoryDropdown(
                value: _category,
                onChanged: (v) => setState(() => _category = v!),
              ),
              const SizedBox(height: 12),

              // Bank
              _Field(
                label: 'Bank (optional)',
                controller: _bankCtrl,
                icon: Icons.account_balance_rounded,
              ),
              const SizedBox(height: 12),

              // Account
              _Field(
                label: 'Account last 4 digits (optional)',
                controller: _accountCtrl,
                icon: Icons.credit_card_rounded,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 28),

              ElevatedButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save_rounded),
                label: const Text('Save Transaction'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kCredit,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ],

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ── Helper widgets ────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: GoogleFonts.dmSans(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: kTextPrimary,
        ),
      );
}

class _ParseFailBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: kDebit.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kDebit.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.warning_rounded, color: kDebit, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                "Couldn't find a transaction amount. Make sure the message contains a dollar amount like \$42.50.",
                style: GoogleFonts.dmSans(color: kDebit, fontSize: 13),
              ),
            ),
          ],
        ),
      );
}

class _TypeToggle extends StatelessWidget {
  final TransactionType value;
  final ValueChanged<TransactionType> onChanged;

  const _TypeToggle({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ToggleButton(
            label: 'Expense',
            icon: Icons.arrow_upward_rounded,
            color: kDebit,
            selected: value == TransactionType.debit,
            onTap: () => onChanged(TransactionType.debit),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ToggleButton(
            label: 'Income',
            icon: Icons.arrow_downward_rounded,
            color: kCredit,
            selected: value == TransactionType.credit,
            onTap: () => onChanged(TransactionType.credit),
          ),
        ),
      ],
    );
  }
}

class _ToggleButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _ToggleButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? color : color.withOpacity(0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? color : color.withOpacity(0.2),
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  color: selected ? Colors.white : color, size: 16),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.dmSans(
                  color: selected ? Colors.white : color,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
}

class _Field extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final IconData icon;
  final TextInputType keyboardType;

  const _Field({
    required this.label,
    required this.controller,
    required this.icon,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) => TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: GoogleFonts.dmSans(fontSize: 14, color: kTextPrimary),
        decoration: InputDecoration(
          labelText: label,
          labelStyle:
              GoogleFonts.dmSans(color: kTextSecondary, fontSize: 13),
          prefixIcon: Icon(icon, color: kPrimary, size: 20),
        ),
      );
}

class _DateField extends StatelessWidget {
  final DateTime date;
  final VoidCallback onTap;

  const _DateField({required this.date, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AbsorbPointer(
          child: TextField(
            controller: TextEditingController(
                text: DateFormat('MMM d, yyyy').format(date)),
            style: GoogleFonts.dmSans(fontSize: 14, color: kTextPrimary),
            decoration: InputDecoration(
              labelText: 'Date',
              labelStyle:
                  GoogleFonts.dmSans(color: kTextSecondary, fontSize: 13),
              prefixIcon: const Icon(Icons.calendar_today_rounded,
                  color: kPrimary, size: 20),
              suffixIcon: const Icon(Icons.chevron_right_rounded,
                  color: kTextSecondary),
            ),
          ),
        ),
      );
}

class _CategoryDropdown extends StatelessWidget {
  final String value;
  final ValueChanged<String?> onChanged;

  const _CategoryDropdown({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) => DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: 'Category',
          labelStyle:
              GoogleFonts.dmSans(color: kTextSecondary, fontSize: 13),
          prefixIcon: Text(
            CategoryHelper.iconFor(value),
            style: const TextStyle(fontSize: 18),
          ),
        ),
        style: GoogleFonts.dmSans(fontSize: 14, color: kTextPrimary),
        items: CategoryHelper.categories
            .map(
              (cat) => DropdownMenuItem(
                value: cat,
                child: Text(
                  '${CategoryHelper.iconFor(cat)}  $cat',
                  style: GoogleFonts.dmSans(fontSize: 14),
                ),
              ),
            )
            .toList(),
        onChanged: onChanged,
      );
}
