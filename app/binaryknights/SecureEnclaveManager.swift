import Foundation
import LocalAuthentication
import Security

class SecureEnclaveManager{
    let algorithm: SecKeyAlgorithm = SecKeyAlgorithm.eciesEncryptionCofactorVariableIVX963SHA256AESGCM
    let sign_algorithm: SecKeyAlgorithm = SecKeyAlgorithm.ecdsaSignatureMessageX962SHA256
    
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
    
    func createAccessControlObject() -> SecAccessControl {
        let access = SecAccessControlCreateWithFlags(
            kCFAllocatorDefault,
            kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
            .privateKeyUsage,
            nil)!
        return access
    }
    
    func encrypt_data(data: Data, publicKey: SecKey) throws -> Data {
        var error: Unmanaged<CFError>?
        let result = SecKeyCreateEncryptedData(publicKey, algorithm, data as CFData, &error)
        
        if result == nil {
            throw SecureEnclaveError.runtimeError("Error encrypting data. \(String(describing: error))")
        }
        
        return result! as Data
    }
    
    func decrypt_data(_ data: Data, privateKey: SecKey) throws -> Data {
        var error: Unmanaged<CFError>?
        let result = SecKeyCreateDecryptedData(privateKey, algorithm, data as CFData, &error)
        
        if result == nil {
            throw SecureEnclaveError.runtimeError("Error decrypting data. \(String(describing: error))")
        }
        
        return result! as Data
    }
    
    func getPublicKeyFromPrivateKey(privateKey: SecKey) -> SecKey? {
        return SecKeyCopyPublicKey(privateKey)
    }
    
    func signing_data(_ privateKey: SecKey, _ content: CFData) throws -> CFData? {
                
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

    enum SecureEnclaveError: Error {
        case runtimeError(String)
    }
    
    struct SEKeyPair {
        let publicKey: SecKey
        let privateKey: SecKey
    }
    
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
    // TODO:
    func initialize_module(){
        
    }
}


