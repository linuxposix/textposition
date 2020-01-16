//
//  ViewController.swift
//  textposition
//
//  Created by USER on 15/01/2020.
//  Copyright © 2020 posixlinux. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet private weak var textView: UITextView!
    @IBOutlet private weak var outlineView: UIView!
    @IBOutlet private weak var bottomConstraint: NSLayoutConstraint!
    private var observer: NSObjectProtocol?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.registerKeyboardNotification()
        self.setupOutlineView()
    }
    
    private func setupOutlineView() {
        self.outlineView.layer.borderWidth = 1 / UIScreen.main.scale
        self.outlineView.layer.borderColor = UIColor.black.cgColor
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        self.unregisterKeyboardNotification()
    }
    
    private func registerKeyboardNotification() {
        self.observer = NotificationCenter.default.addObserver(forName: UIView.keyboardWillChangeFrameNotification, object: nil, queue: nil, using: self.updateKeyboardFrame)
    }
    
    private func unregisterKeyboardNotification() {
        guard let observer = self.observer else { return }
        NotificationCenter.default.removeObserver(observer, name: UIView.keyboardWillChangeFrameNotification, object: nil)
    }
    
    private func updateKeyboardFrame(_ notification: Notification) {
        guard let userInfo: [AnyHashable: Any] = notification.userInfo,
            let endFrameValue: NSValue = userInfo[UIView.keyboardFrameEndUserInfoKey] as? NSValue,
            let startFrameValue: NSValue = userInfo[UIView.keyboardFrameBeginUserInfoKey] as? NSValue,
            let animationCurve: NSNumber = userInfo[UIView.keyboardAnimationCurveUserInfoKey] as? NSNumber,
            let animationDuration: NSNumber = userInfo[UIView.keyboardAnimationDurationUserInfoKey] as? NSNumber else { return }
        
        let startFrame: CGRect = startFrameValue.cgRectValue
        let endFrame: CGRect = endFrameValue.cgRectValue
        
        print("beginFrame: (\(startFrame.origin.x) \(startFrame.origin.y) \(startFrame.size.width) \(startFrame.size.height))");
        print("endFrame: (\(startFrame.origin.x) \(startFrame.origin.y) \(startFrame.size.width) \(startFrame.size.height))");
        
        guard let window: UIWindow = UIApplication.shared.keyWindow else { return }
        
        let beginConvertedFrame: CGRect = window.convert(startFrame, to: self.view)
        let endConvertedFrame: CGRect = window.convert(endFrame, to: self.view)
        let beginIntersectedFrame: CGRect = self.view.frame.intersection(beginConvertedFrame)
        let endIntersectedFrame: CGRect = self.view.frame.intersection(endConvertedFrame)
        
        let animation: Bool = beginIntersectedFrame.height == 0 || endIntersectedFrame.height == 0
        
        let height: CGFloat = endIntersectedFrame.height - self.view.safeAreaInsets.bottom
        
        let updateBlock = { [weak self] in
            self?.bottomConstraint.constant = height
            self?.view.layoutIfNeeded()
        }
        
        if animation {
            let curve: UIView.AnimationOptions = UIView.AnimationOptions(rawValue: animationCurve.uintValue << 16)
            UIView.animate(withDuration: animationDuration.doubleValue, delay: 0, options: curve, animations: updateBlock, completion: nil)
        } else {
            UIView.performWithoutAnimation(updateBlock)
        }
    }
    
    @IBAction func tapButton(_ sender: Any) {
        if self.isCustomInput() {
            self.offCustomInput()
        } else {
            self.onCustomInput()
        }
    }
    
    @IBAction func tapCustomAction(_ sender: Any) {
        self.textView.resignFirstResponder()
        self.textView.becomeFirstResponder()
        
        guard let window: UIWindow = UIApplication.shared.keyWindow else { return }

        let allSubviews: [UIView] = window.subviews.flatMap(self.allSubviews)

        self.makeViewGlitteringInARow(allSubviews)
        print("Finished!")
    }
    
    private func makeViewGlitteringInARow(_ views: [UIView]) {
        DispatchQueue.global().async {
            let group: DispatchGroup = DispatchGroup()
            
            views.forEach({ view in
                group.wait()
                group.enter()
                
                DispatchQueue.main.async {
                    let originalAlpha: CGFloat = view.alpha
                    
                    UIView.animate(withDuration: 0.5, animations: {
                        view.alpha = 0
                    }, completion: { finish in
                        UIView.animate(withDuration: 0.5, animations: {
                            view.alpha = 1
                        }, completion: { finish in
                            view.alpha = originalAlpha
                            group.leave()
                        })
                    })
                }
            })
        }
    }
    
    private func allSubviews(_ view: UIView) -> [UIView] {
        var allViews: [UIView] = view.subviews.flatMap(self.allSubviews)
        
        allViews.append(view)
        
        return allViews
    }
    
    private func onCustomInput() {
        self.textView.inputView = UIView(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: 500))
        self.textView.inputView?.backgroundColor = UIColor.red
        self.textView.reloadInputViews()
    }
    
    private func offCustomInput() {
        self.textView.inputView = nil
        self.textView.reloadInputViews()
    }
    
    private func isCustomInput() -> Bool {
        return self.textView.inputView != nil
    }
}
