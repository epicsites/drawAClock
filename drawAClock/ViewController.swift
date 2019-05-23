//
//  ViewController.swift
//  drawAClock
//
//  Created by Aleksandr on 4/2/19.
//  Copyright © 2019 Aleksandr. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    let clockView = ClockView()
    let tapGesture = UITapGestureRecognizer()

    override func viewDidLoad() {
        super.viewDidLoad()
        clockView.frame = view.frame
        clockView.date = Date(timeInterval: -3600, since: Date())
        view.addSubview(clockView)
        let clock2Image = ClockView.getImage(time: Date(timeInterval: -7230, since: Date()), size: CGSize(width: 150, height: 150))
        clockView.backgroundColor = .clear
        
        let imageView = UIImageView(image: clock2Image)
        imageView.frame.origin.y += 30
        view.addSubview(imageView)
        tapGesture.addTarget(self, action: #selector(handleTap))
        view.addGestureRecognizer(tapGesture)
    }
    
    @objc func handleTap() {
        let clockImage = ClockView.getImage(time: Date(), size: CGSize(width: 150, height: 150))
        let iv = UIImageView(image: clockImage)
        iv.frame.origin = CGPoint(x: 160, y: 30)
        view.addSubview(iv)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        clockView.frame = view.bounds
        
    }
    
    
}

