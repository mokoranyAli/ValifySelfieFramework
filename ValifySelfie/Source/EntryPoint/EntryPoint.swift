//
//  EntryPoint.swift
//  ValifySelfie
//
//  Created by Mohamed Korany on 29/08/2021.
//

import UIKit


/// Show Valify FrameWork screen to take selfie
/// - Parameters:
///   - presenter: Present View Controller
///   - style: Presentation Style like push view controller or present view controller
///   - animated: Indicates presentation view controller animate or not
///
public func showValify(from presenter: (UIViewController & ValifySelfieDelegate), with style: PresentationStyle = .push, animated: Bool = true) {
  let viewController = CameraViewController()
  viewController.delegate = presenter
  
  switch style {
  case .push:
    presenter.navigationController?.pushViewController(viewController, animated: animated)
  case .present:
    presenter.present(UINavigationController(rootViewController: viewController), animated: animated)
  }
}

// MARK: - Presentation Style
//
public enum PresentationStyle {
  
  case push
  case present
}
