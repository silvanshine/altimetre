import 'dart:async';

import 'package:altimetre/data/barometer_repository.dart';
import 'package:altimetre/domain/blocs/barometer_cubit.dart';
import 'package:altimetre/domain/blocs/settings_cubit.dart';
import 'package:altimetre/presentation/home_page/widgets/gauge.dart';
import 'package:altimetre/presentation/paddings.dart';
import 'package:altimetre/presentation/settings_page/settings_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../../domain/models/units.dart';
import '../../utils/convert.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  double _pressure = 0.0;
  StreamSubscription<BarometerEvent>? _subscription;

  @override
  void initState() {
    _subscription = barometerEventStream().listen((event) {
      setState(() {
        _pressure = event.pressure;
      });
    });
    super.initState();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => BarometerCubit(
              barometerRepository: context.read<BarometerRepository>())
            ..listenUpdates(),
        ),
      ],
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Voluptuaria'),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () async {
                final settingsUpdated = await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => BlocProvider.value(
                      value: context.read<SettingsCubit>(),
                      child: const SettingsPage(),
                    ),
                  ),
                );

                if (settingsUpdated == true) {
                  // Reload settings explicitly (optional, as changes should propagate automatically)
                  context.read<SettingsCubit>().loadSettings();
                }
              },
            ),
          ],
        ),
        body: Center(
          child: BlocBuilder<SettingsCubit, SettingsState>(
            builder: (context, settingsState) {
              // Handle Barometer state inside this builder
              return BlocBuilder<BarometerCubit, BarometerState>(
                builder: (context, barometerState) {
                  double pressure = barometerState.pressure ?? 0.0;
                  if (settingsState.pressure == PressureUnit.inHg) {
                    pressure = hPaToInHg(pressure);
                  }

                  double temperature = barometerState.temperature ?? 0.0;
                  if (settingsState.temperature == TemperatureUnit.fahrenheit) {
                    temperature = celsiusToFahrenheit(temperature);
                  }

                  double elevation = barometerState.elevation ?? 0.0;
                  double gpsElevation = barometerState.gpsElevation ?? 0.0;

                  if (settingsState.distance == DistanceUnit.feet) {
                    elevation = metersToFeet(elevation);
                    gpsElevation = metersToFeet(gpsElevation);
                  }

                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      if (barometerState.pressure != null)
                        Gauge(value: barometerState.pressure!),
                      Text(
                        '${pressure.toStringAsFixed(0)} ${settingsState.pressure == PressureUnit.hPa ? 'hPa' : 'inHg'}',
                        style: textTheme.displayMedium,
                      ),
                      Text(
                        'Temperature: ${temperature.toStringAsFixed(0)}${settingsState.temperature == TemperatureUnit.celsius ? '°C' : '°F'}',
                        style: textTheme.displaySmall,
                      ),
                      const SizedBox(width: Paddings.large),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            'Measured: ${elevation.toStringAsFixed(0)} ${settingsState.distance == DistanceUnit.meters ? 'm' : 'ft'}',
                            style: textTheme.bodyLarge,
                          ),
                          const SizedBox(width: Paddings.large),
                          Text(
                            'GPS: ${gpsElevation.toStringAsFixed(0)} ${settingsState.distance == DistanceUnit.meters ? 'm' : 'ft'}',
                            style: textTheme.bodyLarge,
                          ),
                        ],
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
