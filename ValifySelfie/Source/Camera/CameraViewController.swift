//
//  CameraViewController.swift
//  ValifySelfie
//
//  Created by Mohamed Korany on 25/08/2021.
//

import UIKit
import AVFoundation
import Vision

// MARK: - CameraViewController
//
class CameraViewController: UIViewController {
  
  // MARK: - Views
  
  private var captureButton: UIButton!
  private var previewLayer : AVCaptureVideoPreviewLayer!
  
  // MARK: - Properties
  
  private var captureSession : AVCaptureSession!
  private var frontCamera : AVCaptureDevice!
  private var frontInput : AVCaptureInput!
  private var videoOutput : AVCaptureVideoDataOutput!
  private var sampleBuffer: CMSampleBuffer!
  private var takingAPicture = false
  private var drawings: [CAShapeLayer] = []
  
  weak var delegate: ValifySelfieDelegate?
  
  // MARK: - Life Cycle
  
  override func viewDidLoad() {
    super.viewDidLoad()
    configureView()
  }
  
  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    
    checkPermissions()
  }
}

// MARK: - Camera Setup
//
private extension CameraViewController {
  
  func setupAndStartCaptureSession() {
    
    //init session
    captureSession = AVCaptureSession()
    //start configuration
    captureSession.beginConfiguration()
    
    //session specific configuration
    if captureSession.canSetSessionPreset(.photo) {
      captureSession.sessionPreset = .photo
    }
    captureSession.automaticallyConfiguresCaptureDeviceForWideColor = true
    
    //setup inputs
    self.setupInputs()
    self.setupPreviewLayer()
    
    //setup output
    self.setupOutput()
    
    //commit configuration
    self.captureSession.commitConfiguration()
    //start running it
    self.captureSession.startRunning()
  }
  
  func setupInputs() {
    
    //get front camera
    guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) else {
      didReceiveError("no front camera")
      return
    }
    
    frontCamera = device
    guard let fInput = try? AVCaptureDeviceInput(device: frontCamera) else {
      didReceiveError("could not create input device from front camera")
      return
    }
    frontInput = fInput
    if !captureSession.canAddInput(frontInput) {
      didReceiveError("could not add front camera input to capture session")
    }
    
    //connect back camera input to session
    captureSession.addInput(fInput)
  }
  
  func setupOutput(){
    videoOutput = AVCaptureVideoDataOutput()
    let videoQueue = DispatchQueue(label: "videoQueue", qos: .userInteractive)
    videoOutput.setSampleBufferDelegate(self, queue: videoQueue)
    
    if captureSession.canAddOutput(videoOutput) {
      captureSession.addOutput(videoOutput)
    } else {
      didReceiveError("could not add video output")
    }
    
    videoOutput.connections.first?.videoOrientation = .portrait
  }
}

// MARK: - Actions
//
extension CameraViewController {
  
  @objc func takePicktureTapped(_ sender: UIButton?) {
    takingAPicture = true
    takePicture()
  }
}

// MARK: - View's Configuration
//
extension CameraViewController {
  
  func configureView() {
    configureMainView()
    configureCaptureButton()
  }
  
  func configureMainView() {
    title = "Valify Framework"
    view.backgroundColor = .black
  }
  
  func configureCaptureButton() {
    captureButton = UIButton()
    captureButton.backgroundColor = .white
    captureButton.layer.cornerRadius = 25
    captureButton.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(captureButton)
    NSLayoutConstraint.activate([
      captureButton.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
      captureButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -10),
      captureButton.widthAnchor.constraint(equalToConstant: 50),
      captureButton.heightAnchor.constraint(equalToConstant: 50),
    ])
    
    captureButton.addTarget(self, action: #selector(takePicktureTapped(_:)), for: .touchUpInside)
  }
  
  func setupPreviewLayer() {
    previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
    view.layer.insertSublayer(previewLayer, below: navigationController?.view.layer)
    previewLayer.frame = self.view.layer.frame
  }
}

// MARK: - Private Handlers
//
private extension CameraViewController {
  
  func checkPermissions() {
    let cameraAuthStatus =  AVCaptureDevice.authorizationStatus(for: .video)
    
    switch cameraAuthStatus {
    case .authorized:
      setupAndStartCaptureSession()
      
    case .notDetermined, .denied, .restricted:
      AVCaptureDevice.requestAccess(for: .video) { authorized in
        self.handleRequestCameraAccess(isAuthorized: authorized)
      }
    @unknown default:
      return
    }
  }
  
  func didReceiveError(_ message: String) {
    DispatchQueue.main.async { [weak self] in
      self?.showToast(message: message)
    }
  }
  
  func handleRequestCameraAccess(isAuthorized: Bool) {
    DispatchQueue.main.async {
      isAuthorized ? self.setupAndStartCaptureSession() : self.didReceiveError("Access Camera Not Authorized")
    }
  }
  
  func takePicture() {
    guard takingAPicture, sampleBuffer != nil else {
      return
    }
    
    // Try and get a CVImageBuffer out of the sample buffer
    guard let cvBuffer = CMSampleBufferGetImageBuffer(self.sampleBuffer) else {
      return
    }
    
    // Get a CIImage out of the CVImageBuffer
    let ciImage = CIImage(cvImageBuffer: cvBuffer)
    
    //get UIImage out of CIImage
    let uiImage = UIImage(ciImage: ciImage).withHorizontallyFlippedOrientation()
    
    
    let options = [CIDetectorAccuracy: CIDetectorAccuracyHigh]
    let faceDetector = CIDetector(ofType: CIDetectorTypeFace, context: nil, options: options)!
    let faces = faceDetector.features(in: ciImage)
    
    guard faces.first != nil  else {
      
      self.takingAPicture = false
      self.didReceiveError("No Face Found")
      return
    }
    
    guard faces.count == 1 else {
      self.takingAPicture = false
      self.didReceiveError("A lot of faces are detected..! \n We need only one face")
      return
    }
    
    self.takingAPicture = false
    self.showDetailsScreen(with: uiImage)
  }
  
  func showDetailsScreen(with image: UIImage) {
    let detailsScreen = CapturedImageViewController(image: image)
    detailsScreen.delegate = delegate
    self.navigationController?.pushViewController(detailsScreen, animated: true)
  }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate Conformance
//
extension CameraViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
  
  func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
    
    guard let frame = CMSampleBufferGetImageBuffer(sampleBuffer) else {
      debugPrint("unable to get image from sample buffer")
      return
    }
    
    self.detectFace(in: frame)
    self.sampleBuffer = sampleBuffer
  }
}

// MARK: - Face Detection Handlers
//
private extension CameraViewController {
  
  func detectFace(in image: CVPixelBuffer) {
    let faceDetectionRequest = VNDetectFaceLandmarksRequest(completionHandler: { (request: VNRequest, error: Error?) in
      DispatchQueue.main.async {
        if let results = request.results as? [VNFaceObservation] {
          self.handleFaceDetectionResults(results)
        } else {
          self.clearDrawings()
        }
      }
    })
    let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: image, orientation: .leftMirrored, options: [:])
    try? imageRequestHandler.perform([faceDetectionRequest])
  }
  
  func handleFaceDetectionResults(_ observedFaces: [VNFaceObservation]) {
    
    self.clearDrawings()
    let facesBoundingBoxes: [CAShapeLayer] = observedFaces.flatMap({ (observedFace: VNFaceObservation) -> [CAShapeLayer] in
      let faceBoundingBoxOnScreen = self.previewLayer.layerRectConverted(fromMetadataOutputRect: observedFace.boundingBox)
      let faceBoundingBoxPath = CGPath(rect: faceBoundingBoxOnScreen, transform: nil)
      let faceBoundingBoxShape = CAShapeLayer()
      faceBoundingBoxShape.path = faceBoundingBoxPath
      faceBoundingBoxShape.fillColor = UIColor.clear.cgColor
      faceBoundingBoxShape.strokeColor = UIColor.yellow.cgColor
      var newDrawings = [CAShapeLayer]()
      newDrawings.append(faceBoundingBoxShape)
      if let landmarks = observedFace.landmarks {
        newDrawings = newDrawings + self.drawFaceFeatures(landmarks, screenBoundingBox: faceBoundingBoxOnScreen)
      }
      return newDrawings
    })
    facesBoundingBoxes.forEach({ faceBoundingBox in self.view.layer.addSublayer(faceBoundingBox) })
    self.drawings = facesBoundingBoxes
  }
  
  func clearDrawings() {
    self.drawings.forEach({ drawing in drawing.removeFromSuperlayer() })
  }
  
  func drawFaceFeatures(_ landmarks: VNFaceLandmarks2D, screenBoundingBox: CGRect) -> [CAShapeLayer] {
    var faceFeaturesDrawings: [CAShapeLayer] = []
    if let leftEye = landmarks.leftEye {
      let eyeDrawing = self.drawEye(leftEye, screenBoundingBox: screenBoundingBox)
      faceFeaturesDrawings.append(eyeDrawing)
    }
    if let rightEye = landmarks.rightEye {
      let eyeDrawing = self.drawEye(rightEye, screenBoundingBox: screenBoundingBox)
      faceFeaturesDrawings.append(eyeDrawing)
    }
    // draw other face features here
    return faceFeaturesDrawings
  }
  
  func drawEye(_ eye: VNFaceLandmarkRegion2D, screenBoundingBox: CGRect) -> CAShapeLayer {
    let eyePath = CGMutablePath()
    let eyePathPoints = eye.normalizedPoints
      .map({ eyePoint in
        CGPoint(
          x: eyePoint.y * screenBoundingBox.height + screenBoundingBox.origin.x,
          y: eyePoint.x * screenBoundingBox.width + screenBoundingBox.origin.y)
      })
    eyePath.addLines(between: eyePathPoints)
    eyePath.closeSubpath()
    let eyeDrawing = CAShapeLayer()
    eyeDrawing.path = eyePath
    eyeDrawing.fillColor = UIColor.clear.cgColor
    eyeDrawing.strokeColor = UIColor.yellow.cgColor
    
    return eyeDrawing
  }
}
