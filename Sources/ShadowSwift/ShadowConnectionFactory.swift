//
//  ShadowConnectionFactory.swift
//  Shapeshifter-Swift-Transports
//
//  Created by Mafalda on 8/3/20.
//  MIT License
//
//  Copyright (c) 2020 Operator Foundation
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NON-INFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import Foundation
import Logging

#if os(Linux)
import NetworkLinux
#else
import Network
#endif

import Transport

open class ShadowConnectionFactory: ConnectionFactory
{
    var log: Logger
    
    public var name = "Shadow"
    public var config: ShadowConfig
    public var connection: Connection?
    public var host: NWEndpoint.Host?
    public var port: NWEndpoint.Port?

    public init(host: NWEndpoint.Host, port: NWEndpoint.Port, config: ShadowConfig, logger: Logger)
    {
        self.host = host
        self.port = port
        self.config = config
        self.log = logger
    }
    
    public func connect(using parameters: NWParameters) -> Connection?
    {
        guard let currentHost = host, let currentPort = port
            else
        {
            return nil
        }

        return ShadowConnection(host: currentHost, port: currentPort, parameters: parameters, config: config, logger: log)
    }

//    public init(connection: Connection, config: ShadowConfig, logger: Logger)
//    {
//        self.connection = connection
//        self.config = config
//        self.log = logger
//    }
    
//    public func connect(using parameters: NWParameters) -> Connection?
//    {
//        if let currentConnection = connection
//        {
//            return ShadowConnection(connection: currentConnection, parameters: parameters, config: config, logger: log)
//        }
//        else
//        {
//            guard let currentHost = host, let currentPort = port
//                else
//            {
//                return nil
//            }
//
//            return ShadowConnection(host: currentHost, port: currentPort, parameters: parameters, config: config, logger: log)
//        }
//    }
    
}
