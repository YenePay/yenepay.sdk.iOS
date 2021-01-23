//
//  AppDelegate.swift
//  YenePaySDKSampleApp
//
//  Created by Ahmed Mohammed Abdurahman on 1/19/21.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    public var window: UIWindow?
        
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        configureYenePay()
        return true
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        if YNPPaymentOrderManager.sharedInstance().handleOpen(url) {
            return true
        }
        
        return false
    }
    
    
    private func configureYenePay() {
        YNPPaymentOrderManager.sharedInstance().useSandboxEnabled = true
        //YNPPaymentOrderManager.sharedInstance().merchantCode = "0001"
        YNPPaymentOrderManager.sharedInstance().merchantCode = "0734"
        YNPPaymentOrderManager.sharedInstance().ipnUrl = "https://www.example.com/ipn"
        YNPPaymentOrderManager.sharedInstance().returnUrl = "com.yenepay.ios.YenePaySDKSampleApp.ynp://"
    }
    
    
    static func checkout(presentingViewController: UIViewController, completionHandler: ((Bool /* Payment Completed? */)->Void)?) {
        if ShoppingCart.shared.totalPrice == 0.0 {
            let alertVc = UIAlertController(title: "Cart Is Empty",
                                            message: "You must select at least one item.",
                                            preferredStyle: .alert)
            alertVc.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
            presentingViewController.present(alertVc, animated: true, completion: nil)
            
            return
        }
        
        let payment = YNPPaymentOrder()
        payment.merchantOrderId = UUID().uuidString
        payment.paymentProcess = ShoppingCart.shared.items.count == 1 ? YNPPaymentProcessTypeExpress : YNPPaymentProcessTypeCart
        
        var paymentItems: [YNPOrderedItem] = []
        for (storeItem, count) in ShoppingCart.shared.items {
            let paymentItem = YNPOrderedItem()
            paymentItem.itemId = storeItem.id
            paymentItem.itemName = storeItem.name
            paymentItem.unitPrice = storeItem.price
            paymentItem.quantity = count
            paymentItems.append(paymentItem)
        }
        
        payment.items = paymentItems
        payment.discount = 0.0
        payment.tax1 = ShoppingCart.shared.tax1
        payment.tax2 = ShoppingCart.shared.tax2
        payment.handlingFee = 0.0
        payment.deliveryFee = 0.0
        
        YNPPaymentOrderManager.sharedInstance().checkout(with: payment) { [weak presentingViewController] (response, error) in
            if let error = error {
                let alertVc = UIAlertController(title: "Payment Error",
                                                message: error.localizedDescription,
                                                preferredStyle: .alert)
                alertVc.addAction(UIAlertAction(title: "OK", style: .cancel, handler: { (action) in
                    completionHandler?(false)
                }))
                presentingViewController?.present(alertVc, animated: true)
                return
            }
            
            guard let response = response else {
                let alertVc = UIAlertController(title: "Unexpected Error",
                                                message: "This should never happen but if it does, please report it",
                                                preferredStyle: .alert)
                alertVc.addAction(UIAlertAction(title: "OK", style: .cancel, handler: { (action) in
                    completionHandler?(false)
                }))
                presentingViewController?.present(alertVc, animated: true, completion: nil)
                return
            }
            
            
            if response.isPaymentCompleted {
                let alertVc = UIAlertController(title: "Payment Completed",
                                                message: "Payment completed successfully.",
                                                preferredStyle: .alert)
                alertVc.addAction(UIAlertAction(title: "OK", style: .cancel, handler: { (action) in
                    completionHandler?(true)
                }))
                presentingViewController?.present(alertVc, animated: true, completion: nil)
            } else {
                let alertVc = UIAlertController(title: "Payment Not Completed",
                                                message: "Payment status = \(response.statusText)",
                                                preferredStyle: .alert)
                alertVc.addAction(UIAlertAction(title: "OK", style: .cancel, handler: { (action) in
                    completionHandler?(false)
                }))
                presentingViewController?.present(alertVc, animated: true, completion: nil)
            }
        }
    }
}

