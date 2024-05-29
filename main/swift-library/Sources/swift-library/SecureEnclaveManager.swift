import Foundation
import LocalAuthentication
import Security
import CryptoKit
    
    /*
     Creates a new cryptographic key pair in the Secure Enclave.
     
     # Arguments
     
     * 'privateKeyName' - A String used to identify the private key.
     
     # Returns
     
     A 'SEKeyPair' containing the public and private keys on success, or a 'SecureEnclaveError' on failure.
     */
    func create_key(privateKeyName: String ) throws -> SEKeyPair? {
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
            throw SecureEnclaveError.runtimeError("Error generating a new public-private key pair. \(String(describing: error))")
        }
        
        guard let publicKey = getPublicKeyFromPrivateKey(privateKey: privateKeyReference) else {
            throw SecureEnclaveError.runtimeError("Error getting the public key from the private one.")
        }
        
        let keyPair = SEKeyPair(publicKey: publicKey, privateKey: privateKeyReference)
        
        do{
            try storeKey_Keychain(privateKeyName, privateKeyReference)
        }catch{
            SecureEnclaveError.runtimeError("\(error)")
        }
        return keyPair
    }


/** Optimized method off @generateKeyPair() to communicate with the rust-side abstraction-layer.
 Output and input is only in string-forms possible **/
func rustcall_create_key(privateKeyName: RustString) -> String {
    // Add-Error-Case: If an Secure Enclave Processor does not exist.
    do{
        let keyPair = try create_key(privateKeyName: privateKeyName.toString())
        return ("Private Key: "+String((keyPair?.privateKey.hashValue)!) + "\nPublic Key: " + String((keyPair?.publicKey.hashValue)!))
    }catch{
        return ("\(error)")
    }
}
    
    
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
    
    
    /*
     Encrypts data using a public key.
     
     # Arguments
     
     * 'data' - Data that has to be encrypted.
     
     * 'publicKey' - A SecKey data type of the Security Framework representing a cryptographic public key.
     
     # Returns
     
     Data that has been encrypted on success, or a 'SecureEnclaveError' on failure.
     */
    func encrypt_data(data: Data, publicKey: SecKey) throws -> Data {
        var algorithm = SecKeyAlgorithm.eciesEncryptionCofactorVariableIVX963SHA256AESGCM
        var error: Unmanaged<CFError>?
        let result = SecKeyCreateEncryptedData(publicKey, algorithm, data as CFData, &error)
        
        if result == nil {
            throw SecureEnclaveError.runtimeError("Error encrypting data. \(String(describing: error))")
        }
        
        return result! as Data
    }

    func rustcall_encrypt_data(data: RustString, keyname: RustString) -> String {
    do{
        let privateKey: SecKey = try load_key(key_id: keyname.toString())!
        let publicKey = getPublicKeyFromPrivateKey(privateKey: privateKey)
        let encryptedData: Data = try encrypt_data(data: data.toString().data(using: String.Encoding.utf8)!, publicKey: publicKey!)
        let encryptedData_string = encryptedData.base64EncodedString()
        return ("\(encryptedData_string)")
    }catch{
        return ("\(error)")
    }

}
    
    
    /*
     Decrypts data using a private key.
     
     # Arguments
     
     * 'data' - Encrypted data that has to be decrypted.
     
     * 'privateKey' - A SecKey data type of the Security Framework representing a cryptographic private key.
     
     # Returns
     
     Data that has been decrypted on success, or a 'SecureEnclaveError' on failure.
     */
    func decrypt_data(data: Data, privateKey: SecKey) throws -> Data {
        let algorithm: SecKeyAlgorithm = SecKeyAlgorithm.eciesEncryptionCofactorVariableIVX963SHA256AESGCM
        var error: Unmanaged<CFError>?
        let result = SecKeyCreateDecryptedData(privateKey, algorithm, data as CFData, &error)
        
        if result == nil {
            throw SecureEnclaveError.runtimeError("Error decrypting data. \(String(describing: error))")
        }
        
        return result! as Data
    }

    func rustcall_decrypt_data(data: RustString, privateKeyName: RustString) -> String{
        do{
            guard let data = Data(base64Encoded: data.toString())
            else {
                return ("Invalid base64 input")
            }
                                    
            guard let decrypted_value = String(data: try decrypt_data(data: data, privateKey: load_key(key_id: privateKeyName.toString())!), encoding: .utf8)
            else {
                return ("Error converting decrypted data to string")
            }
            
            return ("Successful decrypted: \(data) in \(decrypted_value)")
        } catch {
            return ("Fehler: \(error)")
        }
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
    
    
    /*
     Signs data using a private key.
     
     # Arguments
     
     * 'privateKey' - A SecKey data type of the Security Framework representing a cryptographic private key.
     
     * 'content' - A CFData data type of the Core Foundation that has to be signed.
     
     # Returns
     
     Optionally data that has been signed as a CFData data type on success, or 'nil' on failure.
     */
    func sign_data(privateKey: SecKey, content: CFData) throws -> CFData? {
        let sign_algorithm = SecKeyAlgorithm.ecdsaSignatureMessageX962SHA256;
        if !SecKeyIsAlgorithmSupported(privateKey, SecKeyOperationType.sign, sign_algorithm){
            throw SecureEnclaveError.runtimeError("Algorithm is not supported")
        }
        
        var error: Unmanaged<CFError>?
        guard let signed_data = SecKeyCreateSignature(privateKey, sign_algorithm, content as CFData, &error)
        else{
            throw SecureEnclaveError.runtimeError("Data couldn´t be signed")
        }
        return signed_data
    }
    

    func rustcall_sign_data(content: RustString, privateKeyName: RustString) -> String{
        let privateKeyName_string = privateKeyName.toString()
        let content_cfdata = content.toString().data(using: String.Encoding.utf8)! as CFData

        do {
            let privateKey = try load_key(key_id: privateKeyName_string)!
            return try ((sign_data(privateKey: privateKey,content: content_cfdata))! as Data).base64EncodedString(options: [])
        }catch{
            return "\(error)"
        }
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
    // func verify_signature(publicKey: SecKey, content: String, signature: CFData) throws -> Bool{
    //     let sign_algorithm = SecKeyAlgorithm.ecdsaSignatureMessageX962SHA256
    //     guard let content_data = content.data(using: String.Encoding.utf8)
    //     else{
    //         throw SecureEnclaveError.runtimeError("Invalid message to verify")
    //     }
        
    //     var error: Unmanaged<CFError>?
    //     if SecKeyVerifySignature(publicKey, sign_algorithm, content_data as CFData, signature, &error){
    //         return true
    //     } else{
    //         return false
    //     }
    // }

        func verify_signature(publicKey: SecKey,content: String, signature: String) throws -> Bool {
        let sign_algorithm = SecKeyAlgorithm.ecdsaSignatureMessageX962SHA256
        guard Data(base64Encoded: signature) != nil else{
            throw SecureEnclaveError.runtimeError("Invalid message to verify")
        }
        
        guard let content_data = content.data(using: String.Encoding.utf8)
        else{
            throw SecureEnclaveError.runtimeError("Invalid message to verify")
        }
        
        var error: Unmanaged<CFError>?
        if SecKeyVerifySignature(publicKey, sign_algorithm, content_data as CFData, Data(base64Encoded: signature, options: [])! as CFData, &error){
            return true
        } else{
            return false
        }
    }

    func rustcall_verify_data(publicKeyName: RustString, content: RustString, signature: RustString) -> String{
        do{
            let publicKeyName_string = publicKeyName.toString()
            let content_string = content.toString()
            let signature_string = signature.toString()
            guard let publicKey = getPublicKeyFromPrivateKey(privateKey: try load_key(key_id: publicKeyName_string)!)else{
                throw SecureEnclaveError.runtimeError("Error getting PublicKey from PrivateKey)")
            }
            let status = try verify_signature(publicKey: publicKey, content: content_string, signature: signature_string)
            
            if status == true{
                return "true"
            }else{
                return "false"
            }

        }catch{
            return "\(error)"
        }
        return "true"
    }
    
    
    // Represents errors that can occur within 'SecureEnclaveManager'.
    enum SecureEnclaveError: Error {
        case runtimeError(String)
    }
    
    // Represents a pair of cryptographic keys.
    struct SEKeyPair {
        let publicKey: SecKey
        let privateKey: SecKey
    }
    
    
    /*
     Loads a cryptographic key from the keychain.
     
     # Arguments
     
     * 'key_id' - A String used as the identifier for the key
     
     # Returns
     
     Otionally the key as a SecKey data type on success, or a 'SecureEnclaveError' on failure.
     */
    func load_key(key_id: String) throws -> SecKey? {
        let tag = key_id
        let query: [String: Any] = [
            kSecClass as String                 : kSecClassKey,
            kSecAttrApplicationTag as String    : tag,
            kSecAttrKeyType as String           : kSecAttrKeyTypeECSECPrimeRandom,
            kSecReturnRef as String             : true
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess else {
            throw SecureEnclaveError.runtimeError("Couldn´t find the key")
        }
        return (item as! SecKey)
    }

    func rustcall_load_key(keyID: RustString) -> String {
    do {
        guard let key = try load_key(key_id: keyID.toString()) else {
            return "Key not found."
        }
        return "\(key.hashValue)"
    } catch {
        return "\(error)"
    }
}
    
    
    /*
     Stores a cryptographic key in the keychain.
     
     # Arguments
     
     * 'name' - A String used to identify the key in the keychain.
     
     * 'privateKey' - A SecKey data type of the Security Framework representing a cryptographic private key.
     
     # Returns
     
     A 'SecureEnclaveError' on failure.
     */
    func storeKey_Keychain(_ name: String, _ privateKey: SecKey) throws {
        let key = privateKey
        let tag = name.data(using: .utf8)!
        let addquery: [String: Any] = [kSecClass as String: kSecClassKey,
                                       kSecAttrApplicationTag as String: tag,
                                       kSecValueRef as String: key]
        
        let status = SecItemAdd(addquery as CFDictionary, nil)
        guard status == errSecSuccess
        else {
            throw SecureEnclaveError.runtimeError("Failed to store Key in the Keychain")
        }
    }
    
    // static var isAvailable: Bool {
    //     return true
    // }
    
    /*
     Inizializes a module by creating a private key and the associated private key.
     
     # Returns
     
     A boolean if the module has been inizializes correctly on success, or a 'SecureEnclaveError' on failure.
     */
    func initializeModule() -> Bool  {
        if #available(macOS 10.15, *) {
            var initialized: Bool = true
            var privateKey: P256.KeyAgreement.PrivateKey?
            var publicKey: P256.KeyAgreement.PublicKey?
            do{
                guard initialized else{
                    throw SecureEnclaveError.runtimeError("Did not initailze any Module")
                }
                guard SecureEnclave.isAvailable else {
                throw SecureEnclaveError.runtimeError("Secure Enclave is not Available on this Device")
                }  
            }catch{
                return false
            }
        } else {
            return true
        }

        return true
    }