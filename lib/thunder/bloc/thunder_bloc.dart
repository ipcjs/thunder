import 'dart:convert';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:json_theme/json_theme.dart';
import 'package:path/path.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:stream_transform/stream_transform.dart';

import 'package:thunder/core/enums/theme_type.dart';
import 'package:thunder/core/models/version.dart';
import 'package:thunder/core/update/check_github_update.dart';

part 'thunder_event.dart';
part 'thunder_state.dart';

const throttleDuration = Duration(milliseconds: 300);

EventTransformer<E> throttleDroppable<E>(Duration duration) {
  return (events, mapper) => droppable<E>().call(events.throttle(duration), mapper);
}

class ThunderBloc extends Bloc<ThunderEvent, ThunderState> {
  ThunderBloc() : super(const ThunderState()) {
    on<InitializeAppEvent>(
      _initializeAppEvent,
      transformer: throttleDroppable(throttleDuration),
    );
    on<UserPreferencesChangeEvent>(
      _userPreferencesChangeEvent,
      transformer: throttleDroppable(throttleDuration),
    );
    on<ThemeChangeEvent>(
      _themeChangeEvent,
      transformer: throttleDroppable(throttleDuration),
    );
  }

  Future<void> _initializeAppEvent(InitializeAppEvent event, Emitter<ThunderState> emit) async {
    try {
      // Load up database
      final database = await openDatabase(
        join(await getDatabasesPath(), 'thunder.db'),
        version: 1,
      );

      // Check for any updates from GitHub
      Version version = await fetchVersion();

      // Get theme preferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String themeType = prefs.getString('setting_theme_type') ?? 'dark';

      bool useDarkTheme = themeType == 'dark';

      emit(state.copyWith(status: ThunderStatus.success, database: database, version: version, useDarkTheme: useDarkTheme));
      // add(const ThemeChangeEvent(themeType: ThemeType.black));
    } catch (e, s) {
      await Sentry.captureException(e, stackTrace: s);
    }
  }

  Future<void> _themeChangeEvent(ThemeChangeEvent event, Emitter<ThunderState> emit) async {
    try {
      emit(state.copyWith(status: ThunderStatus.loading));

      SharedPreferences prefs = await SharedPreferences.getInstance();
      String themeType = prefs.getString('setting_theme_type') ?? 'dark';

      if (themeType == 'dark') {
        return emit(state.copyWith(status: ThunderStatus.success, useDarkTheme: true, preferences: prefs));
      } else {
        return emit(state.copyWith(status: ThunderStatus.success, useDarkTheme: false, preferences: prefs));
      }
    } catch (e, s) {
      await Sentry.captureException(e, stackTrace: s);

      emit(state.copyWith(status: ThunderStatus.failure));
    }
  }

  // Future<void> _themeChangeEvent(ThemeChangeEvent event, Emitter<ThunderState> emit) async {
  //   try {
  //     emit(state.copyWith(status: ThunderStatus.loading));

  //     // @todo keep user preferences for theming
  //     SharedPreferences prefs = await SharedPreferences.getInstance();

  //     String themeName = 'assets/themes/black.json';

  //     switch (event.themeType) {
  //       case ThemeType.black:
  //         themeName = 'assets/themes/black.json';
  //       case ThemeType.white:
  //         themeName = 'assets/themes/white.json';
  //     }

  //     final themeString = await rootBundle.loadString(themeName);
  //     final themeJson = jsonDecode(themeString);
  //     final theme = ThemeDecoder.decodeThemeData(themeJson)!;

  //     return emit(state.copyWith(status: ThunderStatus.success, theme: theme, preferences: prefs));
  //   } catch (e, s) {
  //     await Sentry.captureException(e, stackTrace: s);

  //     emit(state.copyWith(status: ThunderStatus.failure));
  //   }
  // }

  Future<void> _userPreferencesChangeEvent(UserPreferencesChangeEvent event, Emitter<ThunderState> emit) async {
    try {
      emit(state.copyWith(status: ThunderStatus.loading));

      SharedPreferences prefs = await SharedPreferences.getInstance();

      await Future.delayed(const Duration(seconds: 1), () {
        return emit(state.copyWith(status: ThunderStatus.success, preferences: prefs));
      });
    } catch (e, s) {
      await Sentry.captureException(e, stackTrace: s);

      emit(state.copyWith(status: ThunderStatus.failure));
    }
  }
}
