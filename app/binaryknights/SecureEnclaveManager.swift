import Foundation
import LocalAuthentication
import Security
import CryptoKit

class SecureEnclaveManager{
    let algorithm: SecKeyAlgorithm = SecKeyAlgorithm.eciesEncryptionCofactorVariableIVX963SHA256AESGCM
    let sign_algorithm: SecKeyAlgorithm = SecKeyAlgorithm.ecdsaSignatureMessageX962SHA256
    var privateKey: P256.KeyAgreement.PrivateKey?
    var publicKey: P256.KeyAgreement.PublicKey?
    var initialized: Bool = false
    
    
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
        
        let status = SecItemAdd(addquery as CFDictionary, nil)
        guard status == errSecSuccess
        else {
            throw SecureEnclaveError.runtimeError("Failed to store Key in the Keychain")
        }
    }
    
    static var isAvailable: Bool {
        return true
    }
    
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
