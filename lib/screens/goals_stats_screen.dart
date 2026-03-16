import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/nutrition_provider.dart';
import '../models/nutrition_stats.dart';
import '../models/nutrition_goals.dart';
import '../models/goal_period.dart';
import '../theme/app_theme.dart';
import 'new_settings_screen.dart';

class GoalsStatsScreen extends StatefulWidget {
  const GoalsStatsScreen({super.key});

  @override
  State<GoalsStatsScreen> createState() => _GoalsStatsScreenState();
}

class _GoalsStatsScreenState extends State<GoalsStatsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  StatsPeriod _selectedPeriod = StatsPeriod.thisWeek;

  // Goal editing controllers
  final _caloriesController = TextEditingController();
  final _proteinController = TextEditingController();
  final _carbsController = TextEditingController();
  final _fatController = TextEditingController();
  DateTime _goalStartDate = DateTime.now();
  DateTime? _goalEndDate;
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // Load statistics and initialize goal form
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<NutritionProvider>();
      provider.loadStatistics().then((_) {
        // After loading, ensure current period stats are available
        if (!provider.statsCache.containsKey(_selectedPeriod)) {
          provider.getStatsForPeriod(_selectedPeriod);
        }
      });
      _initializeGoalForm(provider);
    });
  }

  void _initializeGoalForm(NutritionProvider provider) {
    final goals = provider.goals ?? NutritionGoals.balanced2000();
    _caloriesController.text = goals.calories.toStringAsFixed(0);
    _proteinController.text = goals.protein.toStringAsFixed(0);
    _carbsController.text = goals.carbs.toStringAsFixed(0);
    _fatController.text = goals.fat.toStringAsFixed(0);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Goals & Stats'),
        backgroundColor: AppTheme.surface,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const NewSettingsScreen(),
                ),
              );
            },
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
          ),
        ],
      ),
      body: Consumer<NutritionProvider>(
        builder: (context, provider, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildStatsSection(provider),
                const SizedBox(height: 32),
                _buildGoalsSection(provider),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatsSection(NutritionProvider provider) {
    return Container(
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                const Icon(Icons.analytics, color: AppTheme.primary, size: 24),
                const SizedBox(width: 12),
                const Text(
                  'Your Statistics',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const Spacer(),
                if (provider.isLoadingStats)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
          ),
          
          // Period tabs
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: AppTheme.surfaceVariant,
              borderRadius: BorderRadius.circular(8),
            ),
            child: TabBar(
              controller: _tabController,
              onTap: (index) {
                setState(() {
                  _selectedPeriod = StatsPeriod.values[index];
                });
                // Load stats for the selected period if not cached
                final provider = context.read<NutritionProvider>();
                if (!provider.statsCache.containsKey(_selectedPeriod)) {
                  provider.getStatsForPeriod(_selectedPeriod);
                }
              },
              tabs: StatsPeriod.values.map((period) => 
                Tab(text: period.label)
              ).toList(),
              indicator: BoxDecoration(
                color: AppTheme.primary,
                borderRadius: BorderRadius.circular(6),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: Colors.white,
              unselectedLabelColor: AppTheme.textSecondary,
              dividerColor: Colors.transparent,
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Stats grid
          if (provider.statsCache.containsKey(_selectedPeriod))
            _buildStatsGrid(provider.statsCache[_selectedPeriod]!)
          else if (!provider.isLoadingStats)
            _buildEmptyStats()
          else
            _buildLoadingStats(),
          
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(NutritionStats stats) {
    final kpis = [
      _StatKPI('Meals Tracked', stats.mealsTracked.toString(), Icons.restaurant_menu, AppTheme.primary, description: 'Total number of meals you have logged during this goal period.'),
      _StatKPI('Avg Calories', stats.averageCaloriesFormatted, Icons.local_fire_department, AppTheme.calories, description: 'Average daily calorie intake calculated from all meals logged.'),
      _StatKPI('Deficit Days', stats.daysWithCalorieDeficit.toString(), Icons.trending_down, AppTheme.success, description: 'Number of days where your calorie intake was below your daily goal.'),
      _StatKPI('Avg Delta', stats.averageCalorieDeltaFormatted, Icons.swap_vert, _getDeltaColor(stats.averageCalorieDelta), description: 'Average difference between your goal and actual intake. Negative = under goal.'),
      _StatKPI('Protein Goals', stats.proteinGoalHitRateFormatted, Icons.fitness_center, AppTheme.protein, description: 'Percentage of days where you met or exceeded your protein intake goal.'),
      _StatKPI('Consistency', stats.loggingConsistencyFormatted, Icons.checklist, _getConsistencyColor(stats.loggingConsistency), description: 'Percentage of days in this period where you logged at least one meal.'),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 1.4,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: kpis.length,
        itemBuilder: (context, index) => _buildStatCard(kpis[index]),
      ),
    );
  }

  Widget _buildStatCard(_StatKPI kpi) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kpi.color.withAlpha(15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kpi.color.withAlpha(50)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                kpi.icon,
                color: kpi.color,
                size: 24,
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => _showKPIExplanation(kpi),
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: kpi.color.withAlpha(50),
                  ),
                  child: Icon(
                    Icons.help_outline,
                    size: 12,
                    color: kpi.color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            kpi.value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: kpi.color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            kpi.label,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _showKPIExplanation(_StatKPI kpi) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(kpi.icon, color: kpi.color),
            const SizedBox(width: 8),
            Text(kpi.label),
          ],
        ),
        content: Text(kpi.description),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyStats() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SizedBox(
        height: 200,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.insert_chart_outlined,
                size: 48,
                color: AppTheme.textTertiary,
              ),
              const SizedBox(height: 16),
              const Text(
                'No data for this period',
                style: TextStyle(
                  fontSize: 16,
                  color: AppTheme.textTertiary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Start logging meals to see your stats!',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textTertiary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingStats() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SizedBox(
        height: 200,
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }

  Widget _buildGoalsSection(NutritionProvider provider) {
    return Container(
      decoration: AppTheme.cardDecoration,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Icon(Icons.flag, color: AppTheme.primary, size: 24),
                const SizedBox(width: 12),
                const Text(
                  'Nutrition Goals',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Set your daily nutrition targets with flexible scheduling',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withAlpha(15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.primary.withAlpha(50)),
                  ),
                  child: const Text(
                    '💡 Tip: Goals automatically become active on their start date. Leave end date empty for open-ended goals, or set an end date for time-limited goals.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Goal form
            _buildGoalForm(provider),
            
            const SizedBox(height: 24),
            
            // Goal history
            if (provider.goalHistory.isNotEmpty) ...[
              const Text(
                'Goal History',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              _buildGoalHistory(provider),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildGoalForm(NutritionProvider provider) {
    return Column(
      children: [
        // Nutrition inputs
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _caloriesController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Calories',
                  suffixText: 'cal',
                  prefixIcon: Icon(Icons.local_fire_department, size: 20),
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _proteinController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Protein',
                  suffixText: 'g',
                  prefixIcon: Icon(Icons.fitness_center, size: 20),
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _carbsController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Carbs',
                  suffixText: 'g',
                  prefixIcon: Icon(Icons.grass, size: 20),
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _fatController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Fat',
                  suffixText: 'g',
                  prefixIcon: Icon(Icons.opacity, size: 20),
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Date range pickers
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: _selectGoalStartDate,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.play_arrow, size: 16, color: AppTheme.primary),
                          SizedBox(width: 4),
                          Text(
                            'Start Date',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatDate(_goalStartDate),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: InkWell(
                onTap: _selectGoalEndDate,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _goalEndDate != null ? Icons.stop : Icons.all_inclusive,
                            size: 16,
                            color: _goalEndDate != null ? AppTheme.error : AppTheme.secondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'End Date',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (_goalEndDate != null) ...[
                            const Spacer(),
                            GestureDetector(
                              onTap: _clearEndDate,
                              child: const Icon(
                                Icons.clear,
                                size: 16,
                                color: AppTheme.textTertiary,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _goalEndDate != null ? _formatDate(_goalEndDate!) : 'Open-ended',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: _goalEndDate != null ? AppTheme.textPrimary : AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Notes
        TextFormField(
          controller: _notesController,
          decoration: const InputDecoration(
            labelText: 'Notes (optional)',
            hintText: 'e.g., "Weight loss phase"',
            prefixIcon: Icon(Icons.note, size: 20),
          ),
          maxLines: 2,
        ),
        
        const SizedBox(height: 24),
        
        // Save button
        ElevatedButton.icon(
          onPressed: () => _saveGoals(provider),
          icon: const Icon(Icons.save, size: 20),
          label: const Text('Save New Goals'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            minimumSize: const Size(double.infinity, 0),
          ),
        ),
      ],
    );
  }

  Widget _buildGoalHistory(NutritionProvider provider) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.divider),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: provider.goalHistory.take(5).map((goalPeriod) {
          final isActive = goalPeriod.id == provider.currentGoalPeriod?.id;
          final canDelete = goalPeriod.canBeDeleted;
          
          Widget goalTile = Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isActive ? AppTheme.primary.withAlpha(15) : null,
              border: provider.goalHistory.indexOf(goalPeriod) > 0
                  ? const Border(top: BorderSide(color: AppTheme.divider))
                  : null,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        goalPeriod.dateRangeString,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isActive ? AppTheme.primary : AppTheme.textPrimary,
                        ),
                      ),
                      if (goalPeriod.notes.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          goalPeriod.notes,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                      if (goalPeriod.durationDays != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          '${goalPeriod.durationDays} days',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.textTertiary,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                      if (canDelete) ...[
                        const SizedBox(height: 2),
                        const Text(
                          'Future goal • Swipe left to delete',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppTheme.textTertiary,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const Spacer(),
                Text(
                  '${goalPeriod.goals.calories.toInt()} cal',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
                if (isActive) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'Active',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );

          // Wrap future goals with Dismissible for swipe-to-delete
          if (canDelete) {
            return Dismissible(
              key: Key(goalPeriod.id),
              direction: DismissDirection.endToStart,
              confirmDismiss: (direction) => _confirmDeleteGoalPeriod(goalPeriod),
              onDismissed: (direction) => _deleteGoalPeriod(goalPeriod, provider),
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 16),
                decoration: BoxDecoration(
                  color: AppTheme.error,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.delete,
                      color: Colors.white,
                      size: 24,
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Delete',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              child: goalTile,
            );
          }

          return goalTile;
        }).toList(),
      ),
    );
  }

  Future<void> _selectGoalStartDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _goalStartDate,
      firstDate: DateTime(2020),
      lastDate: _goalEndDate ?? DateTime.now().add(const Duration(days: 365)),
      helpText: 'Select goal start date',
    );

    if (date != null) {
      setState(() {
        _goalStartDate = date;
        // If end date is before start date, clear it
        if (_goalEndDate != null && _goalEndDate!.isBefore(date)) {
          _goalEndDate = null;
        }
      });
    }
  }

  Future<void> _selectGoalEndDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _goalEndDate ?? _goalStartDate.add(const Duration(days: 30)),
      firstDate: _goalStartDate.add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
      helpText: 'Select goal end date (optional)',
    );

    if (date != null) {
      setState(() {
        _goalEndDate = date;
      });
    }
  }

  void _clearEndDate() {
    setState(() {
      _goalEndDate = null;
    });
  }

  Future<void> _saveGoals(NutritionProvider provider) async {
    final calories = double.tryParse(_caloriesController.text) ?? 2000;
    final protein = double.tryParse(_proteinController.text) ?? 150;
    final carbs = double.tryParse(_carbsController.text) ?? 250;
    final fat = double.tryParse(_fatController.text) ?? 65;

    final goals = NutritionGoals(
      calories: calories,
      protein: protein,
      carbs: carbs,
      fat: fat,
    );

    try {
      await provider.createNewGoalPeriod(goals, _goalStartDate, _notesController.text, endDate: _goalEndDate);
      
      if (mounted) {
        HapticFeedback.mediumImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎯 New goals saved successfully!'),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        
        // Clear form
        _notesController.clear();
        _goalStartDate = DateTime.now();
        _goalEndDate = null;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save goals: $e'),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<bool?> _confirmDeleteGoalPeriod(GoalPeriod goalPeriod) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Goal Period'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to delete this future goal period?'),
            const SizedBox(height: 8),
            Text(
              'Period: ${goalPeriod.dateRangeString}',
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (goalPeriod.notes.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Notes: ${goalPeriod.notes}',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
            const SizedBox(height: 8),
            const Text(
              'This action cannot be undone.',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.error,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteGoalPeriod(GoalPeriod goalPeriod, NutritionProvider provider) async {
    try {
      await provider.deleteGoalPeriod(goalPeriod.id);

      if (mounted) {
        HapticFeedback.mediumImpact();
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Goal period deleted: ${goalPeriod.dateRangeString}'),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete goal period: $e'),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Color _getDeltaColor(double delta) {
    if (delta < -200) return AppTheme.success;
    if (delta > 200) return AppTheme.error;
    return AppTheme.secondary;
  }

  Color _getConsistencyColor(double consistency) {
    if (consistency >= 0.8) return AppTheme.success;
    if (consistency >= 0.5) return AppTheme.secondary;
    return AppTheme.error;
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                   'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

class _StatKPI {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String description;

  const _StatKPI(this.label, this.value, this.icon, this.color, {required this.description});
}