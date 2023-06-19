import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// External Packages
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:thunder/core/singletons/database.dart';

// Internal Packages
import 'package:thunder/routes.dart';
import 'package:thunder/thunder/bloc/thunder_bloc.dart';
import 'package:thunder/core/auth/bloc/auth_bloc.dart';

// Ignore specific exceptions to send to Sentry
FutureOr<SentryEvent?> beforeSend(SentryEvent event, {Hint? hint}) async {
  if (event.exceptions != null &&
      event.exceptions!.isNotEmpty &&
      event.exceptions!.first.value != null &&
      event.exceptions!.first.value!.contains('The request returned an invalid status code of 400.')) {
    return null;
  }

  return event;
}

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // Load up environment variables
  await dotenv.load(fileName: ".env");

  await DB.instance.database;

  String? sentryDSN = dotenv.env['SENTRY_DSN'];

  if (sentryDSN != null) {
    await SentryFlutter.init(
      (options) {
        options.dsn = kDebugMode ? '' : sentryDSN;
        options.debug = kDebugMode;
        options.tracesSampleRate = 0.7;
        options.beforeSend = beforeSend;
      },
      appRunner: () => runApp(const ThunderApp()),
    );
  } else {
    runApp(const ThunderApp());
  }
}

class ThunderApp extends StatelessWidget {
  const ThunderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => ThunderBloc()),
        BlocProvider(create: (context) => AuthBloc()),
      ],
      child: BlocBuilder<ThunderBloc, ThunderState>(
        builder: (context, state) {
          switch (state.status) {
            case ThunderStatus.initial:
              context.read<ThunderBloc>().add(InitializeAppEvent());
              FlutterNativeSplash.remove();
              return const Material(color: Color.fromRGBO(33, 33, 35, 1), child: Center(child: CircularProgressIndicator()));
            case ThunderStatus.loading:
            case ThunderStatus.success:
              return OverlaySupport.global(
                child: MaterialApp.router(
                  title: 'Thunder',
                  routerConfig: router,
                  themeMode: state.useDarkTheme ? ThemeMode.dark : ThemeMode.light,
                  theme: ThemeData(useMaterial3: true),
                  darkTheme: ThemeData.dark(useMaterial3: true),
                  debugShowCheckedModeBanner: false,
                ),
              );
            case ThunderStatus.failure:
              return const Material(
                color: Color.fromRGBO(33, 33, 35, 1),
                child: Center(
                  child: Text('An unexpected error occurred', style: TextStyle(color: Colors.white)),
                ),
              );
          }
        },
      ),
    );
  }
}
