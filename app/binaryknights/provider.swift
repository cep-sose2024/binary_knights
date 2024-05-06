//
//  provider.swift
//  binaryknights
//
//  Created by Mohamed Bada on 06.05.24.
//

import Foundation
import LocalAuthentication
import Security
import CryptoKit

class provider{
    
    /*
    Creates an access control object for a cryptographic operation.


    #Returns

    A 'SecAccessControl' configured for private key usage.
    */
    func createAccessControlObject() -> SecAccessControl {
        let access = SecAccessControlCreateWithFlags(
            kCFAllocatorDefault,
            kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
            .privateKeyUsage,
            nil)!
        return access
    }
    

    // Represents errors that can occur within 'SecureEnclaveManager'.
    enum SecureEnclaveError: Error {
        case runtimeError(String)
    }

    
    /*
    Retrieves the public key associated with a given private key.

    # Arguments

    * 'privateKey' - A SecKey data type of the Security Framework representing a cryptographic private key.

    # Returns 

    Optionally a public key of the Security Framework representing a cryptographic public key on success, or 'nil' on failure

    */
    func getPublicKeyFromPrivateKey(privateKey: SecKey) -> SecKey? {
        return SecKeyCopyPublicKey(privateKey)
    }


    // Represents a pair of cryptographic keys.
    struct SEKeyPair {
        let publicKey: SecKey
        let privateKey: SecKey
    }
    static var isAvailable: Bool {
                  return true
    }


    /*
    Creates a new cryptographic key pair in the Secure Enclave.

    # Arguments

    * 'privateKeyName' - A String used to identify the private key.

    # Returns

    A 'SEKeyPair' containing the public and private keys on success, or a 'SecureEnclaveError' on failure.
    */
    func create_key(_ privateKeyName: String ) throws -> SEKeyPair {
        let accessControl = createAccessControlObject()
        
        let privateKeyParams: [String: Any] = [
            kSecAttrLabel as String: privateKeyName,
            kSecAttrIsPermanent as String: true,
            kSecAttrAccessControl as String: accessControl,
        ]
        let params: [String: Any] = [
            kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom,
            kSecAttrKeySizeInBits as String: 256,
            kSecAttrTokenID as String: kSecAttrTokenIDSecureEnclave,
            kSecPrivateKeyAttrs as String: privateKeyParams
        ]
        
        var error: Unmanaged<CFError>?
        guard let privateKeyReference = SecKeyCreateRandomKey(params as CFDictionary, &error) else {
            throw SecureEnclaveError.runtimeError("Error generating a new public-private key pair.")
        }
        
        guard let publicKey = getPublicKeyFromPrivateKey(privateKey: privateKeyReference) else {
            throw SecureEnclaveError.runtimeError("Error getting the public key from the private one.")
        }
        
        let keyPair = SEKeyPair(publicKey: publicKey, privateKey: privateKeyReference)
        
        return keyPair
    }

    /*
    Loads a cryptographic key from the keychain.

    # Arguments

    * 'key_id' - A String used as the identifier for the key

    # Returns

    Otionally the key as a SecKey data type on success, or a 'SecureEnclaveError' on failure.
    */
    static func load_key(_ key_id: String) throws -> SecKey? {
        let tag = key_id.data(using: .utf8)!
        let query: [String: Any] = [
            kSecClass as String                 : kSecClassKey,
            kSecAttrApplicationTag as String    : tag,
            kSecAttrKeyType as String           : kSecAttrKeyTypeEC,
            kSecReturnRef as String             : true
        ]
        
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess else {
            throw SecureEnclaveError.runtimeError("Couldn´t find the key")
        }
        return (item as! SecKey)
    }
    var privateKey: P256.KeyAgreement.PrivateKey?
    var publicKey: P256.KeyAgreement.PublicKey?
    var initialized: Bool = false


    /*
    Inizializes a module by creating a private key and the associated private key.

    # Returns

    A boolean if the module has been inizializes correctly on success, or a 'SecureEnclaveError' on failure.
    */
    func initializeModule() throws-> Bool  {
        self.privateKey =  P256.KeyAgreement.PrivateKey()
        self.publicKey = privateKey!.publicKey
        self.initialized = true
        guard self.initialized else{
            throw SecureEnclaveError.runtimeError("Did not initailze any Module")

        }
        guard SecureEnclave.isAvailable else {
            throw SecureEnclaveError.runtimeError("Secure Enclave is not Available on this Device")
        }
        return true
    }

    
}


