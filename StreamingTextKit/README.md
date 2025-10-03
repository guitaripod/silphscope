# StreamingTextKit

A universal streaming text UI framework for iOS that provides smooth, natural-feeling text rendering for any async text source.

## Features

- **Universal**: Works with any `AsyncThrowingStream<String, Error>` source
- **Smooth Streaming**: Natural typing simulation with configurable speeds
- **Observable Framework**: Modern iOS 17+ with `@Observable`
- **Protocol-Oriented**: Easy to adapt any streaming text API
- **Zero Dependencies**: Pure Foundation + UIKit

## Use Cases

- LLM chat interfaces (OpenAI, Anthropic, Ollama)
- Server-Sent Events (SSE) feeds
- WebSocket text streams
- Live log viewers
- Translation services
- Speech-to-text transcription
- Code generation UIs

## Installation

### Local Package (Development)

Add as a local package dependency in Xcode:
1. File → Add Package Dependencies
2. Add Local → Select `StreamingTextKit` folder
3. Add to target

## Usage

### Basic Streaming

```swift
import StreamingTextKit

let handler = StreamingTextHandler(typingSpeed: .natural)
handler.delegate = self

let stream: AsyncThrowingStream<String, Error> = // your stream
handler.startStreaming(stream)
```

### Typing Speed Options

```swift
.instant          // No delay
.fast            // 2ms delay, 5-10 chars/chunk
.natural         // 5ms delay, 1-3 chars/chunk (default)
.slow            // 15ms delay, 1-2 chars/chunk
.custom(1...5, delayNanoseconds: 10_000_000)
```

### Adapting Streaming Sources

Example: Ollama (Swollama)

```swift
struct SwollamaStreamAdapter {
    static func adapt(_ ollamaStream: AsyncThrowingStream<ChatResponse, Error>)
        -> AsyncThrowingStream<String, Error> {

        AsyncThrowingStream { continuation in
            Task {
                for try await response in ollamaStream {
                    if !response.message.content.isEmpty {
                        continuation.yield(response.message.content)
                    }
                    if response.done {
                        continuation.finish()
                    }
                }
            }
        }
    }
}
```

## Core Components

### StreamingTextHandler
Generic async stream processor with typing simulation

### StreamingTextMessage
Protocol-agnostic message model

### MessagePresenting
Protocol for formatting messages and thinking states

## Requirements

- iOS 17.0+
- Swift 5.9+

## License

MIT
