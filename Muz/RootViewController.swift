//
//  RootViewController.swift
//  Muz
//
//  Created by Nick Lanasa on 12/9/14.
//  Copyright (c) 2014 Nytek Productions. All rights reserved.
//

import Foundation
import UIKit

class RootViewController: UIViewController {
    
    override init() {
        super.init()
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        let image = UIImage(named: "random.jpg")
        var imageView = UIImageView(frame: UIScreen.mainScreen().bounds)
        imageView.image = image?.applyDarkEffect()
        imageView.contentMode = UIViewContentMode.ScaleAspectFill   
        imageView.autoresizingMask = .FlexibleWidth
        view.insertSubview(imageView, atIndex: 0)
    }
    
}
