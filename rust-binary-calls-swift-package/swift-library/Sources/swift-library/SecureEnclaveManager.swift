import Foundation
import LocalAuthentication
import Security

    
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

/** Optimized method off @generateKeyPair() to communicate with the rust-side abstraction-layer.
 Output and input is only in string-forms possible **/
func rustcall_generateKeyPair(publicKeyName: RustString,privateKeyName: RustString) -> String {
    // Add-Error-Case: If an Secure Enclave Processor does not exist.
    do{
        let keys = try generateKeyPair(publicKeyName.toString(), privateKeyName.toString()).publicKey as! Data
        let keysString = keys.base64EncodedString()
        return keysString
    }catch{
        return ("\(error)")
    }
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
    let result = SecKeyCreateEncryptedData(publicKey, .eciesEncryptionCofactorVariableIVX963SHA256AESGCM, data as CFData, &error)
    
    if result == nil {
        throw SecureEnclaveError.runtimeError("Error encrypting data. \(String(describing: error))")
    }
    
    return result! as Data
}

func decrypt(_ data: Data, privateKey: SecKey) throws -> Data {
    var error: Unmanaged<CFError>?
    let result = SecKeyCreateDecryptedData(privateKey, .eciesEncryptionCofactorVariableIVX963SHA256AESGCM, data as CFData, &error)
    
    if result == nil {
        throw SecureEnclaveError.runtimeError("Error decrypting data. \(String(describing: error))")
    }
    
    return result! as Data
}

func getPublicKeyFromPrivateKey(privateKey: SecKey) -> SecKey? {
    return SecKeyCopyPublicKey(privateKey);
}

enum SecureEnclaveError: Error {
    case runtimeError(String)
}

struct SEKeyPair {
    let publicKey: SecKey
    let privateKey: SecKey
}
