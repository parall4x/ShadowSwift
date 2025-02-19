//
//  AddressReader.swift
//  Shadow
//
//  Created by Mafalda on 8/27/20.
//

import Foundation
// FIXME: Logger

class AddressReader
{
    func createAddr() -> Data
    {
        let type: [UInt8] = [0x01]
        let host: [UInt8] = [0x00, 0x00, 0x00, 0x00]
        let port: [UInt8] = [0x00, 0x00]
        
        return Data(array: type + host + port)
    }
    
    func getAddr(from buffer: Data) -> (address: Socks5Addr, remaining: Data)?
    {
        let typeLength = 1
        let portLength = 2
        
        guard let addrType = AddrType(rawValue: Int(buffer[0]))
        else
        {
            return nil
        }
        
        switch addrType
        {
        case .domainName:
            // The second byte indicates the length of the domain name
            let hostLength = Int(buffer[1])
            let addrLength = typeLength + 1 + hostLength + portLength
            
            // Quality check to make sure that our address data is the right size
            guard buffer.count >= addrLength
            else
            {
                return nil
            }
            
            // Get the address data from the beginning of the buffer
            let addressData = buffer[..<addrLength]
            
            // Get the remaining data
            let remaining = buffer[addrLength...]
            
            // The domaine name should start with the 3rd byte
            let hostData = addressData[2..<hostLength + 2]
            // The port is the last 2 bytes
            let portData = addressData[(2 + hostLength)...]
            
            guard let hostString = String(data: hostData, encoding: .utf8)
                else
            {
                return nil
            }
            
            guard let portString = String(data: portData, encoding: .utf8)
            else
            {
                return nil
            }
            
            let socks5Addr = Socks5Addr(type: addrType, data: addressData, string: hostString + portString)
            return(socks5Addr, remaining)
            
        case .ipV4:
            let ipV4Length = 4
            let addressLength = typeLength + ipV4Length + portLength
            guard buffer.count >= addressLength
                else
            {
                return nil
            }
            
            let addressData = buffer[..<addressLength]
            let remaining = buffer[addressLength...]
            
            // IPAddress starts with the 2nd byte
            let hostData = addressData[1...ipV4Length]
            // The port is the last 2 bytes
            let portData = addressData[(typeLength + ipV4Length)...]
            
            guard let hostString = String(data: hostData, encoding: .utf8)
            else
            {
                return nil
            }
            
            guard let portString = String(data: portData, encoding: .utf8)
                else
            {
                return nil
            }
            
            let socks5Addr = Socks5Addr(type: addrType, data: addressData, string: hostString + portString)
            return(socks5Addr, remaining)
            
        case .ipV6:
            let ipV6Length = 16
            let addressLength = typeLength + ipV6Length + portLength
            guard buffer.count >= addressLength
            else
            {
                return nil
            }
            
            let addressData = buffer[..<addressLength]
            let remaining = buffer[addressLength...]
            
            let hostData = addressData[1...ipV6Length]
            let portData = addressData[(typeLength + ipV6Length)...]
            
            guard let hostString = String(data: hostData, encoding: .utf8)
                else
            {
                return nil
            }
            
            guard let portString = String(data: portData, encoding: .utf8)
                else
            {
                return nil
            }
            
            let socks5Addr = Socks5Addr(type: addrType, data: addressData, string: hostString + portString)
            return(socks5Addr, remaining)
        }
    }
}
