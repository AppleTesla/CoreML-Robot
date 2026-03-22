import Foundation
import CoreBluetooth
import Observation

/// Manages BLE connection to the ESP32 robot
@MainActor
@Observable
final class BLEManager: NSObject {
    // MARK: - UUIDs (must match firmware)
    static let serviceUUID = CBUUID(string: "12345678-1234-1234-1234-123456789abc")
    static let commandCharUUID = CBUUID(string: "12345678-1234-1234-1234-123456789001")
    static let statusCharUUID = CBUUID(string: "12345678-1234-1234-1234-123456789002")
    static let configCharUUID = CBUUID(string: "12345678-1234-1234-1234-123456789003")

    // MARK: - Observable state
    var isScanning = false
    var isConnected = false
    var robotState = RobotState()
    var discoveredPeripherals: [CBPeripheral] = []

    // MARK: - Async status stream keyed by peripheral UUID
    private var statusContinuations: [UUID: AsyncStream<RobotState>.Continuation] = [:]

    // MARK: - Private
    private var centralManager: CBCentralManager!
    private var robotPeripheral: CBPeripheral?
    private var commandCharacteristic: CBCharacteristic?
    private var statusCharacteristic: CBCharacteristic?

    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: .main)
    }

    func startScanning() {
        guard centralManager.state == .poweredOn else { return }
        discoveredPeripherals.removeAll()
        isScanning = true
        centralManager.scanForPeripherals(
            withServices: [Self.serviceUUID],
            options: [CBCentralManagerScanOptionAllowDuplicatesKey: false]
        )
    }

    func stopScanning() {
        centralManager.stopScan()
        isScanning = false
    }

    func connect(to peripheral: CBPeripheral) {
        stopScanning()
        robotPeripheral = peripheral
        peripheral.delegate = self
        centralManager.connect(peripheral, options: nil)
    }

    func disconnect() {
        if let peripheral = robotPeripheral {
            centralManager.cancelPeripheralConnection(peripheral)
        }
    }

    func send(_ command: GraspCommand) {
        guard let char = commandCharacteristic, let peripheral = robotPeripheral else { return }
        let data = RobotCommandProtocol.serialize(command)
        peripheral.writeValue(data, for: char, type: .withResponse)
    }

    func sendWithoutResponse(_ command: GraspCommand) {
        guard let char = commandCharacteristic, let peripheral = robotPeripheral else { return }
        let data = RobotCommandProtocol.serialize(command)
        peripheral.writeValue(data, for: char, type: .withoutResponse)
    }

    /// Returns an AsyncStream of RobotState updates for a given peripheral
    func statusStream(for peripheralID: UUID) -> AsyncStream<RobotState> {
        AsyncStream { continuation in
            statusContinuations[peripheralID] = continuation
            continuation.onTermination = { [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.statusContinuations.removeValue(forKey: peripheralID)
                }
            }
        }
    }
}

// MARK: - CBCentralManagerDelegate
extension BLEManager: CBCentralManagerDelegate {
    nonisolated func centralManagerDidUpdateState(_ central: CBCentralManager) {
        Task { @MainActor in
            if central.state == .poweredOn {
                startScanning()
            }
        }
    }

    nonisolated func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral,
                        advertisementData: [String: Any], rssi RSSI: NSNumber) {
        Task { @MainActor in
            if !discoveredPeripherals.contains(where: { $0.identifier == peripheral.identifier }) {
                discoveredPeripherals.append(peripheral)
            }
            // Auto-connect to the first robot found
            if peripheral.name == "CoreML-Robot" {
                connect(to: peripheral)
            }
        }
    }

    nonisolated func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        Task { @MainActor in
            isConnected = true
            peripheral.discoverServices([Self.serviceUUID])
        }
    }

    nonisolated func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        Task { @MainActor in
            isConnected = false
            robotState.isConnected = false
            commandCharacteristic = nil
            statusCharacteristic = nil
            // Finish the stream for this peripheral
            statusContinuations.removeValue(forKey: peripheral.identifier)?.finish()
            // Auto-reconnect
            startScanning()
        }
    }
}

// MARK: - CBPeripheralDelegate
extension BLEManager: CBPeripheralDelegate {
    nonisolated func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        Task { @MainActor in
            guard let services = peripheral.services else { return }
            for service in services {
                peripheral.discoverCharacteristics(
                    [Self.commandCharUUID, Self.statusCharUUID, Self.configCharUUID],
                    for: service
                )
            }
        }
    }

    nonisolated func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        Task { @MainActor in
            guard let characteristics = service.characteristics else { return }
            for char in characteristics {
                switch char.uuid {
                case Self.commandCharUUID:
                    commandCharacteristic = char
                case Self.statusCharUUID:
                    statusCharacteristic = char
                    peripheral.setNotifyValue(true, for: char) // Subscribe to status updates
                default:
                    break
                }
            }
        }
    }

    nonisolated func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        Task { @MainActor in
            guard characteristic.uuid == Self.statusCharUUID,
                  let data = characteristic.value,
                  let state = RobotCommandProtocol.parseStatus(data) else { return }
            robotState = state
            // Emit to the async stream for this peripheral
            statusContinuations[peripheral.identifier]?.yield(state)
        }
    }
}
