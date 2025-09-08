//
//  Logger.swift
//  NetworkingDemoSwiftUI_URLSession
//
//  Created by Satish Thakur on 08/09/25.
//

import Foundation
/*
/// Custom print that only logs in Debug mode
public func print(
    _ items: Any...,
    separator: String = " ",
    terminator: String = "\n"
) {
    #if DEBUG
    let output = items.map { "\($0)" }.joined(separator: separator)
    Swift.print(output, terminator: terminator)
    #endif
}
///Output:
///print("User logged in")   // shows only in Debug
///print("User ID:", 12345)    // still supports multiple arguments
*/
 
/// Custom print that only logs in Debug mode with file, line, and function info
public func print(
    _ items: Any...,
    separator: String = " ",
    terminator: String = "\n",
    file: String = #file,
    line: Int = #line,
    function: String = #function
) {
    #if DEBUG
    let output = items.map { "\($0)" }.joined(separator: separator)
    let filename = (file as NSString).lastPathComponent
    Swift.print("📌 [\(filename):\(line)] \(function) → \(output)", terminator: terminator)
    #endif
}

///print("User logged in")
///print("Token:", "abcd1234")
///Output:
///📌 [LoginViewModel.swift:42] loginUser() → User logged in
///📌 [LoginViewModel.swift:43] loginUser() → Token: abcd1234
