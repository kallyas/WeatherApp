# Weather App

A modern iOS weather application built with SwiftUI that provides detailed weather information using the OpenWeather API.

![Weather App Screenshot](app_screenshot.png)

## Features

- **Current Weather**: View current weather conditions including temperature, feels-like temperature, humidity, wind speed, and more
- **Hourly Forecast**: See weather predictions for the next 48 hours
- **7-Day Forecast**: View extended forecasts for the week ahead
- **Location-Based Weather**: Automatically fetch weather for your current location
- **Search Locations**: Search for weather in any city worldwide
- **Favorite Locations**: Save your frequently accessed locations for quick access
- **Weather Maps**: View weather patterns on an interactive map
- **Dark Mode Support**: Beautiful UI in both light and dark modes
- **Custom Themes**: Personalize the app with custom accent colors
- **Offline Support**: Access previously loaded weather data even without internet
- **Weather Alerts**: Get notified about severe weather conditions

## Technical Details

The app is built using modern iOS development practices:

- **Architecture**: Clean Architecture with MVVM presentation layer
- **UI Framework**: SwiftUI with programmatic UI components
- **State Management**: Combine framework for reactive programming
- **Dependency Injection**: Custom DI container for better testability
- **Network Layer**: Robust API client with error handling and retries
- **Caching**: Efficient caching mechanism for offline support
- **Location Services**: CoreLocation integration with permission handling
- **Persistence**: UserDefaults and file-based storage

## Requirements

- iOS 14.0+
- Xcode 13.0+
- Swift 5.5+
- OpenWeather API Key

## Installation

1. Clone the repository:
   ```
   git clone https://github.com/username/WeatherApp.git
   ```

2. Open `WeatherApp.xcodeproj` in Xcode

3. Set your OpenWeather API key:
   - Go to `WeatherApp/Config/Development.xcconfig`
   - Replace `YOUR_DEVELOPMENT_API_KEY` with your actual API key
   - For production builds, also update `WeatherApp/Config/Production.xcconfig`

4. Build and run the application on your device or simulator

## Configuration

The app supports various configuration options:

- **API Keys**: Manage API keys for different environments
- **Temperature Units**: Choose between Celsius and Fahrenheit
- **Refresh Frequency**: Control how often weather data updates
- **Notifications**: Enable/disable different types of weather alerts

## Architecture

The app follows Clean Architecture principles with the following layers:

- **Presentation Layer**: SwiftUI views and view models
- **Domain Layer**: Use cases and domain models
- **Data Layer**: Repositories and data sources
- **Core**: Shared utilities and extensions

### Key Components

- **AppContainer**: Centralized dependency injection container
- **WeatherViewModel**: Manages weather data and UI state
- **WeatherRepository**: Handles data access with caching
- **LocationManager**: Manages device location services
- **NetworkMonitorService**: Tracks network connectivity
- **ThemeManager**: Handles app appearance customization

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- [OpenWeather API](https://openweathermap.org/api) for weather data
- [SF Symbols](https://developer.apple.com/sf-symbols/) for weather icons
