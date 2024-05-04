import Foundation
import LocalAuthentication
import Security

class SecureEnclaveManager{
    let algorithm: SecKeyAlgorithm = SecKeyAlgorithm.eciesEncryptionCofactorVariableIVX963SHA256AESGCM
    let sign_algorithm: SecKeyAlgorithm = SecKeyAlgorithm.ecdsaSignatureMessageX962SHA256
    
    func generateKeyPair(_ publicKeyName: String,_ privateKeyName: String ) throws -> SEKeyPair {
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
    
    func encrypt(data: Data, publicKey: SecKey) throws -> Data {
        var error: Unmanaged<CFError>?
        let result = SecKeyCreateEncryptedData(publicKey, algorithm, data as CFData, &error)
        
        if result == nil {
            throw SecureEnclaveError.runtimeError("Error encrypting data. \(String(describing: error))")
        }
        
        return result! as Data
    }
    
    func decrypt(_ data: Data, privateKey: SecKey) throws -> Data {
        var error: Unmanaged<CFError>?
        let result = SecKeyCreateDecryptedData(privateKey, algorithm, data as CFData, &error)
        
        if result == nil {
            throw SecureEnclaveError.runtimeError("Error decrypting data. \(String(describing: error))")
        }
        
        return result! as Data
    }
    
    func getPublicKeyFromPrivateKey(privateKey: SecKey) -> SecKey? {
        return SecKeyCopyPublicKey(privateKey);
    }
    
    func signing_data(_ privateKey: SecKey, _ content: String) throws -> CFData? {
        guard let content_data = content.data(using: String.Encoding.utf8)
        else{
            throw SecureEnclaveError.runtimeError("Invalid message to sign")
        }
        
        if !SecKeyIsAlgorithmSupported(privateKey, SecKeyOperationType.sign, sign_algorithm){
            throw SecureEnclaveError.runtimeError("Algorithm is not supported")
        }
        
        var error: Unmanaged<CFError>?
        guard let signed_data = SecKeyCreateSignature(privateKey, SecKeyAlgorithm.ecdsaSignatureMessageX962SHA256, content_data as CFData, &error)
        else{
            throw SecureEnclaveError.runtimeError("Data couldn´t be signed")
        }
        return signed_data
    }
    
    func verify_data(_ publicKey: SecKey,_ content: String,_ signature: CFData) throws -> Bool{
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
}
