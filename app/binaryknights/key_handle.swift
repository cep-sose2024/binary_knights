//
//  key_handle.swift
//  binaryknights
//
//  Created by Mohamed Bada on 06.05.24.
//

import Foundation
import LocalAuthentication
import Security
import CryptoKit

class key_handle{
    
    let algorithm: SecKeyAlgorithm = SecKeyAlgorithm.eciesEncryptionCofactorVariableIVX963SHA256AESGCM
    let sign_algorithm: SecKeyAlgorithm = SecKeyAlgorithm.ecdsaSignatureMessageX962SHA256
    
    
    // Represents errors that can occur within 'SecureEnclaveManager'.
    enum SecureEnclaveError: Error {
        case runtimeError(String)
    }

    /*
    Stores a cryptographic key in the keychain.

    # Arguments
    
    * 'name' - A String used to identify the key in the keychain.

    * 'privateKey' - A SecKey data type of the Security Framework representing a cryptographic private key.

    # Returns

    A 'SecureEnclaveError' on failure.
    */
    func storeKey_Keychain(_ name: String, _ privateKey: SecKey) throws{
        let key = privateKey
        let tag = name.data(using: .utf8)!
        let addquery: [String: Any] = [kSecClass as String: kSecClassKey,
                                       kSecAttrApplicationTag as String: tag,
                                       kSecValueRef as String: key]
        
        //        var error: Unmanaged<CFError>?
        let status = SecItemAdd(addquery as CFDictionary, nil)
        guard status == errSecSuccess
        else {
            throw SecureEnclaveError.runtimeError("Failed to store Key in the Keychain")
        }
    }

    /*
    Encrypts data using a public key.

    # Arguments

    * 'data' - Data that has to be encrypted.

    * 'publicKey' - A SecKey data type of the Security Framework representing a cryptographic public key.

    # Returns

    Data that has been encrypted on success, or a 'SecureEnclaveError' on failure.
    */
    func encrypt_data(data: Data, publicKey: SecKey) throws -> Data {
        var error: Unmanaged<CFError>?
        let result = SecKeyCreateEncryptedData(publicKey, algorithm, data as CFData, &error)
        
        if result == nil {
            throw SecureEnclaveError.runtimeError("Error encrypting data. \(String(describing: error))")
        }
        
        return result! as Data
    }
    

    /*
    Decrypts data using a private key.

    # Arguments

    * 'data' - Encrypted data that has to be decrypted.

    * 'privateKey' - A SecKey data type of the Security Framework representing a cryptographic private key.

    # Returns

    Data that has been decrypted on success, or a 'SecureEnclaveError' on failure.
    */
    func decrypt_data(_ data: Data, privateKey: SecKey) throws -> Data {
        var error: Unmanaged<CFError>?
        let result = SecKeyCreateDecryptedData(privateKey, algorithm, data as CFData, &error)
        
        if result == nil {
            throw SecureEnclaveError.runtimeError("Error decrypting data. \(String(describing: error))")
        }
        
        return result! as Data
    }


    /*
    Signs data using a private key.

    # Arguments

    * 'privateKey' - A SecKey data type of the Security Framework representing a cryptographic private key.

    * 'content' - A CFData data type of the Core Foundation that has to be signed.

    # Returns
    
    Optionally data that has been signed as a CFData data type on success, or 'nil' on failure.
    */
    func sign_data(_ privateKey: SecKey, _ content: CFData) throws -> CFData? {
                
        if !SecKeyIsAlgorithmSupported(privateKey, SecKeyOperationType.sign, sign_algorithm){
            throw SecureEnclaveError.runtimeError("Algorithm is not supported")
        }
        
        var error: Unmanaged<CFError>?
        guard let signed_data = SecKeyCreateSignature(privateKey, SecKeyAlgorithm.ecdsaSignatureMessageX962SHA256, content as CFData, &error)
        else{
            throw SecureEnclaveError.runtimeError("Data couldn´t be signed")
        }
        return signed_data
    }
    

    /*
    Verifies a signature using a public key.

    # Arguments

    * 'publicKey - A SecKey data type of the Security Framework representing a cryptographic public key.

    * 'content' - A String of the data that has to be verified.

    * 'signature' - A CFData data type of the Core Foundation that is the signature.

    # Returns

    A boolean if the signature is valid on success, or a 'SecureEnclaveError' on failure.
    */
    func verify_signature(_ publicKey: SecKey,_ content: String,_ signature: CFData) throws -> Bool{
        guard let content_data = content.data(using: String.Encoding.utf8)
        else{
            throw SecureEnclaveError.runtimeError("Invalid message to verify")
        }
        
        var error: Unmanaged<CFError>?
        if SecKeyVerifySignature(publicKey, sign_algorithm, content_data as CFData, signature, &error){
            return true
        } else{
          return false
        }
    }
    
}
