import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/theme_manager.dart';
import '../models/transaction.dart';
import '../utils/transaction_manager.dart';
import '../utils/localization_helper.dart';

class TransactionHistoryScreen extends StatefulWidget {
  final bool showAppBar;
  final String? initialSearchQuery;
  const TransactionHistoryScreen({
    super.key,
    this.showAppBar = true,
    this.initialSearchQuery,
  });

  @override
  State<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  int _selectedFilterIndex = 0;
  List<String> get _filters => [
    L10n.s('all_filter'),
    L10n.s('received'),
    L10n.s('sent'),
    L10n.s('bills'),
  ];
  late final TextEditingController _searchController;
  late String _searchQuery;

  @override
  void initState() {
    super.initState();
    _searchQuery = widget.initialSearchQuery ?? "";
    _searchController = TextEditingController(text: _searchQuery);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Transaction> _filterTransactions(List<Transaction> allTransactions) {
    List<Transaction> filtered = allTransactions;

    // Apply Search
    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where(
            (t) =>
                t.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                t.details.toLowerCase().contains(_searchQuery.toLowerCase()),
          )
          .toList();
    }

    // Apply Tabs
    switch (_selectedFilterIndex) {
      case 1: // Received
        filtered = filtered.where((t) => t.isPositive).toList();
        break;
      case 2: // Sent
        filtered = filtered.where((t) => !t.isPositive).toList();
        break;
      case 3: // Bills
        filtered = filtered
            .where((t) => t.category == TransactionCategory.bills)
            .toList();
        break;
    }

    return filtered;
  }

  Map<String, List<Transaction>> _groupByDate(List<Transaction> transactions) {
    final groups = <String, List<Transaction>>{};
    for (var t in transactions) {
      final dateStr = t.formattedDate;
      if (groups.containsKey(dateStr)) {
        groups[dateStr]!.add(t);
      } else {
        groups[dateStr] = [t];
      }
    }
    return groups;
  }

  Future<void> _generatePdf(DateTime start, DateTime end) async {
    // 1. Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF1E1E2C)
                : Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const CircularProgressIndicator(color: Colors.indigo),
        ),
      ),
    );

    try {
      final allTransactions = TransactionManager().transactions;
      final filtered = allTransactions.where((t) {
        return t.date.isAfter(start.subtract(const Duration(seconds: 1))) &&
            t.date.isBefore(end.add(const Duration(days: 1)));
      }).toList();

      if (filtered.isEmpty) {
        if (mounted) Navigator.pop(context); // Close loading
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("No transactions found for the selected period"),
            ),
          );
        }
        return;
      }

      final pdf = pw.Document();

      // Load fonts with fallback
      pw.Font? font;
      pw.Font? fontBold;

      try {
        font = await PdfGoogleFonts.spaceGroteskRegular();
        fontBold = await PdfGoogleFonts.spaceGroteskBold();
        debugPrint("Premium fonts loaded successfully");
      } catch (e) {
        debugPrint("Font loading failed, falling back to Helvetica: $e");
        font = pw.Font.helvetica();
        fontBold = pw.Font.helveticaBold();
      }

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          header: (context) => pw.Container(
            alignment: pw.Alignment.centerRight,
            margin: const pw.EdgeInsets.only(bottom: 20),
            child: pw.Text(
              'Page ${context.pageNumber} of ${context.pagesCount}',
              style: pw.TextStyle(
                color: PdfColors.grey700,
                font: font,
                fontSize: 10,
              ),
            ),
          ),
          build: (context) => [
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        "Transaction Statement",
                        style: pw.TextStyle(
                          font: fontBold,
                          fontSize: 26,
                          color: PdfColors.indigo900,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        "Digital Wallet ID: ${FirebaseAuth.instance.currentUser?.phoneNumber ?? FirebaseAuth.instance.currentUser?.uid ?? 'Account'}",
                        style: pw.TextStyle(
                          font: font,
                          fontSize: 12,
                          color: PdfColors.grey700,
                        ),
                      ),
                    ],
                  ),
                  pw.Container(
                    width: 60,
                    height: 60,
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.indigo,
                      shape: pw.BoxShape.circle,
                    ),
                    alignment: pw.Alignment.center,
                    child: pw.Text(
                      "W",
                      style: pw.TextStyle(
                        font: fontBold,
                        color: PdfColors.white,
                        fontSize: 30,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 30),
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColors.indigo50,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    "Report Period:",
                    style: pw.TextStyle(font: fontBold, fontSize: 12),
                  ),
                  pw.Text(
                    "${DateFormat('dd MMM yyyy').format(start)} - ${DateFormat('dd MMM yyyy').format(end)}",
                    style: pw.TextStyle(font: font, fontSize: 12),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 30),
            pw.TableHelper.fromTextArray(
              headers: ['DATE', 'TITLE', 'CATEGORY', 'AMOUNT'],
              data: filtered.map((t) {
                return [
                  DateFormat('dd/MM/yy').format(t.date),
                  t.title,
                  t.category.name.toUpperCase(),
                  t.formattedAmount,
                ];
              }).toList(),
              headerStyle: pw.TextStyle(
                font: fontBold,
                color: PdfColors.white,
                fontSize: 10,
              ),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.indigo),
              cellStyle: pw.TextStyle(font: font, fontSize: 10),
              cellAlignment: pw.Alignment.centerLeft,
              columnWidths: {
                0: const pw.FixedColumnWidth(80),
                1: const pw.FlexColumnWidth(),
                2: const pw.FixedColumnWidth(80),
                3: const pw.FixedColumnWidth(100),
              },
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              headerHeight: 30,
              cellPadding: const pw.EdgeInsets.all(8),
            ),
            pw.SizedBox(height: 40),
            pw.Divider(color: PdfColors.grey300),
            pw.SizedBox(height: 10),
            pw.Center(
              child: pw.Text(
                "Thank you for using our Digital Wallet service!",
                style: pw.TextStyle(
                  font: font,
                  fontSize: 10,
                  color: PdfColors.grey600,
                  fontStyle: pw.FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      );

      if (mounted) Navigator.pop(context); // Close loading

      await Printing.sharePdf(
        bytes: await pdf.save(),
        filename: 'Wallet_Statement_${DateFormat('ddMMyy').format(start)}.pdf',
      );
    } catch (e) {
      debugPrint("PDF Generation Error: $e");
      if (mounted) Navigator.pop(context); // Close loading
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Could not generate report: $e"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _showDownloadOptions() {
    DateTime start = DateTime.now().subtract(const Duration(days: 30));
    DateTime end = DateTime.now();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E2C) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                L10n.s("generate_statement"),
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                L10n.s("select_duration_report"),
                style: GoogleFonts.spaceGrotesk(color: Colors.grey),
              ),
              const SizedBox(height: 32),

              // Date Selectors
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "FROM",
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: start,
                              firstDate: DateTime(2020),
                              lastDate: end,
                            );
                            if (date != null) setModalState(() => start = date);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withOpacity(0.05)
                                  : Colors.grey[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.calendar_today_rounded,
                                  size: 16,
                                  color: Colors.indigo,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  DateFormat('dd MMM yyyy').format(start),
                                  style: GoogleFonts.spaceGrotesk(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "TO",
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: end,
                              firstDate: start,
                              lastDate: DateTime.now(),
                            );
                            if (date != null) setModalState(() => end = date);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withOpacity(0.05)
                                  : Colors.grey[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.calendar_today_rounded,
                                  size: 16,
                                  color: Colors.indigo,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  DateFormat('dd MMM yyyy').format(end),
                                  style: GoogleFonts.spaceGrotesk(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 40),

              // Generate Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _generatePdf(start, end);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    L10n.s("download_statement"),
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Premium Header
          SliverAppBar(
            expandedHeight: 180,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: isDark ? AppColors.darkBg : AppColors.primary,
            leading: widget.showAppBar
                ? IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white,
                    ),
                    onPressed: () => Navigator.pop(context),
                  )
                : null,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [const Color(0xFF1E1E2C), const Color(0xFF12121A)]
                        : [AppColors.primary, const Color(0xFF5046E5)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: -20,
                      right: -20,
                      child: CircleAvatar(
                        radius: 80,
                        backgroundColor: Colors.white.withOpacity(0.05),
                      ),
                    ),
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  L10n.s("history"),
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: _showDownloadOptions,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.2),
                                      ),
                                    ),
                                    child: Text(
                                      L10n.s("download"),
                                      style: GoogleFonts.spaceGrotesk(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              L10n.s("track_spending"),
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Search, Filter & Download Action
          SliverToBoxAdapter(
            child: Transform.translate(
              offset: const Offset(0, -30),
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurface : Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Search Bar
                        Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withOpacity(0.05)
                                : Colors.grey[100],
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: TextField(
                            controller: _searchController,
                            onChanged: (val) =>
                                setState(() => _searchQuery = val),
                            style: GoogleFonts.spaceGrotesk(fontSize: 14),
                            decoration: InputDecoration(
                              hintText: L10n.s("search_transactions"),
                              hintStyle: GoogleFonts.spaceGrotesk(
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                              prefixIcon: const Icon(
                                Icons.search_rounded,
                                size: 20,
                                color: Colors.grey,
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 12,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Filter Chips
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          child: Row(
                            children: List.generate(_filters.length, (index) {
                              final isSelected = _selectedFilterIndex == index;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: GestureDetector(
                                  onTap: () => setState(
                                    () => _selectedFilterIndex = index,
                                  ),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 18,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? AppColors.primary
                                          : (isDark
                                                ? Colors.white.withOpacity(0.05)
                                                : Colors.grey[100]),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: isSelected
                                            ? Colors.transparent
                                            : (isDark
                                                  ? Colors.white.withOpacity(
                                                      0.1,
                                                    )
                                                  : Colors.grey.withOpacity(
                                                      0.1,
                                                    )),
                                      ),
                                    ),
                                    child: Text(
                                      _filters[index],
                                      style: GoogleFonts.spaceGrotesk(
                                        color: isSelected
                                            ? Colors.white
                                            : Colors.grey,
                                        fontSize: 13,
                                        fontWeight: isSelected
                                            ? FontWeight.bold
                                            : FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),

          // Transactions List
          ValueListenableBuilder<List<Transaction>>(
            valueListenable: TransactionManager().transactionsNotifier,
            builder: (context, transactions, _) {
              final filtered = _filterTransactions(transactions);

              if (filtered.isEmpty) {
                return SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          size: 80,
                          color: Colors.grey.withOpacity(0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          L10n.s("no_transactions_found"),
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                        Text(
                          L10n.s("try_adjusting_filters"),
                          style: GoogleFonts.spaceGrotesk(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final grouped = _groupByDate(filtered);

              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final date = grouped.keys.elementAt(index);
                    final items = grouped[date]!;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(
                            top: 10,
                            bottom: 12,
                            left: 4,
                          ),
                          child: Text(
                            date.toUpperCase(),
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: Colors.grey,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                        ...items.map((t) => _buildTransactionCard(t, isDark)),
                        const SizedBox(height: 12),
                      ],
                    );
                  }, childCount: grouped.length),
                ),
              );
            },
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(Transaction t, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.05)
              : Colors.grey.withOpacity(0.1),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {}, // Detail view could be added here
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: t.color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(t.icon, color: t.color, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      Text(
                        t.details.isEmpty
                            ? t.category.name.toUpperCase()
                            : t.details,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      t.formattedAmount,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: t.isPositive
                            ? Colors.green
                            : (isDark ? Colors.white : Colors.black87),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: t.isPositive
                            ? Colors.green.withOpacity(0.1)
                            : Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        t.isPositive ? "SUCCESS" : "COMPLETED",
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          color: t.isPositive ? Colors.green : Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
