import 'package:fluship/shared/models/distribution/distribution_config.dart';
import 'package:fluship/features/config/bloc/config_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WhatsAppConfig', () {
    test('can send only with both a key and a connected chat', () {
      const ready = WhatsAppConfig(apiKey: 'key', recipientId: 'user:1');

      expect(ready.canSend, isTrue);
      expect(ready.isConnected, isTrue);
      expect(const WhatsAppConfig(apiKey: 'key').canSend, isFalse);
      expect(const WhatsAppConfig(recipientId: 'user:1').canSend, isFalse);
      expect(
        const WhatsAppConfig(apiKey: '  ', recipientId: 'user:1').canSend,
        isFalse,
      );
    });

    test('copyWith can drop the chat id and the key', () {
      const ready = WhatsAppConfig(
        recipientId: 'user:1',
        apiKey: 'key',
        enabled: true,
      );

      final rekeyed = ready.copyWith(apiKey: 'other', clearRecipient: true);
      expect(rekeyed.apiKey, 'other');
      expect(rekeyed.recipientId, isNull);
      expect(rekeyed.enabled, isTrue);

      final cleared = ready.copyWith(clearApiKey: true, clearRecipient: true);
      expect(cleared.apiKey, isNull);
      expect(cleared.canSend, isFalse);
    });

    test('survives a round trip through JSON', () {
      const config = WhatsAppConfig(
        recipientId: 'user:50972923564215',
        apiKey: 'key',
        enabled: true,
      );

      expect(WhatsAppConfig.fromJson(config.toJson()), config);
      expect(WhatsAppConfig.fromJson(null), const WhatsAppConfig());
      expect(WhatsAppConfig.fromJson(const {}), const WhatsAppConfig());
    });
  });

  group('DistributionConfigModel', () {
    test('keeps the WhatsApp section through JSON', () {
      const model = DistributionConfigModel(
        whatsappConfig: WhatsAppConfig(
          recipientId: 'user:1',
          apiKey: 'key',
          enabled: true,
        ),
      );

      final restored = DistributionConfigModel.fromJson(model.toJson());

      expect(restored.whatsappConfig, model.whatsappConfig);
      expect(restored.canSendToWhatsApp, isTrue);
    });

    test('loads a profile saved before WhatsApp existed', () {
      final json = ConfigState.empty().toJson();
      (json['distribution'] as Map<String, dynamic>).remove('whatsappConfig');

      final restored = ConfigState.fromJson(json);

      expect(restored.distribution.whatsappConfig, isNull);
      expect(restored.distribution.canSendToWhatsApp, isFalse);
    });

    test('copyWith leaves the WhatsApp section alone unless given one', () {
      const whatsapp = WhatsAppConfig(apiKey: 'key');
      const model = DistributionConfigModel(whatsappConfig: whatsapp);

      expect(model.copyWith(releaseNotes: 'notes').whatsappConfig, whatsapp);
      expect(
        model
            .copyWith(whatsappConfig: whatsapp.copyWith(enabled: true))
            .whatsappConfig
            ?.enabled,
        isTrue,
      );
    });
  });
}
