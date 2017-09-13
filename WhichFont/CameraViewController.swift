//
//  CameraViewController.swift
//  WhichFont
//
//  Created by Daniele on 25/07/17.
//  Copyright © 2017 nexor. All rights reserved.
//

import UIKit
import Vision
import AVKit
import TesseractOCR

extension ViewController {
    
    func prepareLiveVideo() {
        session.sessionPreset = AVCaptureSession.Preset.high
        guard let captureDevice = AVCaptureDevice.default(for: AVMediaType.video) else {
            return
        }
        
        if let deviceInput = try? AVCaptureDeviceInput(device: captureDevice) {
            let deviceOutput = AVCaptureVideoDataOutput()
            deviceOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)]
            deviceOutput.setSampleBufferDelegate(self, queue: DispatchQueue.global(qos: DispatchQoS.QoSClass.default))
            session.addInput(deviceInput)
            session.addOutput(deviceOutput)
            
            self.previewLayer = AVCaptureVideoPreviewLayer(session: session)
            self.previewLayer!.videoGravity = .resize
            self.previewLayer!.frame = self.vwCamera.bounds
            self.previewLayer!.connection?.videoOrientation = self.videoOrientationFromCurrentDeviceOrientation()
            self.vwCamera.layer.addSublayer(self.previewLayer!)
            
            session.startRunning()
        }
    }
    
    func startSession() {
        session.startRunning()
    }
    
    func stopSession() {
        session.stopRunning()
    }
    
    private func videoOrientationFromCurrentDeviceOrientation() -> AVCaptureVideoOrientation {
        switch UIApplication.shared.statusBarOrientation {
        case .portrait:
            return AVCaptureVideoOrientation.portrait
        case .landscapeLeft:
            return AVCaptureVideoOrientation.landscapeLeft
        case .landscapeRight:
            return AVCaptureVideoOrientation.landscapeRight
        case .portraitUpsideDown:
            return AVCaptureVideoOrientation.portraitUpsideDown
        default:
            return AVCaptureVideoOrientation.portrait
        }
    }
    
    private func bufferOrientationFromCurrentDeviceOrientation() -> Int32 {
        /* The intended display orientation of the image. If present, the value
         * of this key is a CFNumberRef with the same value as defined by the
         * TIFF and Exif specifications.  That is:
         *   1  =  0th row is at the top, and 0th column is on the left.
         *   2  =  0th row is at the top, and 0th column is on the right.
         *   3  =  0th row is at the bottom, and 0th column is on the right.
         *   4  =  0th row is at the bottom, and 0th column is on the left.
         *   5  =  0th row is on the left, and 0th column is the top.
         *   6  =  0th row is on the right, and 0th column is the top.
         *   7  =  0th row is on the right, and 0th column is the bottom.
         *   8  =  0th row is on the left, and 0th column is the bottom.
         * If not present, a value of 1 is assumed. */
        switch UIApplication.shared.statusBarOrientation {
        case .portrait:
            return 6
//        case .landscapeLeft:
//            return AVCaptureVideoOrientation.landscapeLeft
//        case .landscapeRight:
//            return AVCaptureVideoOrientation.landscapeRight
//        case .portraitUpsideDown:
//            return AVCaptureVideoOrientation.portraitUpsideDown
        default:
             return 6
        }
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        coordinator.animate(alongsideTransition: { (context) in
            DispatchQueue.main.async {
            self.previewLayer?.connection?.videoOrientation = self.videoOrientationFromCurrentDeviceOrientation()
            self.previewLayer?.frame = self.vwCamera.bounds //on rotation, fix bounds
            }
        }) { (context) in
            //end rotation
        }
        
        super.viewWillTransition(to: size, with: coordinator)
    }
    
    override var shouldAutorotate: Bool {
        return false
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
}

extension ViewController {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        
        var requestOptions:[VNImageOption : Any] = [:]
        
        if let camData = CMGetAttachment(sampleBuffer, kCMSampleBufferAttachmentKey_CameraIntrinsicMatrix, nil) {
            requestOptions = [.cameraIntrinsics:camData]
        }
        
        let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: CGImagePropertyOrientation(rawValue: 6)!, options: requestOptions)
        
        if self.shouldAnalyzeImage == true {
            do {
                let clImage = CIImage.init(cvImageBuffer: pixelBuffer)
                self.currentImage = clImage.toImage()
                
                if let _ = self.currentImage {
                    try imageRequestHandler.perform(self.requests)
                }
            } catch {
                print(error)
            }
        }
    }
    
    func startTextDetection() {
        let textRequest = VNDetectTextRectanglesRequest(completionHandler: self.detectTextHandler)
        textRequest.reportCharacterBoxes = true
        self.requests = [textRequest]
    }
    
    func detectTextHandler(request: VNRequest, error: Error?) {
        guard let observations = request.results as? [VNTextObservation] else {
            print("no result or wrong cast")
            return
        }
        
        guard let mainImage = self.currentImage else {
            print("no current image")
            return
        }
        
        DispatchQueue.main.async() {
            self.shouldAnalyzeImage = false
            self.vwCamera.layer.sublayers?.removeSubrange(1...)
            for sv in self.vwSnapshot.subviews {
                sv.removeFromSuperview()
            }
            self.currentSentenceFrames = []
            self.currentLetterFrames = []
            
            for obs in observations {
                self.highlightWord(box: obs)
                
//                guard let boxes = obs.characterBoxes else {
//                    continue
//                }
////                for characterBox in boxes {
////                    self.highlightLetters(box: characterBox)
////                }
            }
            
            let imgv = UIImageView(image: mainImage)
            imgv.frame = self.vwCamera.bounds
            let vcontainer = UIView(frame: self.vwCamera.bounds)
            vcontainer.addSubview(imgv)
            
            let recognition = RecognitionTypes(rawValue: Int(self.pckRecognition.selectedRow(inComponent: 0)))
            
            var detectedTexts: [String] = []
            for frame in self.currentSentenceFrames {
                var img = vcontainer.layer.asImage(rect: frame)
                
                if let rec = recognition {
                    switch rec {
                    case .grayscale:
                        img = img.g8_grayScale()
                    case .blackwhite:
                        img = img.g8_blackAndWhite()
                    }
                }
                //print(img)
                
                self.tesseract.image = img
                self.tesseract.recognize()
                
                if let s = self.tesseract.recognizedText {
                    detectedTexts.append(s)
                }
            }
            
            if detectedTexts.count > 0 {
                self.currentDetectedText = detectedTexts.joined(separator: "")
            }
            
            self.shouldAnalyzeImage = true
        }
    }
    
    func highlightWord(box: VNTextObservation) {
        guard let _ = box.characterBoxes else {
            return
        }
        
        let dim = box.boundingBox
        
        let size = self.vwCamera.frame
        let width = dim.width * size.width
        let height = dim.height * size.height
        let x = dim.origin.x * size.width
        let y = (1 - dim.origin.y) * size.height - height
        
        let layerFrame = CGRect(x: x, y: y, width: width, height: height)
        let visibleFrame = self.vwCamera.convert(layerFrame, to: self.vwVisibleArea)
        
        if self.vwVisibleArea.frame.contains(visibleFrame) {
            let outlineb = CALayer()
            outlineb.frame = layerFrame
            outlineb.borderWidth = 2.0
            outlineb.borderColor = UIColor.red.cgColor
            
            self.vwCamera.layer.addSublayer(outlineb)
            
            self.currentSentenceFrames.append(layerFrame)
        }
    }
    
    func highlightLetters(box: VNRectangleObservation) {
        let dim = box.boundingBox
        
        let size = self.vwCamera.frame
        let width = dim.width * size.width
        let height = dim.height * size.height
        let x = dim.origin.x * size.width
        let y = (1 - dim.origin.y) * size.height - height
        
        let layerFrame = CGRect(x: x, y: y, width: width, height: height)
        let visibleFrame = self.vwCamera.convert(layerFrame, to: self.vwVisibleArea)
        
        if self.vwVisibleArea.frame.contains(visibleFrame) {
            let outlineb = CALayer()
            outlineb.frame = layerFrame
            outlineb.borderWidth = 2.0
            outlineb.borderColor = UIColor.green.cgColor
            
            self.vwCamera.layer.addSublayer(outlineb)
            
            //self.currentLetterFrames.append(layerFrame)
        }
    }
    
}

extension ViewController {
    
    func shouldCancelImageRecognition(for tesseract: G8Tesseract!) -> Bool {
        return false
    }
}
