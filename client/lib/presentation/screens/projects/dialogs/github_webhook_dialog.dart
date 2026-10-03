import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_theme.dart';
import '../controllers/projects_controller.dart';

class GitHubWebhookDialog extends ConsumerStatefulWidget {
  final String projectId;
  final String? repoUrl;

  const GitHubWebhookDialog({
    super.key,
    required this.projectId,
    this.repoUrl,
  });

  static Future<void> show(
    BuildContext context, {
    required String projectId,
    String? repoUrl,
  }) async {
    await showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 540),
          child: GitHubWebhookDialog(
            projectId: projectId,
            repoUrl: repoUrl,
          ),
        ),
      ),
    );
  }

  @override
  ConsumerState<GitHubWebhookDialog> createState() =>
      _GitHubWebhookDialogState();
}

class _GitHubWebhookDialogState extends ConsumerState<GitHubWebhookDialog> {
  bool _isLoading = true;
  bool _isGenerating = false;
  String? _webhookUrl;
  String? _webhookSecret;
  bool _hasSecret = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final config = await ref
          .read(projectsControllerProvider)
          .getWebhookConfig(widget.projectId);
      if (mounted) {
        setState(() {
          _webhookUrl = config['webhookUrl'] as String?;
          _hasSecret = config['hasSecret'] == true;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _generateSecret() async {
    setState(() => _isGenerating = true);
    try {
      final result = await ref
          .read(projectsControllerProvider)
          .generateWebhookSecret(widget.projectId);
      if (mounted) {
        setState(() {
          _webhookSecret = result['webhookSecret'] as String?;
          _hasSecret = true;
          _isGenerating = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('New webhook secret generated! Make sure to copy it.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isGenerating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate secret: $e'),
            backgroundColor: AppSemanticColors.of(context).danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied to clipboard!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final primaryRed = colorScheme.primary;
    final semantics = AppSemanticColors.of(context);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: _isLoading
          ? const SizedBox(
              height: 200,
              child: Center(child: CircularProgressIndicator()),
            )
          : SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.webhook_rounded,
                              color: primaryRed, size: 24),
                          const SizedBox(width: 10),
                          const Text(
                            'GitHub Webhook Automation',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Connect this project to GitHub webhooks to automate task and bug lifecycle upon commits, pull requests, and issues.',
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 20),

                  if (_errorMessage != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: semantics.danger.withAlpha(20),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: semantics.danger.withAlpha(50)),
                      ),
                      child: Text(_errorMessage!,
                          style: TextStyle(color: semantics.danger, fontSize: 12)),
                    ),

                  // 1. Webhook URL Field
                  const Text(
                    'PAYLOAD URL',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest.withAlpha(50),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: colorScheme.outlineVariant.withAlpha(40)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _webhookUrl ?? 'Unavailable',
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy_rounded, size: 18),
                          tooltip: 'Copy Payload URL',
                          onPressed: _webhookUrl != null
                              ? () =>
                                  _copyToClipboard(_webhookUrl!, 'Payload URL')
                              : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 2. Webhook Secret Field
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'SECRET (HMAC SHA-256)',
                        style:
                            TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
                      ),
                      if (_hasSecret && _webhookSecret == null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: semantics.success.withAlpha(20),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text('Active on server',
                              style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: semantics.success)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest.withAlpha(50),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: colorScheme.outlineVariant.withAlpha(40)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _webhookSecret ??
                                (_hasSecret
                                    ? '••••••••••••••••••••••••••••••••'
                                    : 'No secret generated yet'),
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12,
                              color: _webhookSecret != null
                                  ? colorScheme.onSurface
                                  : colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        if (_webhookSecret != null)
                          IconButton(
                            icon: const Icon(Icons.copy_rounded, size: 18),
                            tooltip: 'Copy Secret',
                            onPressed: () => _copyToClipboard(
                                _webhookSecret!, 'Webhook Secret'),
                          ),
                        TextButton.icon(
                          onPressed: _isGenerating ? null : _generateSecret,
                          icon: _isGenerating
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2),
                                )
                              : const Icon(Icons.refresh_rounded, size: 16),
                          label: Text(
                            _hasSecret ? 'Rotate Secret' : 'Generate Secret',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 3. Automated Capabilities List
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: primaryRed.withAlpha(12),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: primaryRed.withAlpha(30)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.auto_awesome_rounded,
                                size: 16, color: primaryRed),
                            const SizedBox(width: 8),
                            Text('Active Automation Triggers',
                                style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12,
                                    color: primaryRed)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _featureCheck('Commit Messages: "fixes #12" auto-closes linked tasks/features/bugs'),
                        _featureCheck('Pull Requests: Merging a PR completes all referenced deliverables'),
                        _featureCheck('Issues: New GitHub issues are auto-imported into this project backlog'),
                        _featureCheck('Progress: Project completion % recalculates in real-time'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _featureCheck(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_rounded, size: 14, color: Colors.green),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: const TextStyle(fontSize: 11, height: 1.3)),
          ),
        ],
      ),
    );
  }
}
