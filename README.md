# Advanced Gujarati Voice Calculator

A feature-rich calculator app with scientific functions, memory operations, and bilingual support (English & Gujarati). The app includes voice feedback, haptic feedback, calculation history, and multiple themes.

## ✨ Features

### Basic Operations
- **Arithmetic Operations**: Addition (+), subtraction (-), multiplication (×), and division (÷)
- **Advanced Expressions**: Support for parentheses and complex expressions like `(1+3) × 2`
- **Percentage Calculations**: Quick percentage operations
- **Decimal Support**: Full floating-point number support

### Scientific Calculator
- **Trigonometric Functions**: sin, cos, tan (in degrees)
- **Logarithmic Functions**: log (base 10), ln (natural log)
- **Power Functions**: Square (x²), power (xⁿ), square root (√)
- **Mathematical Constants**: π (pi), e (Euler's number)

### Memory Operations
- **MS (Memory Store)**: Save current result to memory
- **MR (Memory Recall)**: Recall value from memory
- **M+ (Memory Add)**: Add current result to memory
- **M- (Memory Subtract)**: Subtract current result from memory
- **MC (Memory Clear)**: Clear memory value
- **Memory Indicator**: Visual indicator when memory contains a value

### History & Data Management
- **Calculation History**: Automatic saving of all calculations
- **Tap to Reuse**: Tap any history item to reuse its result
- **Persistent Storage**: History saved between app sessions
- **Export History**: Save history to a text file
- **Share History**: Share calculations via other apps
- **Clear History**: Remove all saved calculations

### Language & Accessibility
- **Multi-Language Support**: Dropdown menu with 6 languages:
  - 🇬🇧 English (with English numerals)
  - 🇮🇳 Gujarati (with Gujarati numerals ૦-૯)
  - 🇮🇳 Hindi (with Devanagari numerals ०-९)
  - 🇮🇳 Marathi (with Devanagari numerals ०-९)
  - 🇮🇳 Bengali (with Bengali numerals ০-৯)
  - 🇮🇳 Tamil (with English numerals)
- **Voice Feedback**: Text-to-speech in all supported languages with native locales
- **Sound Toggle**: Enable/disable voice feedback
- **Language Persistence**: Your language preference is saved between sessions

### User Experience
- **Light/Dark Themes**: Switch between light and dark modes with persistence
- **Haptic Feedback**: Vibration on button presses (can be toggled)
- **Copy/Paste**: Copy results to clipboard and paste values into calculator
- **Responsive Design**: Beautiful, modern UI that adapts to theme
- **Tab Interface**: Switch between Basic and Scientific calculator modes

## 📱 Screenshots

![App View](assets/AppView.PNG)

## 🚀 Installation

To run this project locally, follow these steps:

1. **Clone the repository:**

   ```bash
   git clone https://github.com/Pankaj-EC/Calculator.git
   cd Calculator
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Run the app:**
   ```bash
   flutter run
   ```

4. **Build for release:**
   ```bash
   # Android
   flutter build apk --release
   
   # iOS
   flutter build ios --release
   
   # Web
   flutter build web --release
   ```

## 📦 Dependencies

- **flutter_tts** (^3.2.2): Text-to-speech functionality in multiple languages
- **math_expressions** (^2.0.1): Parsing and evaluating mathematical expressions
- **shared_preferences** (^2.2.2): Persistent storage for theme and history
- **share_plus** (^7.2.1): Sharing history with other apps
- **vibration** (^1.8.4): Haptic feedback on button presses
- **path_provider** (^2.1.1): File system access for exporting history

## 🎯 Usage

### Basic Calculator Mode
- Perform standard arithmetic operations
- Use memory functions (MS, MR, M+, M-, MC)
- Access calculation history

### Scientific Calculator Mode
- Access trigonometric functions: `sin(30)`, `cos(45)`, `tan(60)`
- Calculate logarithms: `log(100)`, `ln(2.718)`
- Use power functions: `2^8`, or tap `x²` for quick squares
- Insert mathematical constants: π, e

### Settings & Toggles
- **Theme**: Tap the sun/moon icon to switch between light and dark themes
- **Haptic**: Tap the vibration icon to enable/disable haptic feedback
- **Sound**: Tap the volume icon to enable/disable voice feedback
- **Language**: Use the dropdown menu to select from 6 supported languages (English, Gujarati, Hindi, Marathi, Bengali, Tamil)

### History Management
- **Reuse Calculations**: Tap any history item to load its result
- **Share**: Tap the share icon to share history with other apps
- **Export**: Tap the download icon to save history to a file
- **Clear**: Tap the delete icon to remove all history

### Copy & Paste
- Tap the copy icon next to the result to copy to clipboard
- Tap the paste icon to paste a number into the calculator

## 🎨 Theme Support

The calculator supports both light and dark themes:
- **Dark Theme**: Default, easy on the eyes
- **Light Theme**: Clean, bright interface
- **Theme Persistence**: Your theme preference is saved between sessions

## 🌍 Supported Platforms

- ✅ Android
- ✅ iOS
- ✅ Web
- ✅ Windows
- ✅ macOS
- ✅ Linux

## 🌐 Supported Languages

| Language | Script | Numerals | TTS Locale |
|----------|--------|----------|------------|
| 🇬🇧 English | Latin | 0-9 | en-US |
| 🇮🇳 Gujarati | Gujarati | ૦-૯ | gu-IN |
| 🇮🇳 Hindi | Devanagari | ०-९ | hi-IN |
| 🇮🇳 Marathi | Devanagari | ०-९ | mr-IN |
| 🇮🇳 Bengali | Bengali | ০-৯ | bn-IN |
| 🇮🇳 Tamil | Tamil | 0-9 | ta-IN |

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
- Clear History: Use the clear button in the history section to remove all previous calculations.
- Backspace: Use the backspace icon to delete the last character in the current input.
- Calculate: Enter your expression and press = to see the result.

## Code Overview
### Main File
The main file main.dart contains the following components:

- MyApp: The root widget of the application.
- Calculator: The stateful widget containing the main logic and UI of the calculator.
- ButtonPressed Function: Handles the logic for different button presses.
- History Section: Displays the history of calculations.

## Calculator Logic
The calculator logic supports basic arithmetic operations, percentage calculations, and complex expressions. The math_expressions package is used to parse and evaluate expressions, allowing for complex calculations.

## Voice Feedback
The app uses the flutter_tts package to provide voice feedback in the selected language (English or Gujarati). The voice feedback is triggered upon pressing the = button.

## Contributing
Feel free to submit issues and enhancement requests. If you'd like to contribute, please fork the repository and use a feature branch. Pull requests are welcome.