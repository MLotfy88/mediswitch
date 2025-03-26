# mediswitch

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Wi-Fi Debugging

To enable mobile connection via Wi-Fi debugging for `flutter run`, follow these steps:

1.  Connect your Android device to your computer using a USB cable.
2.  Enable USB debugging on your device in the Developer options.
3.  Open a terminal and run `adb tcpip 5555`.
4.  Disconnect the USB cable from your device.
5.  Find the IP address of your Android device (Settings -> About phone -> Status).
6.  In the terminal, run `adb connect <device_ip_address>:5555`.
7.  Now you can run `flutter run` and the application will be installed and run on your device via Wi-Fi.
