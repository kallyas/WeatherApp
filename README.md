# Modern Weather App

A beautiful, feature-rich weather application built with SwiftUI following modern architecture patterns.

![Weather App Banner](https://via.placeholder.com/800x400.png?text=Weather+App)

## Features

- 🌦 Real-time weather data from OpenWeather API
- 📱 Clean, modern UI with beautiful animations
- 🌓 Dark and light mode support
- 📍 Location-based weather
- 🔍 City search functionality
- ⏱ Hourly forecast (24 hours)
- 📆 7-day forecast with temperature ranges
- 📊 Detailed weather metrics (UV index, pressure, visibility, humidity)
- 🎭 Animated weather effects based on conditions
- 🔄 Pull-to-refresh for updating data

## Screenshots

<table>
  <tr>
    <td><img src="https://via.placeholder.com/250x500.png?text=Weather+Home" alt="Home Screen" /></td>
    <td><img src="https://via.placeholder.com/250x500.png?text=Weather+Details" alt="Details Screen" /></td>
    <td><img src="https://via.placeholder.com/250x500.png?text=Weather+Search" alt="Search Screen" /></td>
  </tr>
  <tr>
    <td>Home Screen</td>
    <td>Details View</td>
    <td>Search View</td>
  </tr>
</table>

## Architecture

The app follows MVVM architecture with Clean Architecture principles:

- **Models**: Data structures for API responses
- **Views**: SwiftUI views for UI representation
- **ViewModels**: Business logic and data transformation
- **Use Cases**: Business rules and data flow coordination
- **Repositories**: Abstract data source operations
- **Network Services**: Handle API communication

## Requirements

- iOS 16.0+
- Xcode 14.0+
- Swift 5.7+
- OpenWeather API Key

## Installation

1. Clone the repository
   ```bash
   git clone https://github.com/yourusername/WeatherApp.git
   cd WeatherApp
   ```

2. Open the project in Xcode
   ```bash
   open WeatherApp.xcodeproj
   ```

3. Set your OpenWeather API Key
   - Open `Core/Data/Network/NetworkService.swift`
   - Replace `YOUR_OPENWEATHER_API_KEY` with your actual API key

4. Build and run the application

## Setup from Script

If you want to start from scratch:

1. Run the setup script
   ```bash
   ./setup-weather-app.sh
   ```

2. Follow the instructions in the terminal

## Project Structure

```
WeatherApp/
├── App/                      # App entry point
├── Core/                     # Core business logic
│   ├── Domain/               # Business models and use cases
│   ├── Data/                 # Data handling
│   └── DI/                   # Dependency injection
├── Features/                 # App features 
│   ├── Common/               # Shared components
│   ├── Welcome/              # Welcome screen
│   ├── Weather/              # Main weather feature
│   └── Search/               # Search functionality
├── Services/                 # Helper services
├── Resources/                # App resources
└── Config/                   # Configuration files
```

## Weather Effects

The app includes dynamic weather effects based on current conditions:

- **Clear**: Clean gradient background
- **Cloudy**: Animated clouds
- **Rainy**: Animated raindrops
- **Stormy**: Heavy rain with lightning flashes
- **Snowy**: Animated snowflakes
- **Foggy**: Animated fog layers

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the project
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgements

- [OpenWeather API](https://openweathermap.org/api) for weather data
- [SwiftUI](https://developer.apple.com/xcode/swiftui/) for the UI framework
- Icon designs inspired by Apple's SF Symbols

