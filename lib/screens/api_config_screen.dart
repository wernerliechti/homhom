import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/hom_provider.dart';
import '../theme/app_theme.dart';


class ApiConfigScreen extends StatefulWidget {
  const ApiConfigScreen({super.key});

  @override
  State<ApiConfigScreen> createState() => _ApiConfigScreenState();
}

class _ApiConfigScreenState extends State<ApiConfigScreen> {
  final TextEditingController _apiKeyController = TextEditingController();
  bool _isObscured = true;
  bool _isSaving = false;
  
  @override
  void initState() {
    super.initState();
    _loadCurrentApiKey();
  }

  void _loadCurrentApiKey() {
    final provider = context.read<HomProvider>();
    if (provider.balance?.userApiKey != null) {
      _apiKeyController.text = provider.balance!.userApiKey!;
    }
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('OpenAI API Configuration'),
        backgroundColor: AppTheme.surface,
        elevation: 0,
      ),
      body: Consumer<HomProvider>(
        builder: (context, provider, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Explanation card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withAlpha(15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.primary.withAlpha(50)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.lightbulb_outline,
                            color: AppTheme.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Why Use Your Own API Key?',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        '• Get unlimited HOMs (no scan limits)\n'
                        '• Pay only for actual OpenAI usage\n'
                        '• Typically costs ~\$0.01-0.03 per scan\n'
                        '• Keep full control over your usage',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // API key input
                const Text(
                  'OpenAI API Key',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _apiKeyController,
                  obscureText: _isObscured,
                  decoration: InputDecoration(
                    hintText: 'sk-...',
                    prefixIcon: const Icon(Icons.key, size: 20),
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: () {
                            setState(() {
                              _isObscured = !_isObscured;
                            });
                          },
                          icon: Icon(
                            _isObscured ? Icons.visibility : Icons.visibility_off,
                            size: 20,
                          ),
                        ),
                        IconButton(
                          onPressed: () async {
                            final clipboardData = await Clipboard.getData('text/plain');
                            if (clipboardData?.text != null) {
                              _apiKeyController.text = clipboardData!.text!;
                            }
                          },
                          icon: const Icon(Icons.paste, size: 20),
                          tooltip: 'Paste from clipboard',
                        ),
                      ],
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Help text
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceVariant.withAlpha(50),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'How to get your API key:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '1. Visit platform.openai.com\n'
                        '2. Sign up or log in to your account\n'
                        '3. Go to API → API keys\n'
                        '4. Create a new secret key\n'
                        '5. Copy and paste it above',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () {
                          // Could open browser to OpenAI platform
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Visit platform.openai.com to get your API key'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        child: Text(
                          'Visit platform.openai.com →',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.primary,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Action buttons
                Row(
                  children: [
                    if (provider.balance?.userApiKey != null) ...[
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isSaving ? null : () => _removeApiKey(provider),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: AppTheme.error),
                            foregroundColor: AppTheme.error,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text('Remove Key'),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : () => _saveApiKey(provider),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: Text(
                          _isSaving 
                              ? 'Saving...' 
                              : provider.balance?.userApiKey != null
                                  ? 'Update Key'
                                  : 'Save Key',
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Security note
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.secondary.withAlpha(15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.security,
                        color: AppTheme.secondary,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Your API key is stored securely on your device and never shared with our servers.',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _saveApiKey(HomProvider provider) async {
    final apiKey = _apiKeyController.text.trim();
    
    if (apiKey.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your OpenAI API key'),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (!apiKey.startsWith('sk-')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('API key should start with "sk-"'),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await provider.setApiKey(apiKey);
      
      if (mounted) {
        HapticFeedback.mediumImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 API key saved! You now have unlimited HOMs.'),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save API key: $e'),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _removeApiKey(HomProvider provider) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove API Key'),
        content: const Text(
          'Are you sure you want to remove your API key?\n\n'
          'You\'ll switch back to metered mode with 10 free HOMs.',
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
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _isSaving = true;
      });

      try {
        await provider.setApiKey(null);
        _apiKeyController.clear();
        
        if (mounted) {
          HapticFeedback.mediumImpact();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('API key removed. You now have 10 free HOMs.'),
              backgroundColor: AppTheme.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to remove API key: $e'),
              backgroundColor: AppTheme.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isSaving = false;
          });
        }
      }
    }
  }
}