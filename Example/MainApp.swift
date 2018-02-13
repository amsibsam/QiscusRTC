//
//  MainApp.swift
//  Example
//
//  Created by QiscusiOS on 13/02/18.
//  Copyright © 2018 qiscus. All rights reserved.
//


import UIKit

class MainApp{
    public static let shared = MainApp()
    func getMainVC() -> UIViewController{
        let target = MainViewController()
        return target
    }
}
