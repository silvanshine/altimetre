import 'package:altimetre/data/settings_repository.dart';
import 'package:altimetre/domain/models/units.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'settings_state.dart';

class SettingsCubit extends Cubit<SettingsState> {
  final SettingsRepository _settingsRepository;

  SettingsCubit({
    SettingsRepository? settingsRepository,
  })  : _settingsRepository = settingsRepository ?? SettingsRepository(),
        super(SettingsState()) {
    _init();
  }

  Future<void> loadSettings() async {
    print('Loading settings...');

    final temperature = await _settingsRepository.getTemperatureUnit();
    final pressure = await _settingsRepository.getPressureUnit();
    final distance = await _settingsRepository.getDistanceUnit();

    print(
        'Loaded settings: temperature=$temperature, pressure=$pressure, distance=$distance');

    emit(
      SettingsState(
        temperature: temperature,
        pressure: pressure,
        distance: distance,
      ),
    );
  }

  @override
  void onChange(Change<SettingsState> change) {
    super.onChange(change);
    print('Settings state changed: $change');
  }

  Future<void> updateTemperatureUnit(TemperatureUnit unit) async {
    await _settingsRepository.setTemperatureUnit(unit);
    emit(state.copyWith(temperature: unit));
  }

  Future<void> updatePressureUnit(PressureUnit unit) async {
    await _settingsRepository.setPressureUnit(unit);
    emit(state.copyWith(pressure: unit));
  }

  Future<void> updateDistanceUnit(DistanceUnit unit) async {
    await _settingsRepository.setDistanceUnit(unit);
    emit(state.copyWith(distance: unit));
  }

  void _init() async {
    await loadSettings();
  }
}
