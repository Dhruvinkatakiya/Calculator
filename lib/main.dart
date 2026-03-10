import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:math_expressions/math_expressions.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import 'package:vibration/vibration.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:ui';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// Ads Control Service - Checks API to determine if ads should be shown
class AdsControlService {
  static const String apiUrl = 'https://script.googleusercontent.com/macros/echo?user_content_key=AY5xjrSZr4Zpzpefx_MUDJVJPFASXMnkkxr5J7tPTtNj38sR8mB0Fa0PqM5IXlPvqtpIyqcIJAKEPJsXtU8SJQbFQ04tt4OnKxPSaz4bAqD3n2xtxTRntIHDMA4SAcAQUsncALLDWt5PIoWYlXQaVpURpN0iDNtmiZG6Ik47Dzx424A_zer10V53SqW4I5ujhivFdRDkEDilZZZjSJzKLLbF3SXTPPr96M5KRVsE4DQTFsqm3Yq39VE40DvZthi4F8_oF7apev94chIE3Sr4XkLLHoLe7ozQCCScdIz9LLVk&lib=MH__BrZO-6yBZFmsCpXNALTBB5iDfypnN';
  static const String appName = 'Calculator';
  
  static bool? _adsEnabled;
  static DateTime? _lastFetchTime;
  static const Duration _cacheDuration = Duration(hours: 1);

  /// Fetches ads control status from API
  static Future<bool> shouldShowAds() async {
    // Return cached value if available and not expired
    if (_adsEnabled != null && _lastFetchTime != null) {
      if (DateTime.now().difference(_lastFetchTime!) < _cacheDuration) {
        debugPrint('📋 Using cached ads status: $_adsEnabled');
        return _adsEnabled!;
      }
    }

    try {
      debugPrint('🌐 Fetching ads control status from API...');
      final response = await http.get(Uri.parse(apiUrl)).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          debugPrint('⏱️ API request timeout - defaulting to show ads');
          return http.Response('timeout', 408);
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        debugPrint('✅ API Response: $data');
        
        // Check if the response is a list or a map
        if (data is List) {
          // Find Calculator app in the list
          for (var app in data) {
            if (app['App Name'] == appName) {
              final status = app['Status']?.toString().toLowerCase() ?? '';
              _adsEnabled = status == 'enable';
              _lastFetchTime = DateTime.now();
              debugPrint('🎯 Ads status for $appName: $_adsEnabled (Status: ${app['Status']})');
              return _adsEnabled!;
            }
          }
          debugPrint('⚠️ App "$appName" not found in API response - defaulting to show ads');
          _adsEnabled = true; // Default to enabled if app not found
        } else if (data is Map) {
          // If it's a single app response
          if (data['App Name'] == appName) {
            final status = data['Status']?.toString().toLowerCase() ?? '';
            _adsEnabled = status == 'enable';
            _lastFetchTime = DateTime.now();
            debugPrint('🎯 Ads status for $appName: $_adsEnabled (Status: ${data['Status']})');
            return _adsEnabled!;
          }
        }
      } else {
        debugPrint('❌ API request failed with status: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Error fetching ads control: $e');
    }

    // Default to showing ads if API fails
    _adsEnabled = true;
    _lastFetchTime = DateTime.now();
    return true;
  }

  /// Clear cache to force refresh on next check
  static void clearCache() {
    _adsEnabled = null;
    _lastFetchTime = null;
    debugPrint('🗑️ Ads control cache cleared');
  }
}

// App Open Ad Manager
class AppOpenAdManager {
  static AppOpenAd? _appOpenAd;
  static bool _isShowingAd = false;
  // Replace with your real Ad Unit ID for production
  static const String adUnitId = 'ca-app-pub-8003148820564585/7603355869'; // Test ID

  static Future<void> loadAd() async {
    if (_appOpenAd != null) return;
    
    // Check if ads should be shown
    final shouldShow = await AdsControlService.shouldShowAds();
    if (!shouldShow) {
      debugPrint('🚫 Ads are disabled by API - skipping ad load');
      return;
    }
    
    AppOpenAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          _appOpenAd = ad;
          debugPrint('✅ App Open Ad loaded');
        },
        onAdFailedToLoad: (error) {
          debugPrint('❌ App Open Ad failed to load: $error');
        },
      ),
    );
  }

  static Future<void> showAdIfAvailable() async {
    if (_isShowingAd || _appOpenAd == null) return;
    
    // Check if ads should be shown
    final shouldShow = await AdsControlService.shouldShowAds();
    if (!shouldShow) {
      debugPrint('🚫 Ads are disabled by API - skipping ad display');
      return;
    }
    
    _appOpenAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        _isShowingAd = true;
        debugPrint('📱 App Open Ad showing');
      },
      onAdDismissedFullScreenContent: (ad) {
        _isShowingAd = false;
        _appOpenAd = null;
        ad.dispose();
        loadAd(); // Preload next ad
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('❌ App Open Ad failed to show: $error');
        _isShowingAd = false;
        _appOpenAd = null;
        ad.dispose();
        loadAd();
      },
    );
    _appOpenAd!.show();
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize Mobile Ads SDK
  await MobileAds.instance.initialize();
  // Load first app open ad
  AppOpenAdManager.loadAd();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      showPerformanceOverlay: false,
      checkerboardRasterCacheImages: false,
      checkerboardOffscreenLayers: false,
      showSemanticsDebugger: false,
      title: 'Advanced Calculator',
      darkTheme: ThemeData.dark().copyWith(
        colorScheme: const ColorScheme.dark(
          primary: Colors.blue,
          secondary: Colors.blueAccent,
        ),
      ),
      themeMode: ThemeMode.dark,
      home: const Calculator(),
    );
  }
}

class Calculator extends StatefulWidget {
  const Calculator({super.key});

  @override
  _CalculatorState createState() => _CalculatorState();
}

class _CalculatorState extends State<Calculator> with WidgetsBindingObserver {
  String selectedLanguage = 'English';
  String currentTtsLanguage = 'en-US';
  bool isSoundEnabled = true;
  bool isHapticEnabled = true;
  bool isScientificMode = false;
  bool isTtsReady = false;
  String input = "";
  String output = "0";
  List<String> historyList = [];
  double memoryValue = 0;
  bool hasMemory = false;
  FlutterTts flutterTts = FlutterTts();

  // Supported languages
  final List<String> languages = [
    'English',
    'Gujarati',
    'Hindi',
    'Marathi',
    'Bengali',
    'Tamil',
  ];

  // Language to TTS locale mapping
  final Map<String, String> languageLocales = {
    'English': 'en-US',
    'Gujarati': 'gu-IN',
    'Hindi': 'hi-IN',
    'Marathi': 'mr-IN',
    'Bengali': 'bn-IN',
    'Tamil': 'ta-IN',
  };

  // Number mappings for each language
  final Map<String, Map<String, String>> numberMappings = {
    'English': {
      "0": "0",
      "1": "1",
      "2": "2",
      "3": "3",
      "4": "4",
      "5": "5",
      "6": "6",
      "7": "7",
      "8": "8",
      "9": "9"
    },
    'Gujarati': {
      "0": "૦",
      "1": "૧",
      "2": "૨",
      "3": "૩",
      "4": "૪",
      "5": "૫",
      "6": "૬",
      "7": "૭",
      "8": "૮",
      "9": "૯"
    },
    'Hindi': {
      "0": "०",
      "1": "१",
      "2": "२",
      "3": "३",
      "4": "४",
      "5": "५",
      "6": "६",
      "7": "७",
      "8": "८",
      "9": "९"
    },
    'Marathi': {
      "0": "०",
      "1": "१",
      "2": "२",
      "3": "३",
      "4": "४",
      "5": "५",
      "6": "६",
      "7": "७",
      "8": "८",
      "9": "९"
    },
    'Bengali': {
      "0": "০",
      "1": "১",
      "2": "২",
      "3": "৩",
      "4": "৪",
      "5": "৫",
      "6": "৬",
      "7": "৭",
      "8": "৮",
      "9": "৯"
    },
    'Tamil': {
      "0": "0",
      "1": "1",
      "2": "2",
      "3": "3",
      "4": "4",
      "5": "5",
      "6": "6",
      "7": "7",
      "8": "8",
      "9": "9"
    },
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    initTts();
    _loadHistory();
    _loadLanguage();
    _loadSoundPreference();
    // Show ad on app start
    Future.delayed(const Duration(milliseconds: 500), () {
      AppOpenAdManager.showAdIfAvailable();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Show ad when app comes back to foreground
      AppOpenAdManager.showAdIfAvailable();
    }
  }

  Future<void> initTts() async {
    try {
      print('🎤 Initializing TTS...');

      // Set handlers
      flutterTts.setStartHandler(() {
        print('🔊 TTS Started');
      });

      flutterTts.setCompletionHandler(() {
        print('✅ TTS Completed');
      });

      flutterTts.setErrorHandler((msg) {
        print('❌ TTS Error: $msg');
      });

      flutterTts.setInitHandler(() {
        print('🎯 TTS Engine Connected and Ready');
        isTtsReady = true;
      });

      // Basic configuration
      await flutterTts.setLanguage('en-US');
      await flutterTts.setSpeechRate(0.5);
      await flutterTts.setVolume(1.0);
      await flutterTts.setPitch(1.0);

      // Platform specific settings for Android
      if (Platform.isAndroid) {
        await flutterTts.setSharedInstance(true);
      }

      await flutterTts.awaitSpeakCompletion(false);

      // Wait for engine to fully bind (Android emulator needs more time)
      print('⏳ Waiting for TTS engine to bind...');
      for (int i = 0; i < 6; i++) {
        await Future.delayed(const Duration(milliseconds: 500));
        if (isTtsReady) {
          print('✅ TTS Engine bound via initHandler');
          break;
        }
        print('⏳ Still waiting... (${i + 1}/6)');
      }

      // Force ready after timeout
      if (!isTtsReady) {
        print('⚠️ InitHandler not called, forcing ready state');
        isTtsReady = true;
      }

      // Set initial language
      await flutterTts.setLanguage('en-US');
      currentTtsLanguage = 'en-US';

      // Wait longer for engine to stabilize (no test speak to avoid DeadObject)
      print('⏳ Waiting for TTS engine to stabilize...');
      await Future.delayed(const Duration(milliseconds: 2000));

      // Check available languages
      var languages = await flutterTts.getLanguages;
      print('📋 Available TTS languages: ${languages?.length ?? 0}');
      if (languages != null && languages.isNotEmpty) {
        print('📋 First 10 languages: ${languages.take(10).join(", ")}');
        // Check if Gujarati is available
        bool hasGujarati = languages.any((l) => l.toString().contains('gu'));
        print(hasGujarati
            ? '✅ Gujarati (gu) is available'
            : '⚠️ Gujarati (gu) NOT available');
      }

      print('✅ TTS Initialized and Ready');
    } catch (e) {
      print('❌ TTS initialization failed: $e');
      isTtsReady = false;
    }
  }

  Future<void> testTts() async {
    try {
      await flutterTts.setLanguage('en-US');
      await flutterTts.setSpeechRate(0.5);
      await flutterTts.setVolume(1.0);
      await flutterTts.setPitch(1.0);
      await flutterTts.speak('Sound is now enabled');
    } catch (e) {
      // TTS test failed
    }
  }

  Future<void> _loadSoundPreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isSoundEnabled = prefs.getBool('isSoundEnabled') ?? true;
    });
  }

  Future<void> _saveSoundPreference() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isSoundEnabled', isSoundEnabled);
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      historyList = prefs.getStringList('history') ?? [];
    });
  }

  Future<void> _saveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('history', historyList);
  }

  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      selectedLanguage = prefs.getString('selectedLanguage') ?? 'English';
    });
  }

  Future<void> _saveLanguage(String language) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedLanguage', language);
  }

  String getDisplayText(String text) {
    final mapping = numberMappings[selectedLanguage]!;
    return text.split('').map((e) => mapping[e] ?? e).join();
  }

  Future<void> _speak(String text) async {
    if (!isSoundEnabled) {
      print('🔇 Sound is disabled, skipping speech');
      return;
    }

    if (!isTtsReady) {
      print('⏳ TTS not ready yet, waiting up to 2 seconds...');
      for (int i = 0; i < 4; i++) {
        await Future.delayed(const Duration(milliseconds: 500));
        if (isTtsReady) {
          print('✅ TTS became ready');
          break;
        }
      }
      if (!isTtsReady) {
        print('⚠️ TTS still not ready after 2 seconds, aborting');
        return;
      }
    }

    print('\n🎤 _speak called with: "$text"');

    try {
      final locale = languageLocales[selectedLanguage] ?? 'en-US';

      // Only change language if different from current
      if (locale != currentTtsLanguage) {
        print('🌍 Changing TTS language from $currentTtsLanguage to: $locale');
        await flutterTts.setLanguage(locale);
        currentTtsLanguage = locale;

        // Wait for engine to rebind after language change
        print('⏳ Waiting for TTS engine to rebind after language change...');
        await Future.delayed(const Duration(milliseconds: 2000));
      } else {
        print('🌍 TTS language already set to: $locale');
      }

      print('🔊 Speaking: "$text"');
      var result = await flutterTts.speak(text);

      if (result == 1) {
        print('✅ Speech initiated successfully');
      } else {
        print('⚠️ Speech failed - result: $result');

        // Retry once after reinitializing
        print('🔄 Retrying: Reinitializing TTS...');
        isTtsReady = false;
        await initTts();

        if (isTtsReady) {
          print('🔄 Retrying speak after reinit...');
          if (locale != currentTtsLanguage) {
            await flutterTts.setLanguage(locale);
            currentTtsLanguage = locale;
            await Future.delayed(const Duration(milliseconds: 2000));
          }
          result = await flutterTts.speak(text);
          print(result == 1 ? '✅ Retry successful' : '❌ Retry failed: $result');
        }
      }
    } catch (e) {
      print('❌ TTS Error: $e');

      // Try to recover by reinitializing
      print('🔄 Attempting to reinitialize TTS after error...');
      isTtsReady = false;
      await initTts();
    }
  }

  String _numberToWords(String numStr) {
    // Convert number string to spoken words digit by digit
    // This ensures TTS speaks each digit clearly
    try {
      // Remove any formatting characters (commas, spaces)
      numStr = numStr.replaceAll(',', '').replaceAll(' ', '').trim();

      double num = double.parse(numStr);

      // For whole numbers
      if (num == num.toInt()) {
        int intNum = num.toInt();

        // Handle special cases
        if (intNum == 0) return 'zero';
        if (intNum < 0) {
          return 'minus ${_numberToWords(intNum.abs().toString())}';
        }

        // For numbers up to 9999, speak naturally
        if (intNum <= 9999) {
          return _convertUpTo9999(intNum);
        }

        // For larger numbers, speak digit by digit
        return numStr.split('').map((digit) {
          switch (digit) {
            case '0':
              return 'zero';
            case '1':
              return 'one';
            case '2':
              return 'two';
            case '3':
              return 'three';
            case '4':
              return 'four';
            case '5':
              return 'five';
            case '6':
              return 'six';
            case '7':
              return 'seven';
            case '8':
              return 'eight';
            case '9':
              return 'nine';
            default:
              return digit;
          }
        }).join(' ');
      } else {
        // For decimal numbers, speak digit by digit
        return numStr.split('').map((char) {
          if (char == '.') return 'point';
          if (char == '-') return 'minus';
          switch (char) {
            case '0':
              return 'zero';
            case '1':
              return 'one';
            case '2':
              return 'two';
            case '3':
              return 'three';
            case '4':
              return 'four';
            case '5':
              return 'five';
            case '6':
              return 'six';
            case '7':
              return 'seven';
            case '8':
              return 'eight';
            case '9':
              return 'nine';
            default:
              return char;
          }
        }).join(' ');
      }
    } catch (e) {
      return numStr;
    }
  }

  String _convertUpTo9999(int num) {
    if (num == 0) return 'zero';

    List<String> ones = [
      '',
      'one',
      'two',
      'three',
      'four',
      'five',
      'six',
      'seven',
      'eight',
      'nine'
    ];
    List<String> teens = [
      'ten',
      'eleven',
      'twelve',
      'thirteen',
      'fourteen',
      'fifteen',
      'sixteen',
      'seventeen',
      'eighteen',
      'nineteen'
    ];
    List<String> tens = [
      '',
      '',
      'twenty',
      'thirty',
      'forty',
      'fifty',
      'sixty',
      'seventy',
      'eighty',
      'ninety'
    ];

    String result = '';

    // Thousands
    if (num >= 1000) {
      result += '${ones[num ~/ 1000]} thousand';
      num %= 1000;
      if (num > 0) result += ' ';
    }

    // Hundreds
    if (num >= 100) {
      result += '${ones[num ~/ 100]} hundred';
      num %= 100;
      if (num > 0) result += ' and ';
    }

    // Tens and ones
    if (num >= 20) {
      result += tens[num ~/ 10];
      num %= 10;
      if (num > 0) result += ' ${ones[num]}';
    } else if (num >= 10) {
      result += teens[num - 10];
    } else if (num > 0) {
      result += ones[num];
    }

    return result;
  }

  Future<void> _vibrate() async {
    if (isHapticEnabled) {
      if (await Vibration.hasVibrator()) {
        Vibration.vibrate(duration: 50);
      }
    }
  }

  void buttonPressed(String buttonText) async {
    await _vibrate();

    // Don't speak every button - only speak calculation results
    // Speaking every button causes overlapping speech and poor performance

    setState(() {
      if (buttonText == "C") {
        input = "";
        output = "0";
      } else if (buttonText == "⌫") {
        input = input.length > 1 ? input.substring(0, input.length - 1) : "";
        output = input.isEmpty ? "0" : input;
      } else if (buttonText == "=") {
        _calculateResult();
        // Note: _calculateResult() will speak the answer
      } else if (buttonText == "MS") {
        // Memory Store
        if (output != "0" && output != "Error") {
          memoryValue = double.tryParse(output) ?? 0;
          hasMemory = true;
        }
      } else if (buttonText == "MR") {
        // Memory Recall
        if (hasMemory) {
          input += memoryValue.toString();
        }
      } else if (buttonText == "M+") {
        // Memory Add
        if (output != "0" && output != "Error") {
          memoryValue += double.tryParse(output) ?? 0;
          hasMemory = true;
        }
      } else if (buttonText == "M-") {
        // Memory Subtract
        if (output != "0" && output != "Error") {
          memoryValue -= double.tryParse(output) ?? 0;
          hasMemory = true;
        }
      } else if (buttonText == "MC") {
        // Memory Clear
        memoryValue = 0;
        hasMemory = false;
      } else if (buttonText == "√") {
        if (input.isNotEmpty) {
          try {
            double value = double.parse(input);
            output = math.sqrt(value).toString();
            historyList.add("√$input = $output");
            _saveHistory();
            input = output;
            // Speak result asynchronously without blocking UI
            String spokenAnswer = _numberToWords(output);
            print('🧮 Calculation result: $output');
            _speak("The answer is $spokenAnswer");
          } catch (e) {
            output = "Error";
          }
        }
      } else if (buttonText == "x²") {
        if (input.isNotEmpty) {
          try {
            double value = double.parse(input);
            output = (value * value).toString();
            historyList.add("($input)² = $output");
            _saveHistory();
            input = output;
            // Speak result asynchronously without blocking UI
            String spokenAnswer = _numberToWords(output);
            print('🧮 Calculation result: $output');
            _speak("The answer is $spokenAnswer");
          } catch (e) {
            output = "Error";
          }
        }
      } else if (buttonText == "π") {
        input += math.pi.toString();
      } else if (buttonText == "e") {
        input += math.e.toString();
      } else if (["sin", "cos", "tan", "log", "ln"].contains(buttonText)) {
        input += "$buttonText(";
      } else if (buttonText == "xⁿ") {
        input += "^";
      } else {
        input += buttonText;
      }
    });
  }

  void _calculateResult() {
    if (input.isEmpty) return;

    try {
      String expression = input
          .replaceAll('×', '*')
          .replaceAll('÷', '/')
          .replaceAll('%', '/100')
          .replaceAll('^', '^');

      // Handle scientific functions
      expression = _processScientificFunctions(expression);

      Parser p = Parser();
      Expression exp = p.parse(expression);
      ContextModel cm = ContextModel();
      double result = exp.evaluate(EvaluationType.REAL, cm);

      output = _formatResult(result);
      historyList.add("$input = $output");
      _saveHistory();
      input = output;

      // Speak the answer in words
      String spokenAnswer = _numberToWords(output);
      print('🧮 Calculation result: $output, speaking: $spokenAnswer');
      _speak("The answer is $spokenAnswer");
    } catch (e) {
      output = "Error";
      print('❌ Calculation error: $e');
      _speak("Error");
    }
  }

  String _processScientificFunctions(String expr) {
    // Process trigonometric and logarithmic functions
    RegExp funcPattern = RegExp(r'(sin|cos|tan|log|ln)\(([^)]+)\)');

    expr = expr.replaceAllMapped(funcPattern, (match) {
      String func = match.group(1)!;
      String value = match.group(2)!;

      try {
        // First evaluate the value inside
        Parser p = Parser();
        Expression exp = p.parse(value);
        ContextModel cm = ContextModel();
        double numValue = exp.evaluate(EvaluationType.REAL, cm);

        double result;
        switch (func) {
          case 'sin':
            result = math.sin(numValue * math.pi / 180); // Convert to radians
            break;
          case 'cos':
            result = math.cos(numValue * math.pi / 180);
            break;
          case 'tan':
            result = math.tan(numValue * math.pi / 180);
            break;
          case 'log':
            result = math.log(numValue) / math.ln10; // Base 10
            break;
          case 'ln':
            result = math.log(numValue);
            break;
          default:
            return match.group(0)!;
        }
        return result.toString();
      } catch (e) {
        return match.group(0)!;
      }
    });

    return expr;
  }

  String _formatResult(double result) {
    if (result == result.toInt()) {
      return result.toInt().toString();
    } else {
      return result
          .toStringAsFixed(8)
          .replaceAll(RegExp(r'0*$'), '')
          .replaceAll(RegExp(r'\.$'), '');
    }
  }

  Future<void> _exportHistory() async {
    if (historyList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No history to export')),
      );
      return;
    }

    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/calculator_history.txt');
      await file.writeAsString(historyList.join('\n'));

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('History saved to ${file.path}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to export history')),
      );
    }
  }

  Future<void> _shareHistory() async {
    if (historyList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No history to share')),
      );
      return;
    }

    await Share.share(
      'Calculator History:\n\n${historyList.join('\n')}',
      subject: 'Calculator History',
    );
  }

  Widget buildScientificButton(String buttonText, Color color,
      {bool isWide = false}) {
    return Expanded(
      flex: isWide ? 2 : 1,
      child: Container(
        margin: const EdgeInsets.all(2.5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.5),
              blurRadius: 15,
              spreadRadius: 0,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => buttonPressed(buttonText),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        color.withOpacity(0.85),
                        color.withOpacity(0.70),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 1.5,
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Center(
                    child: Text(
                      getDisplayText(buttonText),
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            color: Colors.black38,
                            offset: Offset(0, 2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildBasicButton(String buttonText, Color color,
      {bool isWide = false}) {
    return Expanded(
      flex: isWide ? 2 : 1,
      child: Container(
        margin: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.5),
              blurRadius: 15,
              spreadRadius: 0,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => buttonPressed(buttonText),
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        color.withOpacity(0.85),
                        color.withOpacity(0.70),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 1.5,
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: Text(
                      getDisplayText(buttonText),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            color: Colors.black38,
                            offset: Offset(0, 2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBasicCalculator() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final numberColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;
    final operatorColor = isDark ? Colors.blueGrey : Colors.blue[700]!;
    final specialColor = isDark ? Colors.orange : Colors.orange[700]!;
    final equalsColor = isDark ? Colors.green : Colors.green[700]!;

    return Column(
      children: [
        Row(
          children: [
            buildBasicButton("C", specialColor),
            buildBasicButton("(", operatorColor),
            buildBasicButton(")", operatorColor),
            buildBasicButton("⌫", specialColor),
          ],
        ),
        Row(
          children: [
            buildBasicButton("MC", operatorColor),
            buildBasicButton("MR", operatorColor),
            buildBasicButton("M+", operatorColor),
            buildBasicButton("M-", operatorColor),
          ],
        ),
        Row(
          children: [
            buildBasicButton("7", numberColor),
            buildBasicButton("8", numberColor),
            buildBasicButton("9", numberColor),
            buildBasicButton("÷", operatorColor),
          ],
        ),
        Row(
          children: [
            buildBasicButton("4", numberColor),
            buildBasicButton("5", numberColor),
            buildBasicButton("6", numberColor),
            buildBasicButton("×", operatorColor),
          ],
        ),
        Row(
          children: [
            buildBasicButton("1", numberColor),
            buildBasicButton("2", numberColor),
            buildBasicButton("3", numberColor),
            buildBasicButton("-", operatorColor),
          ],
        ),
        Row(
          children: [
            buildBasicButton("%", operatorColor),
            buildBasicButton("0", numberColor),
            buildBasicButton(".", numberColor),
            buildBasicButton("+", operatorColor),
          ],
        ),
        Row(
          children: [
            buildBasicButton("MS", operatorColor),
            buildBasicButton("=", equalsColor, isWide: true),
          ],
        ),
      ],
    );
  }

  Widget _buildScientificCalculator() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final numberColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;
    final operatorColor = isDark ? Colors.blueGrey : Colors.blue[700]!;
    final specialColor = isDark ? Colors.orange : Colors.orange[700]!;
    final scientificColor = isDark ? Colors.purple[700]! : Colors.purple[600]!;
    final equalsColor = isDark ? Colors.green : Colors.green[700]!;

    return Column(
      children: [
        Row(
          children: [
            buildScientificButton("C", specialColor),
            buildScientificButton("(", operatorColor),
            buildScientificButton(")", operatorColor),
            buildScientificButton("⌫", specialColor),
          ],
        ),
        Row(
          children: [
            buildScientificButton("sin", scientificColor),
            buildScientificButton("cos", scientificColor),
            buildScientificButton("tan", scientificColor),
            buildScientificButton("π", scientificColor),
          ],
        ),
        Row(
          children: [
            buildScientificButton("log", scientificColor),
            buildScientificButton("ln", scientificColor),
            buildScientificButton("√", scientificColor),
            buildScientificButton("xⁿ", scientificColor),
          ],
        ),
        Row(
          children: [
            buildScientificButton("x²", scientificColor),
            buildScientificButton("e", scientificColor),
            buildScientificButton("÷", operatorColor),
            buildScientificButton("×", operatorColor),
          ],
        ),
        Row(
          children: [
            buildScientificButton("7", numberColor),
            buildScientificButton("8", numberColor),
            buildScientificButton("9", numberColor),
            buildScientificButton("-", operatorColor),
          ],
        ),
        Row(
          children: [
            buildScientificButton("4", numberColor),
            buildScientificButton("5", numberColor),
            buildScientificButton("6", numberColor),
            buildScientificButton("+", operatorColor),
          ],
        ),
        Row(
          children: [
            buildScientificButton("1", numberColor),
            buildScientificButton("2", numberColor),
            buildScientificButton("3", numberColor),
            buildScientificButton("%", operatorColor),
          ],
        ),
        Row(
          children: [
            buildScientificButton("0", numberColor, isWide: true),
            buildScientificButton(".", numberColor),
            buildScientificButton("=", equalsColor),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      Colors.black.withOpacity(0.7),
                      Colors.grey[900]!.withOpacity(0.6)
                    ]
                  : [
                      Colors.white.withOpacity(0.85),
                      Colors.blue[50]!.withOpacity(0.7)
                    ],
            ),
          ),
          child: ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                color: Colors.transparent,
              ),
            ),
          ),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: isDark
                    ? [Colors.blue[300]!, Colors.purple[300]!]
                    : [Colors.blue[700]!, Colors.purple[700]!],
              ).createShader(bounds),
              child: const Text(
                "Calculator",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: Colors.white,
                  fontFamily: 'monospace',
                  shadows: [
                    Shadow(
                      color: Colors.black26,
                      offset: Offset(0, 2),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
            ),
            if (hasMemory)
              Container(
                margin: const EdgeInsets.only(left: 6),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'M',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              isSoundEnabled ? Icons.volume_up : Icons.volume_off,
              size: 20,
            ),
            onPressed: () async {
              setState(() {
                isSoundEnabled = !isSoundEnabled;
              });
              _saveSoundPreference();
              if (isSoundEnabled) {
                // Test TTS when enabling
                await testTts();
              }
            },
            tooltip: 'Sound',
          ),
          PopupMenuButton<String>(
            icon: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [
                          Colors.white.withOpacity(0.15),
                          Colors.white.withOpacity(0.08)
                        ]
                      : [
                          Colors.white.withOpacity(0.9),
                          Colors.white.withOpacity(0.6)
                        ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withOpacity(0.2)
                      : Colors.white.withOpacity(0.5),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.language, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    selectedLanguage,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_drop_down, size: 18),
                ],
              ),
            ),
            tooltip: 'Language: $selectedLanguage',
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 8,
            color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
            offset: const Offset(0, 50),
            onSelected: (String newValue) {
              setState(() {
                selectedLanguage = newValue;
              });
              _saveLanguage(newValue);
              _vibrate();
            },
            itemBuilder: (BuildContext context) {
              return languages.map((String value) {
                String flag = '';
                String nativeName = '';
                switch (value) {
                  case 'English':
                    flag = '🇬🇧';
                    nativeName = 'English';
                    break;
                  case 'Gujarati':
                    flag = '🇮🇳';
                    nativeName = 'ગુજરાતી';
                    break;
                  case 'Hindi':
                    flag = '🇮🇳';
                    nativeName = 'हिन्दी';
                    break;
                  case 'Marathi':
                    flag = '🇮🇳';
                    nativeName = 'मराठी';
                    break;
                  case 'Bengali':
                    flag = '🇮🇳';
                    nativeName = 'বাংলা';
                    break;
                  case 'Tamil':
                    flag = '🇮🇳';
                    nativeName = 'தமிழ்';
                    break;
                }
                final isSelected = selectedLanguage == value;
                return PopupMenuItem<String>(
                  value: value,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? LinearGradient(
                              colors: isDark
                                  ? [
                                      Colors.blue.withOpacity(0.3),
                                      Colors.purple.withOpacity(0.2)
                                    ]
                                  : [
                                      Colors.blue.withOpacity(0.15),
                                      Colors.purple.withOpacity(0.1)
                                    ],
                            )
                          : null,
                      borderRadius: BorderRadius.circular(12),
                      border: isSelected
                          ? Border.all(
                              color: isDark
                                  ? Colors.blue.withOpacity(0.5)
                                  : Colors.blue.withOpacity(0.3),
                              width: 1.5,
                            )
                          : null,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withOpacity(0.1)
                                : Colors.grey.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          alignment: Alignment.center,
                          child:
                              Text(flag, style: const TextStyle(fontSize: 20)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                value,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                              if (nativeName != value)
                                Text(
                                  nativeName,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark
                                        ? Colors.white60
                                        : Colors.black54,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.blue.withOpacity(0.3)
                                  : Colors.blue.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.check,
                              size: 16,
                              color: isDark ? Colors.blue[300] : Colors.blue,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              }).toList();
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [const Color(0xFF0A0E27), const Color(0xFF1A1F3A), const Color(0xFF0F1419)]
                : [const Color(0xFFE3F2FD), const Color(0xFFF3E5F5), const Color(0xFFFCE4EC)],
          ),
        ),
        child: Column(
          children: <Widget>[
            // Display Area with glassmorphism
            Container(
              margin: const EdgeInsets.fromLTRB(10, 8, 10, 6),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [
                          Colors.white.withOpacity(0.10),
                          Colors.white.withOpacity(0.04),
                        ]
                      : [
                          Colors.white.withOpacity(0.95),
                          Colors.white.withOpacity(0.88),
                        ],
                ),
                borderRadius: BorderRadius.circular(26),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withOpacity(0.18)
                      : Colors.white.withOpacity(0.7),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? Colors.black.withOpacity(0.5)
                        : Colors.black.withOpacity(0.08),
                    blurRadius: 28,
                    spreadRadius: 0,
                    offset: const Offset(0, 10),
                  ),
                  BoxShadow(
                    color: isDark
                        ? Colors.blue.withOpacity(0.1)
                        : Colors.blue.withOpacity(0.04),
                    blurRadius: 18,
                    spreadRadius: -4,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Input display
                  Container(
                    width: double.infinity,
                    height: 35,
                    padding: const EdgeInsets.only(bottom: 8),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      reverse: true,
                      child: Text(
                        getDisplayText(input.isEmpty ? "0" : input),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w400,
                          letterSpacing: 0.5,
                          color: isDark ? Colors.white60 : Colors.black45,
                          height: 1.2,
                        ),
                      ),
                    ),
                  ),
                  // Output display
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      reverse: true,
                      child: Text(
                        getDisplayText(output),
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                          color: isDark ? Colors.white : Colors.black87,
                          height: 1.1,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // History Section - Compact Chips
            Container(
              height: 52,
              margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              child: Row(
                children: [
                  Container(
                    width: 62,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDark
                            ? [
                                Colors.white.withOpacity(0.10),
                                Colors.white.withOpacity(0.05)
                              ]
                            : [
                                Colors.white.withOpacity(0.98),
                                Colors.white.withOpacity(0.90)
                              ],
                      ),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withOpacity(0.18)
                            : Colors.white.withOpacity(0.7),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isDark
                              ? Colors.black.withOpacity(0.3)
                              : Colors.black.withOpacity(0.06),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: PopupMenuButton<String>(
                      icon: Icon(
                        Icons.history,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                      tooltip: 'History Options',
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'share',
                          child: Row(
                            children: [
                              Icon(Icons.share, size: 18),
                              SizedBox(width: 8),
                              Text('Share'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'export',
                          child: Row(
                            children: [
                              Icon(Icons.download, size: 18),
                              SizedBox(width: 8),
                              Text('Export'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'clear',
                          child: Row(
                            children: [
                              Icon(Icons.delete, size: 18),
                              SizedBox(width: 8),
                              Text('Clear'),
                            ],
                          ),
                        ),
                      ],
                      onSelected: (value) {
                        if (value == 'share') {
                          _shareHistory();
                        } else if (value == 'export') {
                          _exportHistory();
                        } else if (value == 'clear') {
                          setState(() {
                            historyList.clear();
                            _saveHistory();
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: historyList.isEmpty
                        ? Center(
                            child: Text(
                              'No history',
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark ? Colors.white38 : Colors.black38,
                              ),
                            ),
                          )
                        : ListView.builder(
                            scrollDirection: Axis.horizontal,
                            reverse: true,
                            itemCount: historyList.length,
                            itemBuilder: (context, index) {
                              final reverseIndex =
                                  historyList.length - 1 - index;
                              return GestureDetector(
                                onTap: () {
                                  String history = historyList[reverseIndex];
                                  if (history.contains('=')) {
                                    String result =
                                        history.split('=').last.trim();
                                    setState(() {
                                      input = result;
                                      output = result;
                                    });
                                    _vibrate();
                                  }
                                },
                                child: Container(
                                  margin: const EdgeInsets.only(
                                      right: 8, top: 2, bottom: 2),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 12),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: isDark
                                          ? [
                                              Colors.blue.withOpacity(0.15),
                                              Colors.purple.withOpacity(0.1)
                                            ]
                                          : [
                                              Colors.blue.withOpacity(0.15),
                                              Colors.purple.withOpacity(0.05)
                                            ],
                                    ),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: isDark
                                          ? Colors.blue.withOpacity(0.3)
                                          : Colors.blue.withOpacity(0.4),
                                      width: 1.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.blue.withOpacity(0.2),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    historyList[reverseIndex],
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: isDark
                                          ? Colors.blue[200]
                                          : Colors.blue[900],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
            // Mode Toggle Buttons
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [
                          Colors.white.withOpacity(0.10),
                          Colors.white.withOpacity(0.05)
                        ]
                      : [
                          Colors.white.withOpacity(0.98),
                          Colors.white.withOpacity(0.90)
                        ],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withOpacity(0.18)
                      : Colors.white.withOpacity(0.7),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? Colors.black.withOpacity(0.3)
                        : Colors.black.withOpacity(0.08),
                    blurRadius: 22,
                    spreadRadius: 0,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          isScientificMode = false;
                        });
                        _vibrate();
                      },
                      icon: const Icon(Icons.calculate, size: 18),
                      label: const Text('Basic'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: !isScientificMode
                            ? (isDark ? Colors.blue[700] : Colors.blue)
                            : (isDark ? Colors.grey[800] : Colors.grey[400]),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          isScientificMode = true;
                        });
                        _vibrate();
                      },
                      icon: const Icon(Icons.functions, size: 18),
                      label: const Text('Scientific'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isScientificMode
                            ? (isDark ? Colors.purple[700] : Colors.purple)
                            : (isDark ? Colors.grey[800] : Colors.grey[400]),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? Colors.green[700] : Colors.green,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      onPressed: () {
                        setState(() {
                          input = "";
                          output = "0";
                        });
                        _vibrate();
                      },
                      icon: const Icon(Icons.refresh, color: Colors.white),
                      tooltip: 'Clear All',
                    ),
                  ),
                ],
              ),
            ),
            // Calculator Buttons
            Expanded(
              child: Container(
                padding:
                    const EdgeInsets.only(left: 8, right: 8, top: 2, bottom: 0),
                child: isScientificMode
                    ? _buildScientificCalculator()
                    : _buildBasicCalculator(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
