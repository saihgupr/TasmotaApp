# TasmotaApp <img src="https://i.imgur.com/J8fkOBi.png" width="5%" align="right" />

A native iOS and macOS app for controlling Tasmota-powered smart devices on your local network. Built with SwiftUI for a modern, responsive interface that adapts to different device orientations and screen sizes across iPhone, iPad, and Mac.

## Features

- **Device Management**: Add, edit, and delete Tasmota devices with custom names and IP addresses
- **Group Organization**: Organize devices into logical groups (lights, switches, etc.)
- **Real-time Control**: Toggle devices on/off with immediate feedback
- **Status Monitoring**: View current power state of all devices
- **JSON Import/Export**: Bulk import device configurations from JSON files
- **Responsive Design**: Adaptive layout that uses single column on iPhone portrait mode for better usability
- **Cross-Platform**: Native iOS and macOS app with Mac Catalyst support
- **Native Experience**: Built with SwiftUI for optimal performance and integration across all Apple platforms

### iPhone
<div align="center">
  <img src="https://i.imgur.com/IFTyEms.png" width="22%" />
  <img src="https://i.imgur.com/J0f1NAW.png" width="22%" />
  <img src="https://i.imgur.com/99CrRth.png" width="22%" />
  <img src="https://i.imgur.com/wupTeOF.png" width="22%" />
</div>

### iPad
<div align="center">
  <img src="https://i.imgur.com/nHEg8rk.png" width="45%" style="margin-right: 5px;" />
</div>

### macOS
<div align="center">
  <img src="https://i.imgur.com/O2a2pNS.png" width="45%" style="margin-left: 5px;" />
</div>

## Requirements

- iOS 14.6+ / macOS 12.0+
- Xcode 13.0+
- Swift 5.5+
- Devices running Tasmota firmware on your local network

## Installation

### Option 1: Download from Releases

Download the latest pre-built app from the [Releases](https://github.com/saihgupr/TasmotaApp/releases) page. Simply download the `.app` file and move it to your Applications folder, or sideload the `.ipa` file to your iOS device.

### Option 2: Build from Source

1. Clone this repository:
   ```bash
   git clone https://github.com/saihgupr/TasmotaApp.git
   cd TasmotaApp
   ```

2. Open `TasmotaApp.xcodeproj` in Xcode

3. Select your target device, simulator, or "My Mac (Mac Catalyst)" for macOS

4. Build and run the project (⌘+R)

### Option 3: Use Build Script

```bash
./build.sh
```

## Quick Start

### Setting up your first devices

1. **Manual Entry**: Tap the "+" button to add devices one by one
2. **JSON Import**: Use the import feature to bulk add devices from a JSON file

### JSON Format

The app uses a simple JSON structure to define device groups and their IP addresses:

```json
{
    "lights": {
        "desk": "192.168.1.132",
        "shelf": "192.168.1.24",
        "bed": "192.168.1.16"
    },
    "switches": {
        "heater": "192.168.1.124",
        "humidifier": "192.168.1.31",
        "kettle": "192.168.1.128"
    }
}
```

### Example Configuration

See `sample_devices.json` for a complete example configuration.

## How it Works

The app communicates with Tasmota devices using their built-in HTTP API:

- **Toggle Command**: `http://[device-ip]/cm?cmnd=Power%20Toggle`
- **Status Query**: `http://[device-ip]/cm?cmnd=Power`

Devices respond with JSON containing their current power state, allowing the app to display accurate status information.

## Architecture

- **SwiftUI**: Modern declarative UI framework
- **ObservableObject**: Reactive data management with `DeviceManager`
- **URLSession**: Native HTTP networking for device communication
- **Local Storage**: Device configurations saved in app documents directory
- **Size Classes**: Responsive layout using environment values

## Key Components

- `ContentView`: Main app interface with navigation and device listing
- `DeviceGroupView`: Displays grouped devices with adaptive column layout
- `DeviceCard`: Individual device control interface with toggle and context menu
- `TasmotaAPI`: HTTP communication layer for device control
- `DeviceManager`: Core data management and persistence
- `AddEditDeviceView`: Device configuration interface
- `ImportJSONView`: Bulk device import functionality

## Tasmota Device Setup

To use this app with your devices, ensure they're running Tasmota firmware with HTTP API enabled:

1. Flash your device with [Tasmota firmware](https://tasmota.github.io/docs/)
2. Connect the device to your WiFi network
3. Note the device's IP address (check your router's DHCP client list)
4. Test the device responds to HTTP commands:
   ```bash
   curl http://[device-ip]/cm?cmnd=Power
   ```

## Contributing

Contributions are welcome! Please feel free to submit pull requests or open issues for bugs and feature requests.

## Acknowledgments

- [Tasmota](https://tasmota.github.io/docs/) - The amazing open-source firmware that makes this possible
- Apple's SwiftUI team for the excellent declarative UI framework
- The iOS development community for inspiration and best practices

---

**Note**: This app requires devices to be on the same local network. Remote access and cloud connectivity are not currently supported.
