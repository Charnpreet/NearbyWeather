//
//  WelcomeStepper.swift
//  NearbyWeather
//
//  Created by Erik Maximilian Martens on 08.02.20.
//  Copyright © 2020 Erik Maximilian Martens. All rights reserved.
//

import Foundation

class WelcomeStepper: Stepper {}

extension WelcomeStepper {
  
  func requestRouting(toStep step: WelcomeStep) {
    emitStep(step, type: WelcomeStep.self)
  }
}
