//
//  BarcodeScannerView.swift
//  lms
//
//  Created by Diptayan Jash on 24/04/25.
//

import Foundation
import SwiftUI
import AVFoundation

struct BarcodeScannerView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var scannedCode: String
    @State private var isTorchOn = false
    let onScanComplete: (String) async -> Void
    
    var body: some View {
        ZStack {
            BarcodeScannerRepresentable(scannedCode: $scannedCode, isTorchOn: $isTorchOn, didScan: { code in
                Task {
                    await onScanComplete(code)
                    dismiss()
                }
            })
            .ignoresSafeArea()
            
            VStack {
                // Top header
                HStack {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.black.opacity(0.6))
                            .clipShape(Circle())
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        isTorchOn.toggle()
                    }) {
                        Image(systemName: isTorchOn ? "flashlight.on.fill" : "flashlight.off.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.black.opacity(0.6))
                            .clipShape(Circle())
                    }
                }
                .padding()
                
                Spacer()
                
                // Scanning indicator and instructions
                VStack(spacing: 20) {
                    Rectangle()
                        .stroke(Color.blue, lineWidth: 3)
                        .frame(width: 250, height: 125)
                        .overlay(
                            Image(systemName: "barcode.viewfinder")
                                .font(.system(size: 60))
                                .foregroundColor(.blue.opacity(0.5))
                        )
                    
                    Text("Position the barcode in the frame")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.black.opacity(0.6))
                        .cornerRadius(10)
                }
                
                Spacer()
                
                // Manual entry button
                Button(action: {
                    dismiss()
                }) {
                    Text("Enter ISBN Manually")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .cornerRadius(16)
                        .padding(.horizontal)
                        .padding(.bottom, 30)
                }
            }
        }
    }
}

struct BarcodeScannerRepresentable: UIViewControllerRepresentable {
    @Binding var scannedCode: String
    @Binding var isTorchOn: Bool
    var didScan: (String) -> Void
    
    func makeUIViewController(context: Context) -> UIViewController {
        let viewController = BarcodeScannerViewController()
        viewController.delegate = context.coordinator
        return viewController
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        if let viewController = uiViewController as? BarcodeScannerViewController {
            viewController.toggleTorch(isOn: isTorchOn)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, BarcodeScannerViewControllerDelegate {
        var parent: BarcodeScannerRepresentable
        
        init(_ parent: BarcodeScannerRepresentable) {
            self.parent = parent
        }
        
        func didScanBarcode(code: String) {
            parent.scannedCode = code
            parent.didScan(code)
        }
    }
}

protocol BarcodeScannerViewControllerDelegate: AnyObject {
    func didScanBarcode(code: String)
}

class BarcodeScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    weak var delegate: BarcodeScannerViewControllerDelegate?
    
    private var captureSession: AVCaptureSession!
    private var previewLayer: AVCaptureVideoPreviewLayer!
    private var device: AVCaptureDevice?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCaptureSession()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if captureSession?.isRunning == false {
            DispatchQueue.global(qos: .background).async {
                self.captureSession.startRunning()
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if captureSession?.isRunning == true {
            captureSession.stopRunning()
        }
    }
    
    private func setupCaptureSession() {
        captureSession = AVCaptureSession()
        
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else { return }
        device = videoCaptureDevice
        
        let videoInput: AVCaptureDeviceInput
        
        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            return
        }
        
        if captureSession.canAddInput(videoInput) {
            captureSession.addInput(videoInput)
        } else {
            return
        }
        
        let metadataOutput = AVCaptureMetadataOutput()
        
        if captureSession.canAddOutput(metadataOutput) {
            captureSession.addOutput(metadataOutput)
            
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.ean13, .ean8]
        } else {
            return
        }
        
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = view.layer.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        
        DispatchQueue.global(qos: .background).async {
            self.captureSession.startRunning()
        }
    }
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        if let metadataObject = metadataObjects.first {
            guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
            guard let stringValue = readableObject.stringValue else { return }
            
            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
            
            // Check if the code is a valid ISBN (EAN-13)
            if stringValue.count == 13 && (stringValue.hasPrefix("978") || stringValue.hasPrefix("979")) {
                captureSession.stopRunning()
                delegate?.didScanBarcode(code: stringValue)
            }
        }
    }
    
    func toggleTorch(isOn: Bool) {
        guard let device = device else { return }
        
        if device.hasTorch {
            do {
                try device.lockForConfiguration()
                device.torchMode = isOn ? .on : .off
                device.unlockForConfiguration()
            } catch {
                print("Torch could not be used")
            }
        }
    }
}
