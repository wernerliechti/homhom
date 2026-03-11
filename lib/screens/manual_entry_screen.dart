import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/food_item.dart';
import '../models/nutrition_data.dart';
import '../providers/nutrition_provider.dart';
import '../theme/app_theme.dart';

class ManualEntryScreen extends StatefulWidget {
  const ManualEntryScreen({super.key});

  @override
  State<ManualEntryScreen> createState() => _ManualEntryScreenState();
}

class _ManualEntryScreenState extends State<ManualEntryScreen> {
  late TextEditingController _nameController;
  late TextEditingController _caloriesController;
  late TextEditingController _descriptionController;
  late TextEditingController _weightController;
  late TextEditingController _proteinController;
  late TextEditingController _carbsController;
  late TextEditingController _fatController;
  late TextEditingController _fiberController;
  late TextEditingController _sugarController;
  late TextEditingController _sodiumController;
  late TextEditingController _vitaminCController;
  late TextEditingController _calciumController;
  late TextEditingController _ironController;

  bool _isSaving = false;
  bool _showOptionalFields = false;
  DateTime _selectedMealTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _caloriesController = TextEditingController();
    _descriptionController = TextEditingController();
    _weightController = TextEditingController(text: '100');
    _proteinController = TextEditingController();
    _carbsController = TextEditingController();
    _fatController = TextEditingController();
    _fiberController = TextEditingController();
    _sugarController = TextEditingController();
    _sodiumController = TextEditingController();
    _vitaminCController = TextEditingController();
    _calciumController = TextEditingController();
    _ironController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _caloriesController.dispose();
    _descriptionController.dispose();
    _weightController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    _fiberController.dispose();
    _sugarController.dispose();
    _sodiumController.dispose();
    _vitaminCController.dispose();
    _calciumController.dispose();
    _ironController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manual Entry'),
        backgroundColor: AppTheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(false),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildRequiredSection(),
            const SizedBox(height: 24),
            _buildMealTimeSection(),
            const SizedBox(height: 24),
            _buildOptionalToggle(),
            if (_showOptionalFields) ...[
              const SizedBox(height: 16),
              _buildOptionalSection(),
            ],
            const SizedBox(height: 32),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.primary.withAlpha(20),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.edit_note,
            size: 48,
            color: AppTheme.primary,
          ),
          SizedBox(height: 12),
          Text(
            'Add Food Manually',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppTheme.primary,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Name & Calories are required • Everything else is optional',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRequiredSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.required_rounded, color: AppTheme.error, size: 20),
              SizedBox(width: 8),
              Text(
                'Required Fields',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildTextField(
            'Food Name',
            _nameController,
            'e.g. Chicken Breast, Apple',
            isHint: true,
          ),
          const SizedBox(height: 12),
          _buildTextField(
            'Calories',
            _caloriesController,
            'kcal',
            keyboardType: TextInputType.number,
          ),
        ],
      ),
    );
  }

  Widget _buildMealTimeSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.schedule, color: AppTheme.primary, size: 20),
              SizedBox(width: 8),
              Text(
                'Meal Time',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Material(
            color: AppTheme.surfaceVariant,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: _selectMealTime,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.divider),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _formatDate(_selectedMealTime),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatTime(_selectedMealTime),
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const Icon(Icons.edit_calendar, color: AppTheme.primary),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionalToggle() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() {
            _showOptionalFields = !_showOptionalFields;
          });
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Icon(
                _showOptionalFields ? Icons.expand_less : Icons.expand_more,
                color: AppTheme.primary,
              ),
              const SizedBox(width: 8),
              const Text(
                'Add Optional Fields',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionalSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.science, color: AppTheme.secondary, size: 20),
              SizedBox(width: 8),
              Text(
                'Optional Fields',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildTextField(
            'Description',
            _descriptionController,
            'e.g. grilled, skinless',
            isHint: true,
          ),
          const SizedBox(height: 12),
          _buildTextField(
            'Weight',
            _weightController,
            'g',
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          const Divider(height: 24),
          const SizedBox(height: 8),
          const Text(
            'Macronutrients',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  'Protein',
                  _proteinController,
                  'g',
                  keyboardType: TextInputType.number,
                  compact: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTextField(
                  'Carbs',
                  _carbsController,
                  'g',
                  keyboardType: TextInputType.number,
                  compact: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildTextField(
            'Fat',
            _fatController,
            'g',
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          const Divider(height: 24),
          const SizedBox(height: 8),
          const Text(
            'Micronutrients',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          _buildTextField(
            'Fiber',
            _fiberController,
            'g',
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          _buildTextField(
            'Sugar',
            _sugarController,
            'g',
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          _buildTextField(
            'Sodium',
            _sodiumController,
            'mg',
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          _buildTextField(
            'Vitamin C',
            _vitaminCController,
            'mg',
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          _buildTextField(
            'Calcium',
            _calciumController,
            'mg',
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          _buildTextField(
            'Iron',
            _ironController,
            'mg',
            keyboardType: TextInputType.number,
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    String? suffix, {
    bool isHint = false,
    bool compact = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: isHint ? suffix : null,
            suffixText: !isHint ? suffix : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppTheme.divider),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppTheme.divider),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppTheme.primary, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            isDense: compact,
          ),
          inputFormatters: keyboardType == TextInputType.number
              ? [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}$'))]
              : null,
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton.icon(
          onPressed: _isSaving ? null : _saveFoodItem,
          icon: _isSaving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.save, size: 20),
          label: Text(_isSaving ? 'Saving...' : 'Save Food Item'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(false),
          icon: const Icon(Icons.close, size: 20),
          label: const Text('Cancel'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppTheme.textSecondary,
            side: const BorderSide(color: AppTheme.divider),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ],
    );
  }

  Future<void> _selectMealTime() async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedMealTime,
      firstDate: DateTime(now.year - 1),
      lastDate: now,
    );

    if (pickedDate == null) return;

    if (mounted) {
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedMealTime),
      );

      if (pickedTime != null) {
        setState(() {
          _selectedMealTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  String _formatDate(DateTime date) {
    final today = DateTime.now();
    final yesterday = today.subtract(const Duration(days: 1));

    if (date.year == today.year && date.month == today.month && date.day == today.day) {
      return 'Today';
    } else if (date.year == yesterday.year && date.month == yesterday.month && date.day == yesterday.day) {
      return 'Yesterday';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  String _formatTime(DateTime time) {
    final hour = time.hour;
    final minute = time.minute;
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:${minute.toString().padLeft(2, '0')} $period';
  }

  Future<void> _saveFoodItem() async {
    // Validate required fields
    if (_nameController.text.trim().isEmpty) {
      _showError('Please enter a food name');
      return;
    }

    if (_caloriesController.text.trim().isEmpty) {
      _showError('Please enter calories');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final provider = context.read<NutritionProvider>();

      // Create FoodItem from manual entry
      final foodItem = FoodItem(
        id: Uuid().v4(),
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        estimatedWeight: double.tryParse(_weightController.text) ?? 100,
        confidence: 1.0, // Manual entry has full confidence
        nutrition: NutritionData(
          calories: double.tryParse(_caloriesController.text) ?? 0,
          protein: double.tryParse(_proteinController.text) ?? 0,
          carbs: double.tryParse(_carbsController.text) ?? 0,
          fat: double.tryParse(_fatController.text) ?? 0,
          fiber: _fiberController.text.isNotEmpty ? double.tryParse(_fiberController.text) : null,
          sugar: _sugarController.text.isNotEmpty ? double.tryParse(_sugarController.text) : null,
          sodium: _sodiumController.text.isNotEmpty ? double.tryParse(_sodiumController.text) : null,
          vitaminC: _vitaminCController.text.isNotEmpty ? double.tryParse(_vitaminCController.text) : null,
          calcium: _calciumController.text.isNotEmpty ? double.tryParse(_calciumController.text) : null,
          iron: _ironController.text.isNotEmpty ? double.tryParse(_ironController.text) : null,
        ),
        portionMethod: 'manual',
      );

      // Save meal with manual entry
      await provider.saveMealWithAnalysis(
        null, // No image for manual entry
        [foodItem],
        analysisMetadata: {
          'entryMethod': 'manual',
          'enteredAt': DateTime.now().toIso8601String(),
        },
        mealTime: _selectedMealTime,
      );

      if (mounted) {
        HapticFeedback.mediumImpact();
        Navigator.of(context).pop(true); // Return success
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🍽️ Food item saved successfully!'),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        _showError('Failed to save: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
