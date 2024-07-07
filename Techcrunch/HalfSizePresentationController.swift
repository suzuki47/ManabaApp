//
//  HalfSizePresentationController.swift
//  Ritsumeikan
//
//  Created by 鈴木悠太 on 2024/05/15.
//

import UIKit

class HalfSizePresentationController: UIPresentationController {
    override var frameOfPresentedViewInContainerView: CGRect {
        guard let containerView = containerView else {
            return CGRect.zero
        }
        let height = containerView.bounds.height * 3 / 4
        return CGRect(x: 0, y: containerView.bounds.height - height, width: containerView.bounds.width, height: height)
    }
    
    override func containerViewWillLayoutSubviews() {
        super.containerViewWillLayoutSubviews()
        presentedView?.frame = frameOfPresentedViewInContainerView
    }
}

