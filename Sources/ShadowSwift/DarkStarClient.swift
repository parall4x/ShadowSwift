//
//  DarkStarClient.swift
//  ShadowSwift
//
//  Created by Dr. Brandon Wiley on 10/14/21.
//

import Foundation
import Crypto
import Transmission
import Net
import Datable
import SwiftHexTools

public class DarkStarClient
{
    let sharedKey: SymmetricKey

    static public func handleServerConfirmationCode(connection: Connection, sharedKey: SymmetricKey, endpoint: NWEndpoint, serverEphemeralPublicKey: P256.KeyAgreement.PublicKey, clientEphemeralPublicKey: P256.KeyAgreement.PublicKey) -> Bool
    {
        let data = connection.read(size: P256KeySize)

        guard let code = DarkStar.generateServerConfirmationCode(clientSharedKey: sharedKey, endpoint: endpoint, serverEphemeralPublicKey: serverEphemeralPublicKey, clientEphemeralPublicKey: clientEphemeralPublicKey) else {return false}

         return data == code
//        return true // We'll accept any server auth code for now (test)
    }

    static public func handleClientConfirmationCode(connection: Connection, theirPublicKey: P256.KeyAgreement.PublicKey, myPrivateKey: P256.KeyAgreement.PrivateKey, endpoint: NWEndpoint, serverPersistentPublicKey: P256.KeyAgreement.PublicKey, clientEphemeralPublicKey: P256.KeyAgreement.PublicKey) -> Bool
    {
        guard let data = DarkStar.generateClientConfirmationCode(connection: connection, theirPublicKey: theirPublicKey, myPrivateKey: myPrivateKey, endpoint: endpoint, serverPersistentPublicKey: serverPersistentPublicKey, clientEphemeralPublicKey: clientEphemeralPublicKey) else {return false}

        return connection.write(data: data)
    }

    static public func createClientSharedKey(clientEphemeralPrivateKey: P256.KeyAgreement.PrivateKey, serverEphemeralPublicKey: P256.KeyAgreement.PublicKey, serverPersistentPublicKey: P256.KeyAgreement.PublicKey, serverEndpoint: NWEndpoint) -> SymmetricKey?
    {
        guard let ephemeralECDH = try? clientEphemeralPrivateKey.sharedSecretFromKeyAgreement(with: serverEphemeralPublicKey) else {return nil}

        let ephemeralECDHData = DarkStar.sharedSecretToData(secret: ephemeralECDH)

        guard let persistentECDH = try? clientEphemeralPrivateKey.sharedSecretFromKeyAgreement(with: serverPersistentPublicKey) else {return nil}

        let persistentECDHData = DarkStar.sharedSecretToData(secret: persistentECDH)

        let clientEphemeralPublicKey = clientEphemeralPrivateKey.publicKey

        let clientEphemeralPublicKeyData = clientEphemeralPublicKey.compactRepresentation!

        let serverEphemeralPublicKeyData = serverEphemeralPublicKey.compactRepresentation!

        guard let serverIdentifier = DarkStar.makeServerIdentifier(serverEndpoint) else {return nil}

        var hash = SHA256()
        hash.update(data: ephemeralECDHData)
        hash.update(data: persistentECDHData)
        hash.update(data: serverIdentifier)
        hash.update(data: clientEphemeralPublicKeyData)
        hash.update(data: serverEphemeralPublicKeyData)
        hash.update(data: DarkStarString.data)
        hash.update(data: ServerString.data)
        let hashed = hash.finalize()

        let hashedData = Data(hashed)
        return SymmetricKey(data: hashedData)
    }

    public init?(serverPersistentPublicKey: P256.KeyAgreement.PublicKey, endpoint: NWEndpoint, connection: Connection)
    {
        // Send client ephemeral key
        guard let (clientEphemeralPrivateKey, clientEphemeralPublicKey) = DarkStar.handleMyEphemeralKey(connection: connection) else {return nil}

        // Send client confirmation code
        guard DarkStarClient.handleClientConfirmationCode(connection: connection, theirPublicKey: serverPersistentPublicKey, myPrivateKey: clientEphemeralPrivateKey, endpoint: endpoint, serverPersistentPublicKey: serverPersistentPublicKey, clientEphemeralPublicKey: clientEphemeralPublicKey) else {return nil}

        // Receive server ephemeral key
        guard let serverEphemeralPublicKey = DarkStar.handleTheirEphemeralPublicKey(connection: connection) else {return nil}

        // Create shared key
        guard let sharedKey = DarkStarClient.createClientSharedKey(clientEphemeralPrivateKey: clientEphemeralPrivateKey, serverEphemeralPublicKey: serverEphemeralPublicKey, serverPersistentPublicKey: serverPersistentPublicKey, serverEndpoint: endpoint) else {return nil}
        self.sharedKey = sharedKey

//      Todo: Get rid of this
//        let keyb64 = sharedKey.withUnsafeBytes {
//            return Data(Array($0)).hex
//        }
//
//        print("Shared key: " + keyb64)
        
        // Receive and validate server confirmation code
        guard DarkStarClient.handleServerConfirmationCode(connection: connection, sharedKey: sharedKey, endpoint: endpoint, serverEphemeralPublicKey: serverEphemeralPublicKey, clientEphemeralPublicKey: clientEphemeralPublicKey) else {return nil}
    }
}
