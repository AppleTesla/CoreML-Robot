import Foundation
import CoreBluetooth
import Combine

/// Manages BLE connection to the ESP32 robot
class BLEManager: NSObject, ObservableObject {
    // MARK: - UUIDs (must match firmware)
    static let serviceUUID = CBUUID(string: "12345678-1234-1234-1234-123456789abc")
    static let commandCharUUID = CBUUID(string: "12345678-1234-1234-1234-123456789001")
    static let statusCharUUID = CBUUID(string: "12345678-1234-1234-1234-123456789002")
    static let configCharUUID = CBUUID(string: "12345678-1234-1234-1234-123456789003")

    // MARK: - Published state
    @Published var isScanning = false
    @Published var isConnected = false
    @Published var robotState = RobotState()
    @Published var discoveredPeripherals: [CBPeripheral] = []

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
}

// MARK: - CBCentralManagerDelegate
extension BLEManager: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            startScanning()
        }
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral,
                        advertisementData: [String: Any], rssi RSSI: NSNumber) {
        if !discoveredPeripherals.contains(where: { $0.identifier == peripheral.identifier }) {
            discoveredPeripherals.append(peripheral)
        }
        // Auto-connect to the first robot found
        if peripheral.name == "CoreML-Robot" {
            connect(to: peripheral)
        }
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        isConnected = true
        peripheral.discoverServices([Self.serviceUUID])
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        isConnected = false
        robotState.isConnected = false
        commandCharacteristic = nil
        statusCharacteristic = nil
        // Auto-reconnect
        startScanning()
    }
}

// MARK: - CBPeripheralDelegate
extension BLEManager: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }
        for service in services {
            peripheral.discoverCharacteristics(
                [Self.commandCharUUID, Self.statusCharUUID, Self.configCharUUID],
                for: service
            )
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
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

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard characteristic.uuid == Self.statusCharUUID,
              let data = characteristic.value,
              let state = RobotCommandProtocol.parseStatus(data) else { return }
        robotState = state
    }
}
