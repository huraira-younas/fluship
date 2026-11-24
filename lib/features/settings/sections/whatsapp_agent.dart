import 'package:fluship/shared/models/distribution/distribution_config.dart';
import 'package:fluship/core/app_theme/fluship_theme_extension.dart';
import 'package:fluship/services/distribution/distribution.dart';
import 'package:fluship/features/config/bloc/config_bloc.dart';
import 'package:fluship/shared/widgets/app_text_field.dart';
import 'package:fluship/shared/widgets/app_button.dart';
import 'package:fluship/shared/widgets/app_toast.dart';
import 'package:fluship/shared/widgets/app_card.dart';
import 'package:fluship/shared/widgets/app_text.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluship/di/locator.dart';
import 'package:material_ui/material_ui.dart';

class const WhatsAppAgent({super.key}) extends StatefulWidget {
  @override
  State<WhatsAppAgent> createState() => _WhatsAppAgentState();
}

class _WhatsAppAgentState extends State<WhatsAppAgent> {
  static const _testMessage =
      'Fluship is connected. Build summaries will arrive in this chat.';

  var _connecting = false;
  var _testing = false;

  WhatsAppConfig get _current =>
      getIt<ConfigBloc>().state.distribution.whatsappConfig ??
      const WhatsAppConfig();

  void _update(WhatsAppConfig config) {
    final bloc = getIt<ConfigBloc>();

    bloc.add(
      UpdateConfig(
        config: bloc.state.distribution.copyWith(whatsappConfig: config),
        onError: (error) => AppToast.error(error.message),
      ),
    );
  }

  void _onKeyChanged(String value) {
    final current = _current;
    final key = value.trim();
    if (key == (current.apiKey ?? '')) return;

    // The chat id was read with the old key, so it has to be found again.
    _update(
      key.isEmpty
          ? current.copyWith(clearApiKey: true, clearRecipient: true)
          : current.copyWith(apiKey: key, clearRecipient: true),
    );
  }

  Future<void> _connect() async {
    final key = _current.apiKey?.trim() ?? '';
    if (key.isEmpty || _connecting) return;

    setState(() => _connecting = true);
    try {
      final id = await getIt<WhatsAppClient>().findCreatorId(token: key);
      if (id == null) {
        AppToast.warning(
          'No message found yet. Send any message to your agent in WhatsApp, '
          'then press Connect again.',
        );
        return;
      }

      _update(_current.copyWith(recipientId: id));
      AppToast.success('WhatsApp agent connected.');
    } catch (error) {
      AppToast.error('$error');
    } finally {
      if (mounted) setState(() => _connecting = false);
    }
  }

  Future<void> _sendTest() async {
    final config = _current;
    if (!config.canSend || _testing) return;

    setState(() => _testing = true);
    try {
      await getIt<WhatsAppClient>().sendText(
        token: config.apiKey!.trim(),
        to: config.recipientId!,
        body: _testMessage,
      );
      AppToast.success('Test message sent. Check your agent chat.');
    } catch (error) {
      AppToast.error('$error');
    } finally {
      if (mounted) setState(() => _testing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ft = context.flushipTheme;

    return BlocSelector<ConfigBloc, ConfigState, WhatsAppConfig>(
      selector: (s) => s.distribution.whatsappConfig ?? const WhatsAppConfig(),
      builder: (_, config) {
        final hasKey = (config.apiKey ?? '').trim().isNotEmpty;

        return AppCard(
          title: 'WhatsApp Agent',
          description:
              '• In WhatsApp open Settings → Agents → Create an agent, then the agent chat → Chat info → API key.\n'
              '• Paste the key here, send any message to the agent from your phone, then press Connect.\n'
              '• An agent can only message the account that created it, so summaries arrive in your own chat with the agent.\n'
              '• Build files are not attached (16 MB limit). The summary lists them and adds the Google Drive link.',
          spacing: 15,
          children: [
            AppTextField.label(
              initialValue: config.apiKey,
              onChanged: _onKeyChanged,
              label: 'Agent API key',
              hint: '••••••••••••••••',
              obscureText: true,
            ),
            AppText.custom(
              color: config.isConnected ? ft.colors.success : ft.colors.textDim,
              config.isConnected
                  ? 'Connected to your agent chat.'
                  : 'Not connected yet.',
              size: .caption,
            ),
            Wrap(
              runSpacing: ft.spacing.sm,
              spacing: ft.spacing.sm,
              children: [
                AppButton.primary(
                  label: config.isConnected ? 'Reconnect' : 'Connect',
                  onPressed: hasKey ? _connect : null,
                  isLoading: _connecting,
                  size: .sm,
                ),
                AppButton.outline(
                  onPressed: config.canSend ? _sendTest : null,
                  label: 'Send test message',
                  isLoading: _testing,
                  size: .sm,
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
