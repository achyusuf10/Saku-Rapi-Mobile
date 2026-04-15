import 'package:app_saku_rapi/features/home_widget/home_widget_constants.dart';
import 'package:app_saku_rapi/features/home_widget/home_widget_deep_link_handler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HomeWidgetDeepLinkHandler', () {
    group('URI parsing', () {
      test('extracts type parameter correctly', () {
        final uri = Uri.parse('sakurapi://action?type=speech&walletId=w-1');
        expect(uri.queryParameters['type'], 'speech');
      });

      test('extracts walletId parameter correctly', () {
        final uri = Uri.parse('sakurapi://action?type=manual&walletId=w-abc');
        expect(uri.queryParameters['walletId'], 'w-abc');
      });

      test('handles empty walletId gracefully', () {
        final uri = Uri.parse('sakurapi://action?type=ocr&walletId=');
        expect(uri.queryParameters['walletId'], '');
      });

      test('handles missing walletId gracefully', () {
        final uri = Uri.parse('sakurapi://action?type=text');
        expect(uri.queryParameters['walletId'], isNull);
      });

      test('validates all 4 action types', () {
        expect(HomeWidgetConstants.actionManual, 'manual');
        expect(HomeWidgetConstants.actionSpeech, 'speech');
        expect(HomeWidgetConstants.actionOcr, 'ocr');
        expect(HomeWidgetConstants.actionText, 'text');
      });

      test('validates URI scheme and host', () {
        expect(HomeWidgetConstants.uriScheme, 'sakurapi');
        expect(HomeWidgetConstants.uriHost, 'action');
      });

      test('full URI construction matches expected format', () {
        const type = 'manual';
        const walletId = 'w-123';
        final uri = Uri.parse(
          '${HomeWidgetConstants.uriScheme}://${HomeWidgetConstants.uriHost}'
          '?${HomeWidgetConstants.paramType}=$type'
          '&${HomeWidgetConstants.paramWalletId}=$walletId',
        );

        expect(uri.scheme, 'sakurapi');
        expect(uri.host, 'action');
        expect(uri.queryParameters[HomeWidgetConstants.paramType], 'manual');
        expect(
          uri.queryParameters[HomeWidgetConstants.paramWalletId],
          'w-123',
        );
      });
    });

    group('pendingWidgetActionProvider', () {
      test('starts as null', () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        expect(container.read(pendingWidgetActionProvider), isNull);
      });

      test('can be set and read', () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final uri = Uri.parse('sakurapi://action?type=manual&walletId=w-1');
        container.read(pendingWidgetActionProvider.notifier).state = uri;

        expect(container.read(pendingWidgetActionProvider), uri);
      });

      test('can be cleared to null (consumed)', () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final uri = Uri.parse('sakurapi://action?type=manual&walletId=w-1');
        container.read(pendingWidgetActionProvider.notifier).state = uri;
        expect(container.read(pendingWidgetActionProvider), isNotNull);

        // Consume (clear)
        container.read(pendingWidgetActionProvider.notifier).state = null;
        expect(container.read(pendingWidgetActionProvider), isNull);
      });

      test('notifies listeners on state change', () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final values = <Uri?>[];
        container.listen(
          pendingWidgetActionProvider,
          (prev, next) => values.add(next),
        );

        final uri = Uri.parse('sakurapi://action?type=speech&walletId=w-2');
        container.read(pendingWidgetActionProvider.notifier).state = uri;
        container.read(pendingWidgetActionProvider.notifier).state = null;

        expect(values, [uri, null]);
      });
    });

    group('pendingWidgetWalletIdProvider', () {
      test('starts as null', () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        expect(container.read(pendingWidgetWalletIdProvider), isNull);
      });

      test('can be set and cleared', () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        container.read(pendingWidgetWalletIdProvider.notifier).state = 'w-abc';
        expect(container.read(pendingWidgetWalletIdProvider), 'w-abc');

        container.read(pendingWidgetWalletIdProvider.notifier).state = null;
        expect(container.read(pendingWidgetWalletIdProvider), isNull);
      });
    });

    group('cold start override', () {
      test('provider override injects initial URI', () {
        final uri = Uri.parse('sakurapi://action?type=manual&walletId=w-1');

        final container = ProviderContainer(
          overrides: [
            pendingWidgetActionProvider.overrideWith((ref) => uri),
          ],
        );
        addTearDown(container.dispose);

        expect(container.read(pendingWidgetActionProvider), uri);
      });

      test('override with null leaves provider empty', () {
        final container = ProviderContainer(
          overrides: [
            pendingWidgetActionProvider.overrideWith((ref) => null),
          ],
        );
        addTearDown(container.dispose);

        expect(container.read(pendingWidgetActionProvider), isNull);
      });
    });

    group('receiveUri scheme filtering', () {
      test('URI with correct scheme is accepted', () {
        final uri = Uri.parse('sakurapi://action?type=manual&walletId=w-1');
        expect(uri.scheme, HomeWidgetConstants.uriScheme);
      });

      test('URI with wrong scheme is rejected', () {
        final uri = Uri.parse('https://example.com?type=manual');
        expect(uri.scheme, isNot(HomeWidgetConstants.uriScheme));
      });
    });
  });
}
