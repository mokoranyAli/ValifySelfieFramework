//
//  CapturedImageViewController.swift
//  TesApp
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
    
    imageView.image = image
    imageView.transform = CGAffineTransform(scaleX: -1, y: 1); //Flipped

  }
  
  @IBAction func doneButtonTapped(_ sender: Any) {
    delegate?.didFinishScan(from: self, with: .success(image))
  }
  
  
  @IBAction func recaptureButtonTapped(_ sender: Any) {
    navigationController?.popViewController(animated: true)
  }
}




