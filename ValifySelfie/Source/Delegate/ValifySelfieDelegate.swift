//
//  ValifySelfieDelegate.swift
//  ValifySelfie
//
//  Created by Mohamed Korany on 29/08/2021.
//

import UIKit

public protocol ValifySelfieDelegate: class {
  func didFinishScan(from viewController: UIViewController, with result: Result<UIImage, Error>)
}
