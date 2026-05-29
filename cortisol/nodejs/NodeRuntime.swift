//
//  NodeRuntime.swift
//  cortisol
//
//  Created by Aarav Gupta on 29/05/26.
//

import SwiftUI
import NodeMobile
import Darwin

enum NodeRuntime {
    private static let startOnce: Void = {
        let thread = Thread {
            run()
        }
        thread.stackSize = 2 * 1024 * 1024
        thread.start()
    }()

    static func startIfNeeded() {
        _ = startOnce
    }

    private static func run() {
        guard let scriptPath = Bundle.main.path(forResource: "main", ofType: "js", inDirectory: "nodejs-project") else {
            print("Unable to find nodejs-project/main.js")
            return
        }

        let arguments = ["node", scriptPath]
        let totalSize = arguments.reduce(0) { $0 + $1.utf8.count + 1 }

        let buffer = UnsafeMutablePointer<CChar>.allocate(capacity: totalSize)
        let argv = UnsafeMutablePointer<UnsafeMutablePointer<CChar>?>.allocate(capacity: arguments.count)

        var currentOffset = 0
        for (index, argument) in arguments.enumerated() {
            let cString = Array(argument.utf8CString)
            cString.withUnsafeBufferPointer { source in
                if let baseAddress = source.baseAddress {
                    memcpy(buffer.advanced(by: currentOffset), baseAddress, source.count)
                }
            }
            argv[index] = buffer.advanced(by: currentOffset)
            currentOffset += cString.count
        }

        node_start(Int32(arguments.count), argv)
    }
}
