import Foundation

public protocol StreamingTextDelegate: AnyObject {
    func streamingHandler(_ handler: StreamingTextHandler, didUpdateContent content: String)
    func streamingHandler(_ handler: StreamingTextHandler, didCompleteWithContent content: String)
    func streamingHandler(_ handler: StreamingTextHandler, didFailWithError error: Error)
}
