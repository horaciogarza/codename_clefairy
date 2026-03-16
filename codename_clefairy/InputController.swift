import SpriteKit

protocol InputControllerDelegate: AnyObject {
    func inputDidReceiveEmoji(_ emoji: String, node: SKNode)
    func inputSequenceComplete()
}

class InputController {
    weak var delegate: InputControllerDelegate?

    private var expectedCount: Int = 0
    private var receivedCount: Int = 0
    private var isLocked: Bool = true

    func prepare(expectedSequenceLength: Int) {
        expectedCount = expectedSequenceLength
        receivedCount = 0
        isLocked = false
    }

    func lock() {
        isLocked = true
    }

    var isAcceptingInput: Bool {
        return !isLocked && receivedCount < expectedCount
    }

    func handleTouch(emoji: String, node: SKNode) {
        guard isAcceptingInput else { return }

        receivedCount += 1
        delegate?.inputDidReceiveEmoji(emoji, node: node)

        if receivedCount >= expectedCount {
            isLocked = true
            delegate?.inputSequenceComplete()
        }
    }
}
