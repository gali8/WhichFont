//
//  LaunchViewController.swift
//  WhichFont
//
//  Created by Daniele on 25/07/17.
//  Copyright © 2017 nexor. All rights reserved.
//

import UIKit

class DelayHelper {
    class func delay(_ delay:Double, closure:@escaping ()->()) {
        DispatchQueue.main.asyncAfter(
            deadline: DispatchTime.now() + Double(Int64(delay * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC), execute: closure)
    }
}

class LaunchViewController: UIViewController, UIViewControllerTransitioningDelegate {
    
    private let presentationTransitioning = RevealAnimator()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.transitioningDelegate = self
        
        DelayHelper.delay(0.2) {
            let vc = self.storyboard!.instantiateViewController(withIdentifier: "MainScene")
            vc.transitioningDelegate = self
            self.present(vc, animated: true, completion: nil)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return presentationTransitioning
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return nil
    }
}


class RevealAnimator: NSObject, UIViewControllerAnimatedTransitioning, CAAnimationDelegate {
    
    let animationDuration = 0.4
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return animationDuration
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let fromView = transitionContext.view(forKey: UITransitionContextViewKey.from)
        let toView = transitionContext.view(forKey: UITransitionContextViewKey.to)
        //let from = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.from)
        //let to = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.to)
        //let finalFrame = transitionContext.finalFrame(for: to!)
        let containerView = transitionContext.containerView
        //let bounds = UIScreen.main.bounds
        
        toView?.alpha = 0.8
        
        containerView.addSubview(toView!)
        
        UIView.animate(withDuration: animationDuration, animations: {
            fromView?.alpha = 0
            toView?.alpha = 1
        }) { (done) in
            transitionContext.completeTransition(true)
            fromView?.alpha = 1
        }
    }
}
