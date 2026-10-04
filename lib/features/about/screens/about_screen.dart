import 'package:flutter/material.dart';
import 'package:calvinchesstrainer/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../core/services/feedback_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/ui/logo_mark.dart';

class AboutScreen extends ConsumerStatefulWidget {
  const AboutScreen({super.key});

  @override
  ConsumerState<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends ConsumerState<AboutScreen> {
  final _feedbackController = TextEditingController();
  bool _isSending = false;
  bool _sent = false;

  /// The real app version from the platform (pubspec's `version:` at build
  /// time). Null until it loads, and the line stays hidden if it never does.
  String? _version;

  /// Feedback travels in the request's query string, so keep it well under
  /// common server URL limits.
  static const _maxFeedbackLength = 500;

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform()
        .then((info) {
          if (mounted) setState(() => _version = info.version);
        })
        .catchError((Object e) {
          debugPrint('App version unavailable: $e');
        });
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  Future<void> _submitFeedback(AppLocalizations l10n) async {
    final message = _feedbackController.text.trim();
    if (message.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.feedbackEmpty)));
      return;
    }

    setState(() => _isSending = true);

    final success = await ref
        .read(feedbackServiceProvider)
        .sendFeedback(message);

    if (!mounted) return;
    setState(() => _isSending = false);

    if (success) {
      _feedbackController.clear();
      setState(() => _sent = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.feedbackThanks),
          backgroundColor: AppColors.correctGreen,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.feedbackError),
          backgroundColor: AppColors.incorrectRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.about)),
      body: Center(
        child: ConstrainedBox(
          // Readable line lengths on an iPad.
          constraints: const BoxConstraints(maxWidth: 640),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              children: [
                const SizedBox(height: 16),
                const LogoMark(size: 88),
                const SizedBox(height: 20),
                Text(
                  l10n.appTitle,
                  style: AppText.display.copyWith(fontSize: 30),
                  textAlign: TextAlign.center,
                ),
                if (_version != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    l10n.aboutVersion(_version!),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.brandSoft,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    l10n.aboutByInternut,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                _buildSection(
                  context,
                  icon: Icons.school_rounded,
                  title: l10n.aboutWhatIs,
                  body: l10n.aboutWhatIsBody,
                ),
                const SizedBox(height: 16),
                _buildSection(
                  context,
                  icon: Icons.sports_esports_rounded,
                  title: l10n.aboutTrainingModes,
                  body: l10n.aboutTrainingModesBody,
                ),
                const SizedBox(height: 16),
                _buildSection(
                  context,
                  icon: Icons.favorite_rounded,
                  title: l10n.aboutCredits,
                  body: l10n.aboutCreditsBody,
                ),
                const SizedBox(height: 16),
                _buildSection(
                  context,
                  icon: Icons.menu_book_rounded,
                  title: l10n.aboutInspired,
                  body: l10n.aboutInspiredBody,
                ),
                const SizedBox(height: 16),
                _buildSection(
                  context,
                  icon: Icons.info_outline_rounded,
                  title: l10n.aboutInternut,
                  body: l10n.aboutInternutBody,
                ),
                const SizedBox(height: 24),
                _buildFeedbackSection(context, l10n),
                const SizedBox(height: 32),
                Text(
                  l10n.aboutFooter,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeedbackSection(BuildContext context, AppLocalizations l10n) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.chat_bubble_outline_rounded,
                color: AppColors.primary,
                size: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  l10n.feedbackTitle,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            l10n.feedbackBody,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          if (_sent)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: AppColors.correctGreen.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.correctGreen,
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.feedbackThanks,
                    style: TextStyle(
                      color: AppColors.correctGreen,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => setState(() => _sent = false),
                    child: Text(l10n.feedbackSend),
                  ),
                ],
              ),
            )
          else ...[
            TextField(
              controller: _feedbackController,
              maxLines: 4,
              maxLength: _maxFeedbackLength,
              enabled: !_isSending,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: l10n.feedbackHint,
                hintStyle: AppText.caption,
                fillColor: AppColors.ground,
                contentPadding: const EdgeInsets.all(14),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _isSending ? null : () => _submitFeedback(l10n),
                icon: _isSending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send_rounded, size: 18),
                label: Text(
                  _isSending ? l10n.feedbackSending : l10n.feedbackSend,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String body,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            body,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
