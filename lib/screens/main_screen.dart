import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';
import '../models/shop.dart';
import '../models/receipt.dart';
import 'package:fl_chart/fl_chart.dart';
import '../l10n/app_localizations.dart';
import '../main.dart';
import 'dart:io';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:collection/collection.dart';
import 'dart:math';
import 'dart:ui';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';

// --- МОДЕЛИ ДАННЫХ ---
class ChartSegment {
  final String label;
  final String address;
  final double value;
  final double amount;
  final Color color;

  ChartSegment({
    required this.label,
    required this.address,
    required this.value,
    required this.amount,
    required this.color,
  });
}

// --- ОСНОВНОЙ ЭКРАН ---
class MainScreen extends StatefulWidget {
  final String login;
  final String password;
  final String apiKey;
  final String token;
  const MainScreen({super.key, required this.login, required this.password, required this.apiKey, required this.token});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  late ApiService apiService;
  List<Shop> shops = [];
  List<Receipt> receipts = [];
  bool isLoading = true;
  String? error;
  
  List<ChartSegment> chartSegments = [];
  int? touchedIndex;
  DateTimeRange? selectedRange;

  late AnimationController _floatingAnimationController;

  @override
  void initState() {
    super.initState();
    _floatingAnimationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _initAndLoadData();
  }

  @override
  void dispose() {
    _floatingAnimationController.dispose();
    super.dispose();
  }

  // --- ЛОГИКА ДАННЫХ ---
  void _processReceipts() {
    final cardReceipts = receipts.where((receipt) {
      return receipt.paymentTransactions.any((pt) =>
          pt.transactionTypeId >= 1 && pt.transactionTypeId <= 4);
    });

    final groupedByAddress = groupBy(cardReceipts, (Receipt r) {
      final shop = shops.firstWhere((s) => s.id == r.shopId,
          orElse: () => Shop(id: r.shopId, title: 'Unknown', websiteUrl: 'Unknown'));
      return shop.websiteUrl;
    });

    final Map<String, double> groupedSums = {};
    final Map<String, String> groupedTitles = {};

    groupedByAddress.forEach((address, receiptsList) {
      double sum = 0;
      for (final receipt in receiptsList) {
        double amount = double.tryParse(receipt.totalAmount.replaceAll(',', '.')) ?? 0.0;
        if (receipt.type == 3 || receipt.type == 4 || receipt.state == 3) {
          amount = -amount.abs();
        }
        sum += amount;
      }
      groupedSums[address] = sum;
      groupedTitles[address] = shops.firstWhere((s) => s.websiteUrl == address).title;
    });

    final totalAmount = groupedSums.values.fold(0.0, (sum, item) => sum + item.abs());
    
    final colors = [
      const Color(0xFFff6b6b), const Color(0xFF4ecdc4), const Color(0xFF45b7d1),
      const Color(0xFFffa726), const Color(0xFFab47bc), const Color(0xFF66bb6a),
    ];
    
    int colorIndex = 0;
    chartSegments = groupedSums.entries.map((entry) {
      final percentage = totalAmount > 0 ? (entry.value.abs() / totalAmount) * 100 : 0.0;
      return ChartSegment(
        label: groupedTitles[entry.key]!,
        address: entry.key,
        value: percentage,
        amount: entry.value,
        color: colors[colorIndex++ % colors.length],
      );
    }).toList();
    
    // Сортировка для стабильного отображения
    chartSegments.sort((a, b) => b.value.compareTo(a.value));
  }

  Future<void> _initAndLoadData({DateTimeRange? range}) async {
    setState(() => isLoading = true);
    try {
      apiService = ApiService(
        login: widget.login, password: widget.password,
        apiKey: widget.apiKey, token: widget.token,
      );
      shops = await apiService.getShops();
      final now = DateTime.now();
      selectedRange = range ?? DateTimeRange(start: now.subtract(const Duration(days: 7)), end: now);
      receipts = await apiService.getReceipts(selectedRange!.start, selectedRange!.end);
      _processReceipts();
      error = null;
    } catch (e) {
      error = e.toString();
      chartSegments = [];
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(DateTime.now().year - 5),
      lastDate: DateTime.now(),
      initialDateRange: selectedRange,
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
             colorScheme: const ColorScheme.light(
              primary: Color(0xFF667eea),
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) await _initAndLoadData(range: picked);
  }

  void _onSegmentTap(int? index) {
    setState(() => touchedIndex = index);
  }

  // --- ОСНОВНОЙ BUILD МЕТОД ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF667eea), Color(0xFF764ba2)],
          ),
        ),
        child: SafeArea(
          child: isLoading
              ? _buildLoadingState()
              : error != null
                  ? _buildErrorState(error!)
                  : _buildDashboardContent(),
        ),
      ),
    );
  }
  
  // --- ВИДЖЕТЫ СОСТОЯНИЙ ---
  Widget _buildLoadingState() {
    return Center(child: CircularProgressIndicator(color: Colors.white));
  }

  Widget _buildErrorState(String errorMessage) {
    return Center(
      child: Text("Error: $errorMessage", style: GoogleFonts.nunito(color: Colors.white, fontSize: 16)),
    );
  }
  
  Widget _buildDashboardContent() {
    final chartDiameter = min(MediaQuery.of(context).size.width * 0.8, 300.0);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          FadeInDown(
            duration: const Duration(milliseconds: 500),
            child: _buildHeader(),
          ),
          const SizedBox(height: 32),
          if (chartSegments.isEmpty)
            FadeInUp(child: _buildNoDataWidget())
          else
            FadeInUp(
              duration: const Duration(milliseconds: 700),
              child: _buildChart(chartDiameter),
            ),
          const SizedBox(height: 32),
          if (touchedIndex != null && touchedIndex! >= 0 && touchedIndex! < chartSegments.length)
             SlideInLeft(
                duration: const Duration(milliseconds: 500),
                child: _buildInfoCard(chartSegments[touchedIndex!]),
             ),
          const SizedBox(height: 24),
          if (chartSegments.isNotEmpty)
            SlideInRight(
                duration: const Duration(milliseconds: 500),
                child: _buildLegend(),
            ),
        ],
      ),
    );
  }

  // --- КОМПОНЕНТЫ ИНТЕРФЕЙСА ---
  Widget _buildHeader() {
    return Column(
      children: [
        GestureDetector(
          onTap: _pickDateRange,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.calendar_today, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text(
                  '${selectedRange!.start.day}.${selectedRange!.start.month} - ${selectedRange!.end.day}.${selectedRange!.end.month}',
                  style: GoogleFonts.nunito(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Аналітика Продажів',
          style: GoogleFonts.nunito(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Статистика по торговим точкам',
          style: GoogleFonts.nunito(color: Colors.white.withOpacity(0.7), fontSize: 16),
        ),
      ],
    );
  }
  
  Widget _buildNoDataWidget() {
    return Column(
      children: [
        SvgPicture.asset('assets/tea_pack.svg', height: 80, colorFilter: ColorFilter.mode(Colors.white.withOpacity(0.5), BlendMode.srcIn)),
        const SizedBox(height: 16),
        Text("Немає даних за вибраний період", style: GoogleFonts.nunito(color: Colors.white70, fontSize: 16)),
      ],
    );
  }

  Widget _buildChart(double diameter) {
    return SizedBox(
      width: diameter,
      height: diameter,
      child: Stack(
        children: [
          PieChart(
            PieChartData(
              sections: _buildPieSections(diameter),
              centerSpaceRadius: diameter * 0.35,
              sectionsSpace: 3,
              pieTouchData: PieTouchData(
                touchCallback: (event, response) {
                  if (event.isInterestedForInteractions) {
                    _onSegmentTap(response?.touchedSection?.touchedSectionIndex);
                  }
                },
              ),
            ),
          ),
          Center(child: _buildChartCenter(diameter)),
        ],
      ),
    );
  }

  List<PieChartSectionData> _buildPieSections(double diameter) {
    return List.generate(chartSegments.length, (i) {
      final isTouched = i == touchedIndex;
      final radius = isTouched ? diameter * 0.14 : diameter * 0.12;
      final segment = chartSegments[i];

      return PieChartSectionData(
        color: segment.color,
        value: segment.value,
        radius: radius,
        showTitle: false,
      );
    });
  }

  Widget _buildChartCenter(double diameter) {
    final bool isValidIndex = touchedIndex != null && touchedIndex! >= 0 && touchedIndex! < chartSegments.length;

    return AnimatedBuilder(
      animation: _floatingAnimationController,
      builder: (context, child) {
        return Transform.translate(
            offset: Offset(0, 5 * sin(_floatingAnimationController.value * 2 * pi)),
            child: child);
      },
      child: Container(
        width: diameter * 0.5,
        height: diameter * 0.5,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.9),
          boxShadow: [
             BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                spreadRadius: 5)
          ],
        ),
        child: Center(
          child: !isValidIndex
              ? SvgPicture.asset('assets/tea_pack.svg', height: diameter * 0.2, colorFilter: ColorFilter.mode(const Color(0xFF667eea), BlendMode.srcIn))
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${chartSegments[touchedIndex!].value.toStringAsFixed(1)}%',
                      style: GoogleFonts.nunito(
                        fontSize: diameter * 0.1,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF333333),
                      ),
                    ),
                    Text(
                      'Поточний',
                      style: GoogleFonts.nunito(
                        fontSize: diameter * 0.05,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(ChartSegment segment) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [segment.color.withOpacity(0.8), segment.color],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: segment.color.withOpacity(0.4),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            segment.label,
            style: GoogleFonts.nunito(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            segment.address,
            style: GoogleFonts.nunito(color: Colors.white.withOpacity(0.8), fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const Divider(color: Colors.white54, height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Сума: ',
                style: GoogleFonts.nunito(color: Colors.white, fontSize: 18),
              ),
              Text(
                '${segment.amount.toStringAsFixed(2)} ₴',
                style: GoogleFonts.nunito(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildLegend() {
    // Изменено: Отображаем только топ-3
    final legendItemsCount = min(3, chartSegments.length);

    return Wrap(
      spacing: 16,
      runSpacing: 10,
      alignment: WrapAlignment.center,
      children: List.generate(legendItemsCount, (i) {
        final segment = chartSegments[i];
        final isSelected = i == touchedIndex;
        return GestureDetector(
          onTap: () => _onSegmentTap(i),
          child: AnimatedContainer(
             duration: const Duration(milliseconds: 300),
             padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
             decoration: BoxDecoration(
               color: isSelected ? Colors.white.withOpacity(0.3) : Colors.transparent,
               borderRadius: BorderRadius.circular(16)
             ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: segment.color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${segment.label} (${segment.value.toStringAsFixed(0)}%)',
                  style: GoogleFonts.nunito(color: Colors.white, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}