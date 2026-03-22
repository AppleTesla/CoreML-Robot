import Foundation
import Observation

/// States for the pick-and-place task
enum PickPlaceState: String, CaseIterable, Sendable {
    case idle
    case scanning
    case targetAcquired
    case approaching
    case grasping
    case lifting
    case transporting
    case placing
    case releasing
    case returning
}

/// Orchestrates the full pick-and-place cycle
@MainActor
@Observable
final class PickPlaceStateMachine {
    var state: PickPlaceState = .idle
    var targetObject: DetectedObject?
    var statusMessage: String = "Idle"

    private let bleManager: BLEManager
    private let graspPlanner = GraspPlanner()
    private var commandQueue: [GraspCommand] = []
    private var executionTask: Task<Void, Never>?
    private let commandInterval: Duration = .milliseconds(1500)

    init(bleManager: BLEManager) {
        self.bleManager = bleManager
    }

    /// Start scanning for objects to pick up
    func startPickAndPlace() {
        guard state == .idle else { return }
        transition(to: .scanning)
    }

    /// Stop the current operation and return home
    func stop() {
        executionTask?.cancel()
        executionTask = nil
        commandQueue.removeAll()
        bleManager.send(.stop)
        transition(to: .idle)
    }

    /// Called when new detections arrive from the vision pipeline
    func onDetections(_ detections: [DetectedObject], imageSize: CGSize) {
        guard state == .scanning else { return }

        // Pick the highest-confidence detection
        guard let best = detections.max(by: { $0.confidence < $1.confidence }) else { return }

        targetObject = best
        transition(to: .targetAcquired)

        // Plan the grasp
        let pickCommands = graspPlanner.planGrasp(for: best, imageSize: imageSize)
        let placeCommands = graspPlanner.planPlace()

        guard !pickCommands.isEmpty else {
            statusMessage = "Object unreachable"
            transition(to: .idle)
            return
        }

        // Queue all commands
        commandQueue = pickCommands + placeCommands
        executeCommands()
    }

    // MARK: - Private

    private func transition(to newState: PickPlaceState) {
        state = newState
        statusMessage = stateDescription(newState)
        print("PickPlace: \(newState.rawValue)")
    }

    private func executeCommands() {
        executionTask = Task { [weak self] in
            while let self, !self.commandQueue.isEmpty, !Task.isCancelled {
                let command = self.commandQueue.removeFirst()
                self.bleManager.send(command)
                self.updateStateForCommand(command)

                try? await Task.sleep(for: self.commandInterval)
            }

            if let self, !Task.isCancelled {
                self.transition(to: .idle)
            }
        }
    }

    private func updateStateForCommand(_ command: GraspCommand) {
        switch command.type {
        case .moveAll:
            if state == .targetAcquired || state == .scanning {
                transition(to: .approaching)
            } else if state == .grasping {
                transition(to: .lifting)
            } else if state == .lifting {
                transition(to: .transporting)
            } else if state == .transporting {
                transition(to: .placing)
            }
        case .gripper:
            if command.gripperPercent == 0 {
                transition(to: .grasping)
            } else {
                transition(to: .releasing)
            }
        case .home:
            transition(to: .returning)
        default:
            break
        }
    }

    private func stateDescription(_ state: PickPlaceState) -> String {
        switch state {
        case .idle: return "Idle"
        case .scanning: return "Scanning for objects..."
        case .targetAcquired: return "Target acquired: \(targetObject?.label ?? "unknown")"
        case .approaching: return "Approaching target..."
        case .grasping: return "Closing gripper..."
        case .lifting: return "Lifting object..."
        case .transporting: return "Transporting..."
        case .placing: return "Placing object..."
        case .releasing: return "Releasing..."
        case .returning: return "Returning home..."
        }
    }
}
