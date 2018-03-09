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

    var blinking: Bool = false
    @IBOutlet weak var connectButton: UIButton!
    @IBOutlet weak var blinkButton: UIButton!
    var blinkTimer: Timer!
    var value: Bool = true
    @IBOutlet weak var speedRangeController: UISegmentedControl!
    var koshian: Koshian!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        blinkButton.isHidden = true
        speedRangeController.isHidden = true
        koshian = Koshian(localName: "konashi2-f02226")
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.koshianReady(notif:)), name: KoshianConstants.KoshianConnected, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.koshianNotReady(notif:)), name: KoshianConstants.KoshianDisconnected, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.koshianTimeout(notif:)), name: KoshianConstants.KoshianConnectionTimeout, object: nil)
    }

    @IBAction func connect(_ sender: Any) {
        if koshian.connected {
            koshian.digitalWrite(pin: KoshianConstants.DigitalIO5, value: KoshianConstants.LOW)
            koshian.disconnect()
        } else {
            koshian.connect()
        }
    }
    
    @objc func koshianReady(notif: Notification) {
        koshian.pinMode(pin: KoshianConstants.DigitalIO1, mode: KoshianConstants.PinModeOutput)
        koshian.pinMode(pin: KoshianConstants.DigitalIO3, mode: KoshianConstants.PinModeOutput)
        koshian.pinMode(pin: KoshianConstants.DigitalIO5, mode: KoshianConstants.PinModeOutput)
        koshian.digitalWrite(pin: KoshianConstants.DigitalIO5, value: KoshianConstants.HIGH)
        connectButton.setTitle("Disconnect", for: UIControlState.normal)
        blinkButton.addTarget(self, action: #selector(startBlinking(_:)), for: UIControlEvents.touchUpInside)
        blinkButton.isHidden = false
        speedRangeController.isHidden = false
    }
    
    @objc func koshianNotReady(notif: Notification) {
        connectButton.setTitle("Connect", for: UIControlState.normal)
        blinkButton.isHidden = true
        speedRangeController.isHidden = true
    }
    
    @objc func koshianTimeout(notif: Notification) {
        let alert = UIAlertController(title: "Koshian", message: "Connection timeout", preferredStyle: UIAlertControllerStyle.alert)
        let defaultAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.default) { (action) in
        }
        alert.addAction(defaultAction)
        self.present(alert, animated: true) {
        }
    }
    
    @objc func startBlinking(_ sender: Any) {
        if !blinking {
            blinkButton.setTitle("Stop", for: UIControlState.normal)
            blinkButton.addTarget(self, action: #selector(stopBlinking(_:)), for: UIControlEvents.touchUpInside)
            blinking = true
            blinkTimer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true, block: {_ in
                switch self.speedRangeController.selectedSegmentIndex {
                case 0:
                    self.koshian.digitalWrite(pin: KoshianConstants.DigitalIO3, value: 1)
                    self.koshian.digitalWrite(pin: KoshianConstants.DigitalIO1, value: 0)
               case 1:
                    self.koshian.digitalWrite(pin: KoshianConstants.DigitalIO3, value: self.value ? 1 : 0)
                    self.koshian.digitalWrite(pin: KoshianConstants.DigitalIO1, value: 0)
                    self.value = !self.value
                case 2:
                    self.koshian.digitalWrite(pin: KoshianConstants.DigitalIO3, value: self.value ? 1 : 0)
                    self.koshian.digitalWrite(pin: KoshianConstants.DigitalIO1, value: self.value ? 0 : 1)
                    self.value = !self.value
                default:
                    self.koshian.digitalWrite(pin: KoshianConstants.DigitalIO3, value: 0)
                    self.koshian.digitalWrite(pin: KoshianConstants.DigitalIO1, value: 0)
                    self.value = true
                }
            })
            blinkTimer.fire()
        }
    }
    
    private func rescheduleTimer() {
        if !blinking && blinkTimer != nil {
            blinkTimer.invalidate()
            blinkTimer.fire()
        }
    }
    
    @objc func stopBlinking(_ sender: Any) {
        if blinking {
            blinkButton.setTitle("Blink", for: UIControlState.normal)
            blinkButton.addTarget(self, action: #selector(startBlinking(_:)), for: UIControlEvents.touchUpInside)
            blinking = false
            self.koshian.digitalWrite(pin: KoshianConstants.DigitalIO3, value: 0)
            self.koshian.digitalWrite(pin: KoshianConstants.DigitalIO1, value: 0)
            blinkTimer.invalidate()
        }
    }
    
    @IBAction func changeSpeedRange(_ sender: UISegmentedControl) {
        rescheduleTimer()
    }
    
}



