//
//  ViewController.swift
//  KoshianLED
//
//  Created by Kazuo Tsubaki on 2018/03/08.
//  Copyright © 2018年 Kazuo Tsubaki. All rights reserved.
//

import UIKit
import CoreBluetooth

class ViewController: UIViewController {

    var centralManager: CBCentralManager!
    var konashi: CBPeripheral!
    var konashiService: CBService!
    var pioSetting : CBCharacteristic!
    var pio: CBCharacteristic!
    var blinking: Bool = false
    @IBOutlet weak var connectButton: UIButton!
    @IBOutlet weak var blinkButton: UIButton!
    var blinkTimer: Timer!
    var value: Bool = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        blinkButton.isHidden = true
        
        centralManager = CBCentralManager(delegate: self, queue: nil, options:nil)
        
    }

    @IBAction func connect(_ sender: Any) {
        if konashi != nil {
            centralManager.cancelPeripheralConnection(konashi)
            konashi = nil
        } else {
            centralManager.scanForPeripherals(withServices: nil, options: nil)
        }
    }
    
    @objc func startBlinking(_ sender: Any) {
        if !blinking {
            blinkButton.setTitle("Stop", for: UIControlState.normal)
            blinkButton.addTarget(self, action: #selector(stopBlinking(_:)), for: UIControlEvents.touchUpInside)
            blinking = true
            blinkTimer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true, block: {_ in
                self.digitalWrite(pin:1, value:self.value ? 1 : 0)
                self.value = !self.value
            })
            blinkTimer.fire()
        }
    }
    
    @objc func stopBlinking(_ sender: Any) {
        if blinking {
            blinkButton.setTitle("Blink", for: UIControlState.normal)
            blinkButton.addTarget(self, action: #selector(startBlinking(_:)), for: UIControlEvents.touchUpInside)
            blinking = false
            self.digitalWrite(pin:1, value:0)
            blinkTimer.invalidate()
        }
    }
    
    func digitalWrite(pin: Int, value: Int) -> Void {
        var value = UInt8(0x01 << value)
        let data = Data(buffer: UnsafeBufferPointer(start: &value, count: MemoryLayout<UInt8>.size))
        konashi.writeValue(data, for: pio, type: CBCharacteristicWriteType.withoutResponse)
    }
}

extension ViewController: CBCentralManagerDelegate {
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            print("powerOn")
        default:
            print("central.state = \(central.state)")
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        let localName = advertisementData["kCBAdvDataLocalName"] as? String
        if localName == "konashi2-f02226" {
            central.stopScan()
            print("\(localName ?? "") found")
            konashi = peripheral
            print("connecting")
            central.connect(konashi, options: nil)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("connected")
        konashi.delegate = self
        konashiService = nil
        konashi.discoverServices(nil)
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("disconnected")
        konashi = nil
        konashiService = nil
        pioSetting = nil
        pio = nil
        
        connectButton.setTitle("Connect", for: UIControlState.normal)
        blinkButton.isHidden = true
    }
}

extension ViewController: CBPeripheralDelegate {
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        for service in peripheral.services! {
            if service.uuid.uuidString == "229BFF00-03FB-40DA-98A7-B0DEF65C2D4B" {
                print("found service")
                konashiService = service
                konashi.discoverCharacteristics(nil, for: konashiService)
                break
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        for c in service.characteristics! {
            if c.uuid.uuidString == "229B3002-03FB-40DA-98A7-B0DEF65C2D4B" {
                pio = c
            }
            if c.uuid.uuidString == "229B3000-03FB-40DA-98A7-B0DEF65C2D4B" {
                pioSetting = c
            }
        }
        
        var pinMode = UInt8(0x01 << 1)
        let data = Data(buffer: UnsafeBufferPointer(start: &pinMode, count: MemoryLayout<UInt8>.size))
        konashi.writeValue(data, for: pioSetting, type: CBCharacteristicWriteType.withoutResponse)

        print("pioSetting \(pioSetting.uuid)")
        print("pio \(pio.uuid)")
        connectButton.setTitle("Disconnect", for: UIControlState.normal)
        blinkButton.isHidden = false
        blinkButton.setTitle("Blink", for: UIControlState.normal)
        blinkButton.addTarget(self, action: #selector(startBlinking(_:)), for: UIControlEvents.touchUpInside)
        blinking = false
   }
}

