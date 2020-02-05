//
//  File.swift
//  NearbyWeather
//
//  Created by Erik Maximilian Martens on 01.02.20.
//  Copyright © 2020 Erik Maximilian Martens. All rights reserved.
//

import UIKit

// MARK: - Step

protocol StepProtocol {
  static var identifier: String { get }
}

enum Step: StepProtocol {
  static var identifier: String {
    return "Step"
  }
  
  case none
}

// MARK: - Coordinator

enum NextCoordinator {
  case none
  case single(Coordinator)
  case multiple([Coordinator])
}

protocol CoordinatorProtocol {
  var parentCoordinator: Coordinator? { get }
  var childCoordinators: [Coordinator] { get }
  var rootViewController: UIViewController { get }
  func didReceiveStep(_ notification: Notification)
  func executeRoutingStep(_ step: StepProtocol, nextCoordinatorReceiver receiver: (NextCoordinator) -> Void)
}

class Coordinator: CoordinatorProtocol {
  
  // MARK: - Properties
  
  weak var parentCoordinator: Coordinator?
  var childCoordinators: [Coordinator]
  
  var rootViewController: UIViewController {
    return UINavigationController()
  }
  
  // MARK: - Initialization
  
  init<T: StepProtocol>(parentCoordinator: Coordinator?, type: T.Type) {
    self.parentCoordinator = parentCoordinator
    self.childCoordinators = []
    
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(Self.didReceiveStep),
      name: Notification.Name(rawValue: T.identifier),
      object: nil
    )
  }
  
  deinit {
    NotificationCenter.default.removeObserver(self)
  }
  
  // MARK: - Functions
  
  @objc func didReceiveStep(_ notification: Notification) {
    didReceiveStep(notification, type: Step.self)
  }
  
  func didReceiveStep<T: StepProtocol>(_ notification: Notification, type: T.Type) {
    guard let userInfo = notification.userInfo as? [String: T],
      let step = userInfo[Constants.Keys.AppCoordinator.kStep] else {
        return
    }
    executeRoutingStep(step) { [weak self] nextCoordinator in
      switch nextCoordinator {
      case .none:
        break
      case let .single(coordinator):
        self?.childCoordinators.append(coordinator)
      case let .multiple(coordinators):
        self?.childCoordinators.append(contentsOf: coordinators)
      }
    }
  }
  
  /// The next step is expected to pass the following coordinator after having completed the internal setup process
  /// if such a coordinator is required for subseqent coordination.
  func executeRoutingStep(_ step: StepProtocol, nextCoordinatorReceiver receiver: (NextCoordinator) -> Void) {}
}
