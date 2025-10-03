# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Silphscope is an iOS application built with UIKit (no Storyboards) that targets iPhone devices running iOS 17.6+. The project uses a programmatic UI approach with SceneDelegate for window management.

## Build and Run Commands

Build the project:
```bash
xcodebuild -project silphscope.xcodeproj -scheme silphscope -configuration Debug build
```

Build for simulator:
```bash
xcodebuild -project silphscope.xcodeproj -scheme silphscope -destination 'platform=iOS Simulator,name=iPhone 15' build
```

Clean build:
```bash
xcodebuild -project silphscope.xcodeproj -scheme silphscope clean
```

## Dependencies

- **Swollama**: Local package located at `../../swift/Swollama`
- **GRDB**: Database library

## Architecture Notes

- **Never ever add code comments**. They are BLOAT.
- Follow the existing programmatic UI approach - no Interface Builder
- Use UIStackView's heavily to simplify the layout code. UIStackView's are very configurable and performant.
- Always use the latest UIKit APIs like diffable datasource
- Use MVVM architecture
- GRDB for all data persistence
- UIKit only - No SwiftUI
- Prefer Protocol-Oriented-Programming over Object-Oriented-Programming
- **Logging**: Use `AppLogger` for all logging - never use `print()` statements. AppLogger provides structured logging with categories.
- **Deployment target**: iOS 17.6 (minimum), though project settings show iOS 18.2 SDK
- **Supported devices**: iPhone only (TARGETED_DEVICE_FAMILY = 1)
- **Bundle ID**: com.guitaripod.silphscope
- **Team ID**: P4DQK6SRKR

## Coding practices

- **swift-format**: Always run swift-format before committing anything.
