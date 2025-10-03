import Foundation

public enum TypingSpeed {
    case instant
    case fast
    case natural
    case slow
    case custom(chunkSize: ClosedRange<Int>, delayNanoseconds: UInt64)

    var chunkSize: ClosedRange<Int> {
        switch self {
        case .instant:
            return 1000...1000
        case .fast:
            return 5...10
        case .natural:
            return 1...3
        case .slow:
            return 1...2
        case .custom(let size, _):
            return size
        }
    }

    var delayNanoseconds: UInt64 {
        switch self {
        case .instant:
            return 0
        case .fast:
            return 2_000_000
        case .natural:
            return 5_000_000
        case .slow:
            return 15_000_000
        case .custom(_, let delay):
            return delay
        }
    }
}
