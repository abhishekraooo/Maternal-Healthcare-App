import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:maternalhealthcare/patient_side/auth/authwrapper.dart';
import 'package:maternalhealthcare/utils/role_selection.dart';
import 'package:maternalhealthcare/config/firebase_options.dart';
import 'package:maternalhealthcare/doctor_side/provider/doctor_provider.dart';
import 'package:maternalhealthcare/patient_side/provider/patient_provider.dart';
import 'package:maternalhealthcare/patient_side/provider/profile_provider.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  /// Loads environment variables from the .env file.
  try {
    await dotenv.load(fileName: ".env");
    debugPrint("Environment variables loaded successfully.");
  } catch (e) {
    debugPrint("Error loading .env file: $e");
  }

  /// Initializes the Firebase service.
  try {
    final options = DefaultFirebaseOptions.currentPlatform;
    await Firebase.initializeApp(options: options);
    debugPrint("Firebase initialized successfully.");
  } catch (e, stacktrace) {
    debugPrint("Firebase initialization error: $e");
    debugPrint("Stacktrace: $stacktrace");
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  /// Defines the primary application color palette.
  static const Color appPrimary = Color(0xFF007069);
  static const Color appSecondary = Color(0xFFC5D4E5);
  static const Color appBackground = Color(0xFFFFFFFF);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PatientDataProvider()),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
        ChangeNotifierProvider(create: (_) => DoctorDataProvider()),
      ],
      child: MaterialApp(
        title: 'Maternal Healthcare App',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          /// Applies the global background color.
          scaffoldBackgroundColor: appBackground,

          /// Configures the global color scheme.
          colorScheme: const ColorScheme.light(
            primary: appPrimary,
            secondary: appSecondary,
            surface: appBackground,
          ),

          /// Applies the 'Inter' font family globally, utilizing ThemeData.light().textTheme for safe context access.
          textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme),

          /// Configures the global card theme.
          cardTheme: CardThemeData(
            color: appBackground,
            elevation: 2,
            shadowColor: appSecondary.withOpacity(0.5),

            /// Provides a subtle thematic shadow.
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),

          /// Configures the global elevated button theme.
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: appPrimary,
              foregroundColor: appBackground,

              /// Determines the text and icon color.
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),

          /// Configures the global application bar theme.
          appBarTheme: const AppBarTheme(
            backgroundColor: appBackground,
            foregroundColor: appPrimary,

            /// Determines the text and icon color for the AppBar.
            elevation: 0,
            centerTitle: true,
          ),
        ),
        home: const AuthWrapper(),
      ),
    );
  }
}
