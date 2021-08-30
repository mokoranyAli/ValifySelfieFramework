//
//  CapturedImageViewController.swift
//  ValifySelfie
//
//  Created by Mohamed Korany on 25/08/2021.
//

import UIKit

// MARK: - CapturedImageViewController
//
class CapturedImageViewController: UIViewController {
  
  // MARK: - IBOutlets
  
  @IBOutlet weak var imageView: UIImageView!
  @IBOutlet weak var recaptureButton: UIButton!
  @IBOutlet weak var doneButton: UIButton!
  
  // MARK: - Properties
  
  let image: UIImage
  
  weak var delegate: ValifySelfieDelegate?
  
  // MARK: - Init
  
  init(image: UIImage) {
    self.image = image
    super.init(nibName: "CapturedImageViewController", bundle: Bundle(for: type(of: self)))
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  // MARK: - LifeCycle
  
  override func viewDidLoad() {
    super.viewDidLoad()
    configureView()
  }
}

// MARK: - IBActions
//
private extension CapturedImageViewController {
  
  @IBAction func doneButtonTapped(_ sender: Any) {
    delegate?.didFinishScan(from: self, with: .success(imageView.image ?? image)) // This is because flipped image
  }
  
  
  @IBAction func recaptureButtonTapped(_ sender: Any) {
    navigationController?.popViewController(animated: true)
  }
}

// MARK: - View's Confguration
//
private extension CapturedImageViewController {
  
  func configureView() {
    configureImageView()
    configureDoneButton()
    configureRecaptureButton()
  }
  
  func configureImageView() {
    imageView.image = image
    imageView.transform = CGAffineTransform(scaleX: -1, y: 1); //Flipped
  }
  
  func configureDoneButton() {
    doneButton.setTitle("Done", for: .normal)
  }
  
  func configureRecaptureButton() {
    recaptureButton.setTitle("Take Another Photo", for: .normal)
  }
}
