//
//  utils.swift
//  YenePaySDKSampleApp
//
//  Created by Ahmed Mohammed Abdurahman on 1/22/21.
//

import Foundation

public extension Double {
    var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = ""
        formatter.alwaysShowsDecimalSeparator = false
        formatter.currencyDecimalSeparator = "."
        formatter.currencyGroupingSeparator = ","
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        formatter.roundingMode = .floor
        return formatter.string(from: NSNumber(value: self)) ?? "0"
    }
}
