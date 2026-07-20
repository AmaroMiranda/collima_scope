import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:collima_scope/app/providers.dart';
import 'package:collima_scope/features/adapter_profile/domain/adapter_profile.dart';
import 'package:collima_scope/features/collimation/application/collimation_controller.dart';
import 'package:collima_scope/features/history/domain/collimation_session.dart';
import 'package:collima_scope/features/telescope_profile/domain/telescope_profile.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  late TelescopeProfile telescope;

  setUp(() {
    telescope = TelescopeProfile(
      id: 't1',
      name: 'Meu Newtoniano',
      type: TelescopeType.newtonian,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );
  });

  // Teste 10 (spec §23): ao usar sem adaptador cadastrado, o app informa
  // que está em modo referência visual.
  test('sessão sem adaptador fica em modo referência visual', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container
        .read(collimationControllerProvider.notifier)
        .startSession(telescope: telescope);

    final state = container.read(collimationControllerProvider);
    expect(state.mode, CollimationMode.visualReference);
  });

  test('sessão com adaptador validado fica em modo adaptador calibrado', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final adapter = AdapterProfile(
      id: 'a1',
      name: 'Adaptador 3D',
      validatedAt: DateTime(2026),
    );

    container.read(collimationControllerProvider.notifier).startSession(
          telescope: telescope,
          adapter: adapter,
        );

    final state = container.read(collimationControllerProvider);
    expect(state.mode, CollimationMode.adapterCalibrated);
  });

  test('sessão com adaptador não validado fica em modo manual assistido', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final adapter = AdapterProfile(id: 'a1', name: 'Adaptador genérico');

    container.read(collimationControllerProvider.notifier).startSession(
          telescope: telescope,
          adapter: adapter,
        );

    final state = container.read(collimationControllerProvider);
    expect(state.mode, CollimationMode.manualAssisted);
  });

  // Menos decisões repetidas para quem já configurou tudo: a tela de nova
  // sessão pré-marca o equipamento e o modo (avançado ou não) da última vez.
  test('startSession memoriza telescópio, adaptador e modo avançado',
      () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final adapter = AdapterProfile(id: 'a1', name: 'Adaptador genérico');

    container.read(collimationControllerProvider.notifier).startSession(
          telescope: telescope,
          adapter: adapter,
          advancedMode: true,
        );
    await Future<void>.delayed(Duration.zero);

    final prefs = container.read(appPrefsProvider);
    expect(await prefs.getLastTelescopeId(), 't1');
    expect(await prefs.getLastAdapterId(), 'a1');
    expect(await prefs.getPreferAdvancedMode(), isTrue);
  });

  test('startSession sem adaptador memoriza ausência de adaptador', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container
        .read(collimationControllerProvider.notifier)
        .startSession(telescope: telescope);
    await Future<void>.delayed(Duration.zero);

    final prefs = container.read(appPrefsProvider);
    expect(await prefs.getLastTelescopeId(), 't1');
    expect(await prefs.getLastAdapterId(), isNull);
    expect(await prefs.getPreferAdvancedMode(), isFalse);
  });
}
