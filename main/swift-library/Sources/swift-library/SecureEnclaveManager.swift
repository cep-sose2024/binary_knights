import Foundation
import LocalAuthentication
import Security
import CryptoKit

var algorithm = SecKeyAlgorithm.eciesEncryptionCofactorVariableIVX963SHA224AESGCM
var sign_algorithm: SecKeyAlgorithm = SecKeyAlgorithm.ecdsaSignatureMessageX962SHA224;
//let sign_algorithm = SecKeyAlgorithm.ecdsaSignatureMessageX962SHA256;

    /**
    Creates a new cryptographic key pair in the Secure Enclave.
     
    # Arguments
     
    * 'privateKeyName' - A String used to identify the private key.
     
    # Returns
     
    A 'SEKeyPair' containing the public and private keys on success, or a 'SecureEnclaveError' on failure.
    **/
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


    /** 
    Optimized method off @create_key() to communicate with the rust-side abstraction-layer.

    # Arguments

    * 'privateKeyName' - A 'RustString' data type used to identify the private key.

    # Returns

    A String representing the private and public key.
    **/
    func rustcall_create_key(privateKeyName: RustString) -> String {
    // Add-Error-Case: If an Secure Enclave Processor does not exist.
        do{
            let keyPair = try create_key(privateKeyName: privateKeyName.toString())
            return ("Private Key: "+String((keyPair?.privateKey.hashValue)!) + "\nPublic Key: " + String((keyPair?.publicKey.hashValue)!))
        }catch{
            return ("\(error)")
        }
    }
    
    
    /**
    Creates an access control object for a cryptographic operation.
     
    #Returns
     
    A 'SecAccessControl' configured for private key usage.
    **/
    func createAccessControlObject() -> SecAccessControl {
        let access = SecAccessControlCreateWithFlags(
            kCFAllocatorDefault,
            kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
            .privateKeyUsage,
            nil)!
        return access
    }
    
    
    /**
    Encrypts data using a public key.
     
    # Arguments
     
    * 'data' - Data that has to be encrypted.
     
    * 'publicKey' - A SecKey data type representing a cryptographic public key.
     
    # Returns
     
    Data that has been encrypted on success, or a 'SecureEnclaveError' on failure.
    **/
    func encrypt_data(data: Data, publicKeyName: SecKey) throws -> Data {
        var error: Unmanaged<CFError>?
        let result = SecKeyCreateEncryptedData(publicKeyName, algorithm, data as CFData, &error)
        
        if result == nil {
            throw SecureEnclaveError.runtimeError("Error encrypting data. \(String(describing: error))")
        }
        
        return result! as Data
    }


    /** 
    Optimized method off @encrypt_data() to communicate with the rust-side abstraction-layer.

    # Arguments

    * 'data' - A 'RustString' data type used to represent the data that has to be encrypted as a String.

    * 'privateKeyName' - A 'RustString' data type used to identify the private key.

    # Returns

    A String representing the encrypted data.
    **/
    func rustcall_encrypt_data(data: RustString, publicKeyName: RustString) -> String {
        do{
            let privateKey: SecKey = try load_key(key_id: publicKeyName.toString())!
            let publicKey = getPublicKeyFromPrivateKey(privateKey: privateKey)
            let encryptedData: Data = try encrypt_data(data: data.toString().data(using: String.Encoding.utf8)!, publicKeyName: publicKey!)
            let encryptedData_string = encryptedData.base64EncodedString()
            return ("\(encryptedData_string)")
        }catch{
            return ("\(error)")
        }

    }
    
    
    /**
    Decrypts data using a private key.
     
    # Arguments
     
    * 'data' - Encrypted data that has to be decrypted.
     
    * 'privateKey' - A SecKey data type representing a cryptographic private key.
     
    # Returns
     
    Data that has been decrypted on success, or a 'SecureEnclaveError' on failure.
    **/
    func decrypt_data(data: Data, privateKey: SecKey) throws -> Data {
        //let algorithm: SecKeyAlgorithm = SecKeyAlgorithm.eciesEncryptionCofactorVariableIVX963SHA256AESGCM
        var error: Unmanaged<CFError>?
        let result = SecKeyCreateDecryptedData(privateKey, algorithm, data as CFData, &error)
        
        if result == nil {
            throw SecureEnclaveError.runtimeError("Error decrypting data. \(String(describing: error))")
        }
        
        return result! as Data
    }

    /** 
    Optimized method off @decrypt_data() to communicate with the rust-side abstraction-layer.

    # Arguments

    * 'data' - A 'RustString' data type used to represent the data that has to be decrypted as a String.

    * 'privateKeyName' - A 'RustString' data type used to identify the private key.

    # Returns

    A String representing the decrypted data.
    **/
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
    
    
    
    /**
    Retrieves the public key associated with a given private key.
     
    # Arguments
     
    * 'privateKey' - A SecKey data type representing a cryptographic private key.
     
    # Returns
     
    Optionally a public key representing a cryptographic public key on success, or 'nil' on failure
     
    **/
    func getPublicKeyFromPrivateKey(privateKey: SecKey) -> SecKey? {
        return SecKeyCopyPublicKey(privateKey)
    }
    
    
    /**
    Signs data using a private key.
     
    # Arguments
     
    * 'privateKey' - A SecKey data type representing a cryptographic private key.
     
    * 'content' - A CFData data type of the Core Foundation that has to be signed.
     
    # Returns
     
    Optionally data that has been signed as a CFData data type on success, or 'nil' on failure.
    **/
    func sign_data(data: CFData, privateKeyReference: SecKey) throws -> CFData? {
        if !SecKeyIsAlgorithmSupported(privateKeyReference, SecKeyOperationType.sign, sign_algorithm){
            throw SecureEnclaveError.runtimeError("Algorithm is not supported")
        }
        
        var error: Unmanaged<CFError>?
        guard let signed_data = SecKeyCreateSignature(privateKeyReference, sign_algorithm, data as CFData, &error)
        else{
            throw SecureEnclaveError.runtimeError("Data couldn´t be signed: \(String(describing: error))")
        }
        return signed_data
    }
    

    /** 
    Optimized method off @sign_data() to communicate with the rust-side abstraction-layer.

    # Arguments

    * 'data' - A 'RustString' data type used to represent the data that has to be signed as a String.

    * 'privateKeyName' - A 'RustString' data type used to identify the private key.

    # Returns

    A String representing the signed data.
    **/
    func rustcall_sign_data(data: RustString, privateKeyName: RustString) -> String{
        let privateKeyName_string = privateKeyName.toString()
        let data_cfdata = data.toString().data(using: String.Encoding.utf8)! as CFData

        do {
            let privateKeyReference = try load_key(key_id: privateKeyName_string)!
            let signed_data = try ((sign_data(data: data_cfdata, privateKeyReference: privateKeyReference))! as Data) 
            return signed_data.base64EncodedString(options: [])
        }catch{
            return "\(error)"
        }
    }
    
    
    /**
    Verifies a signature using a public key.
     
    # Arguments
     
    * 'publicKey - A SecKey data type representing a cryptographic public key.
     
    * 'content' - A String of the data that has to be verified.
     
    * 'signature' - A CFData data type of the Core Foundation that is the signature.
     
    # Returns
     
    A boolean if the signature is valid on success, or a 'SecureEnclaveError' on failure.
    **/
    func verify_signature(publicKey: SecKey, data: String, signature: String) throws -> Bool {
        //let sign_algorithm = SecKeyAlgorithm.ecdsaSignatureMessageX962SHA256
        guard Data(base64Encoded: signature) != nil else{
            throw SecureEnclaveError.runtimeError("Invalid message to verify")
        }
        
        guard let data_data = data.data(using: String.Encoding.utf8)
        else{
            throw SecureEnclaveError.runtimeError("Invalid message to verify")
        }
        
        var error: Unmanaged<CFError>?
        if SecKeyVerifySignature(publicKey, sign_algorithm, data_data as CFData, Data(base64Encoded: signature, options: [])! as CFData, &error){
            return true
        } else{
            return false
        }
    }


    /** 
    Optimized method off @verify_data() to communicate with the rust-side abstraction-layer.

    # Arguments

    * 'data' - A 'RustString' data type used to represent the data that has to be verified as a String.

    * 'signature' - A 'RustString' data type used to represent the signature of the signed data as a String.

    * 'publicKeyName' - A 'RustString' data type used to identify the public key.

    # Returns

    A String if the data could have been verified with the signature.
    **/
    func rustcall_verify_data(data: RustString, signature: RustString, publicKeyName: RustString) -> String{
        do{
            let publicKeyName_string = publicKeyName.toString()
            let data_string = data.toString()
            let signature_string = signature.toString()

            guard let publicKey = getPublicKeyFromPrivateKey(privateKey: try load_key(key_id: publicKeyName_string)!)else{
                throw SecureEnclaveError.runtimeError("Error getting PublicKey from PrivateKey)")
            }
            let status = try verify_signature(publicKey: publicKey, data: data_string, signature: signature_string)
            
            if status == true{
                return "true"
            }else{
                return "false"
            }

        }catch{
            return "\(error)"
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
    
    
    /**
    Loads a cryptographic private key from the keychain.
     
    # Arguments
     
    * 'key_id' - A String used as the identifier for the key
     
    # Returns
     
    Optionally the key as a SecKey data type on success, or a 'SecureEnclaveError' on failure.
    **/
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


    /** 
    Optimized method off @load_key() to communicate with the rust-side abstraction-layer.

    # Arguments

    * 'keyID' - A 'RustString' data type used to represent identifier for the key as a String.

    # Returns

    A String representing the private key as a String.
    **/
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
    
    
    /**
    Stores a cryptographic key in the keychain.
     
    # Arguments
     
    * 'name' - A String used to identify the key in the keychain.
     
    * 'privateKey' - A SecKey data type representing a cryptographic private key.
     
    # Returns
     
    A 'SecureEnclaveError' on failure.
    **/
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
    
    /**
    Inizializes a module by creating a private key and the associated private key. Optimized to communicate with the rust-side abstraction-layer.
     
    # Returns
     
    A boolean if the module has been inizializes correctly on success, or a 'SecureEnclaveError' on failure.
    **/
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






    func setAlgorithm(newAlgorithm: RustString) -> String {
        do{
            switch newAlgorithm.toString() {        
            // RSA Encryption
            case "RsaEncryptionRaw":
                algorithm = .rsaEncryptionRaw
            case "RsaEncryptionPKCS1":
                algorithm = .rsaEncryptionPKCS1
            case "RsaEncryptionOAEPSHA1":
                algorithm = .rsaEncryptionOAEPSHA1
            case "RsaEncryptionOAEPSHA224":
                algorithm = .rsaEncryptionOAEPSHA224
            case "RsaEncryptionOAEPSHA256":
                algorithm = .rsaEncryptionOAEPSHA256
            case "RsaEncryptionOAEPSHA384":
                algorithm = .rsaEncryptionOAEPSHA384
            case "RsaEncryptionOAEPSHA512":
                algorithm = .rsaEncryptionOAEPSHA512
            case "RsaEncryptionOAEPSHA1AESGCM":
                algorithm = .rsaEncryptionOAEPSHA1AESGCM
            case "RsaEncryptionOAEPSHA224AESGCM":
                algorithm = .rsaEncryptionOAEPSHA224AESGCM
            case "RsaEncryptionOAEPSHA256AESGCM":
                algorithm = .rsaEncryptionOAEPSHA256AESGCM
            case "RsaEncryptionOAEPSHA384AESGCM":
                algorithm = .rsaEncryptionOAEPSHA384AESGCM
            case "RsaEncryptionOAEPSHA512AESGCM":
                algorithm = .rsaEncryptionOAEPSHA512AESGCM

            // ECIES Encryption
            case "EciesEncryptionStandardX963SHA1AESGCM":
                algorithm = .eciesEncryptionStandardX963SHA1AESGCM
            case "EciesEncryptionStandardX963SHA224AESGCM":
                algorithm = .eciesEncryptionStandardX963SHA224AESGCM
            case "EciesEncryptionStandardX963SHA256AESGCM":
                algorithm = .eciesEncryptionStandardX963SHA256AESGCM
            case "EciesEncryptionStandardX963SHA384AESGCM":
                algorithm = .eciesEncryptionStandardX963SHA384AESGCM
            case "EciesEncryptionStandardX963SHA512AESGCM":
                algorithm = .eciesEncryptionStandardX963SHA512AESGCM
            case "EciesEncryptionCofactorX963SHA1AESGCM":
                algorithm = .eciesEncryptionCofactorX963SHA1AESGCM
            case "EciesEncryptionCofactorX963SHA224AESGCM":
                algorithm = .eciesEncryptionCofactorX963SHA224AESGCM
            case "EciesEncryptionCofactorX963SHA256AESGCM":
                algorithm = .eciesEncryptionCofactorX963SHA256AESGCM
            case "EciesEncryptionCofactorX963SHA384AESGCM":
                algorithm = .eciesEncryptionCofactorX963SHA384AESGCM
            case "EciesEncryptionCofactorX963SHA512AESGCM":
                algorithm = .eciesEncryptionCofactorX963SHA512AESGCM
            case "EciesEncryptionStandardVariableIVX963SHA224AESGCM":
                algorithm = .eciesEncryptionStandardVariableIVX963SHA224AESGCM
            case "EciesEncryptionStandardVariableIVX963SHA256AESGCM":
                algorithm = .eciesEncryptionStandardVariableIVX963SHA256AESGCM
            case "EciesEncryptionStandardVariableIVX963SHA384AESGCM":
                algorithm = .eciesEncryptionStandardVariableIVX963SHA384AESGCM
            case "EciesEncryptionStandardVariableIVX963SHA512AESGCM":
                algorithm = .eciesEncryptionStandardVariableIVX963SHA512AESGCM
            case "EciesEncryptionCofactorVariableIVX963SHA224AESGCM":
                algorithm = .eciesEncryptionCofactorVariableIVX963SHA224AESGCM
            case "EciesEncryptionCofactorVariableIVX963SHA256AESGCM":
                algorithm = .eciesEncryptionCofactorVariableIVX963SHA256AESGCM
            case "EciesEncryptionCofactorVariableIVX963SHA384AESGCM":
                algorithm = .eciesEncryptionCofactorVariableIVX963SHA384AESGCM
            case "EciesEncryptionCofactorVariableIVX963SHA512AESGCM":
                algorithm = .eciesEncryptionCofactorVariableIVX963SHA512AESGCM

            // ECDH Key Exchange
            case "EcdhKeyExchangeStandard":
                algorithm = .ecdhKeyExchangeStandard
            case "EcdhKeyExchangeStandardX963SHA1":
                algorithm = .ecdhKeyExchangeStandardX963SHA1
            case "EcdhKeyExchangeStandardX963SHA224":
                algorithm = .ecdhKeyExchangeStandardX963SHA224
            case "EcdhKeyExchangeStandardX963SHA256":
                algorithm = .ecdhKeyExchangeStandardX963SHA256
            case "EcdhKeyExchangeStandardX963SHA384":
                algorithm = .ecdhKeyExchangeStandardX963SHA384
            case "EcdhKeyExchangeStandardX963SHA512":
                algorithm = .ecdhKeyExchangeStandardX963SHA512
            case "EcdhKeyExchangeCofactor":
                algorithm = .ecdhKeyExchangeCofactor
            case "EcdhKeyExchangeCofactorX963SHA1":
                algorithm = .ecdhKeyExchangeCofactorX963SHA1
            case "EcdhKeyExchangeCofactorX963SHA224":
                algorithm = .ecdhKeyExchangeCofactorX963SHA224
            case "EcdhKeyExchangeCofactorX963SHA256":
                algorithm = .ecdhKeyExchangeCofactorX963SHA256
            case "EcdhKeyExchangeCofactorX963SHA384":
                algorithm = .ecdhKeyExchangeCofactorX963SHA384
            case "EcdhKeyExchangeCofactorX963SHA512":
                algorithm = .ecdhKeyExchangeCofactorX963SHA512
            default:
                throw SecureEnclaveError.runtimeError("Error generating a new public-private key pair. \(String(describing: newAlgorithm))")
            }
        }catch{
            return "\(error)"
        }
        return "The algorithm was set without problems"
    }


    func setSigitureAlgorithm(new_Sign_algorithm: RustString) -> String {
        do{
            switch new_Sign_algorithm.toString() {
            // RSA Signatures
            case "RsaSignatureRaw":
                sign_algorithm = .rsaSignatureRaw
            case "RsaSignatureDigestPKCS1v15Raw":
                sign_algorithm = .rsaSignatureDigestPKCS1v15Raw
            case "RsaSignatureDigestPKCS1v15SHA1":
                sign_algorithm = .rsaSignatureDigestPKCS1v15SHA1
            case "RsaSignatureDigestPKCS1v15SHA224":
                sign_algorithm = .rsaSignatureDigestPKCS1v15SHA224
            case "RsaSignatureDigestPKCS1v15SHA256":
                sign_algorithm = .rsaSignatureDigestPKCS1v15SHA256
            case "RsaSignatureDigestPKCS1v15SHA384":
                sign_algorithm = .rsaSignatureDigestPKCS1v15SHA384
            case "RsaSignatureDigestPKCS1v15SHA512":
                sign_algorithm = .rsaSignatureDigestPKCS1v15SHA512
            case "RsaSignatureMessagePKCS1v15SHA1":
                sign_algorithm = .rsaSignatureMessagePKCS1v15SHA1
            case "RsaSignatureMessagePKCS1v15SHA224":
                sign_algorithm = .rsaSignatureMessagePKCS1v15SHA224
            case "RsaSignatureMessagePKCS1v15SHA256":
                sign_algorithm = .rsaSignatureMessagePKCS1v15SHA256
            case "RsaSignatureMessagePKCS1v15SHA384":
                sign_algorithm = .rsaSignatureMessagePKCS1v15SHA384
            case "RsaSignatureMessagePKCS1v15SHA512":
                sign_algorithm = .rsaSignatureMessagePKCS1v15SHA512
            case "RsaSignatureDigestPSSSHA1":
                sign_algorithm = .rsaSignatureDigestPSSSHA1
            case "RsaSignatureDigestPSSSHA224":
                sign_algorithm = .rsaSignatureDigestPSSSHA224
            case "RsaSignatureDigestPSSSHA256":
                sign_algorithm = .rsaSignatureDigestPSSSHA256
            case "RsaSignatureDigestPSSSHA384":
                sign_algorithm = .rsaSignatureDigestPSSSHA384
            case "RsaSignatureDigestPSSSHA512":
                sign_algorithm = .rsaSignatureDigestPSSSHA512
            
            // ECDSA Signatures
            case "EcdsaSignatureDigestX962":
                sign_algorithm = .ecdsaSignatureDigestX962
            case "EcdsaSignatureDigestX962SHA1":
                sign_algorithm = .ecdsaSignatureDigestX962SHA1
            case "EcdsaSignatureDigestX962SHA224":
                sign_algorithm = .ecdsaSignatureDigestX962SHA224
            case "EcdsaSignatureDigestX962SHA256":
                sign_algorithm = .ecdsaSignatureDigestX962SHA256
            case "EcdsaSignatureDigestX962SHA384":
                sign_algorithm = .ecdsaSignatureDigestX962SHA384
            case "EcdsaSignatureDigestX962SHA512":
                sign_algorithm = .ecdsaSignatureDigestX962SHA512
            case "EcdsaSignatureMessageX962SHA1":
                sign_algorithm = .ecdsaSignatureMessageX962SHA1
            case "EcdsaSignatureMessageX962SHA224":
                sign_algorithm = .ecdsaSignatureMessageX962SHA224
            case "EcdsaSignatureMessageX962SHA256":
                sign_algorithm = .ecdsaSignatureMessageX962SHA256
            case "EcdsaSignatureMessageX962SHA384":
                sign_algorithm = .ecdsaSignatureMessageX962SHA384
            case "EcdsaSignatureMessageX962SHA512":
                sign_algorithm = .ecdsaSignatureMessageX962SHA512
            case "EcdsaSignatureDigestRFC4754":
                if #available(macOS 14.0, *) {
                    sign_algorithm = .ecdsaSignatureDigestRFC4754
                } else {
                    throw SecureEnclaveError.runtimeError("Error generating a new public-private key pair. The macOS-Version is not supported for this algorithm!")
                }
            case "EcdsaSignatureDigestRFC4754SHA1":
                if #available(macOS 14.0, *) {
                    sign_algorithm = .ecdsaSignatureDigestRFC4754SHA1
                } else {
                    throw SecureEnclaveError.runtimeError("Error generating a new public-private key pair. The macOS-Version is not supported for this algorithm!")
                }
            case "EcdsaSignatureDigestRFC4754SHA224":
                if #available(macOS 14.0, *) {
                    sign_algorithm = .ecdsaSignatureDigestRFC4754SHA224
                } else {
                    throw SecureEnclaveError.runtimeError("Error generating a new public-private key pair. The macOS-Version is not supported for this algorithm!")
                }
            case "EcdsaSignatureDigestRFC4754SHA256":
                if #available(macOS 14.0, *) {
                    sign_algorithm = .ecdsaSignatureDigestRFC4754SHA256
                } else {
                    throw SecureEnclaveError.runtimeError("Error generating a new public-private key pair. The macOS-Version is not supported for this algorithm!")
                }
            case "EcdsaSignatureDigestRFC4754SHA384":
                if #available(macOS 14.0, *) {
                    sign_algorithm = .ecdsaSignatureDigestRFC4754SHA384
                } else {
                    throw SecureEnclaveError.runtimeError("Error generating a new public-private key pair. The macOS-Version is not supported for this algorithm!")
                }
            case "EcdsaSignatureDigestRFC4754SHA512":
                if #available(macOS 14.0, *) {
                    sign_algorithm = .ecdsaSignatureDigestRFC4754SHA512
                } else {
                    throw SecureEnclaveError.runtimeError("Error generating a new public-private key pair. The macOS-Version is not supported for this algorithm!")
                }
            case "EcdsaSignatureMessageRFC4754SHA1":
                if #available(macOS 14.0, *) {
                    sign_algorithm = .ecdsaSignatureMessageRFC4754SHA1
                } else {
                    throw SecureEnclaveError.runtimeError("Error generating a new public-private key pair. The macOS-Version is not supported for this algorithm!")
                }
            case "EcdsaSignatureMessageRFC4754SHA224":
                if #available(macOS 14.0, *) {
                    sign_algorithm = .ecdsaSignatureMessageRFC4754SHA224
                } else {
                    throw SecureEnclaveError.runtimeError("Error generating a new public-private key pair. The macOS-Version is not supported for this algorithm!")
                }
            case "EcdsaSignatureMessageRFC4754SHA256":
                if #available(macOS 14.0, *) {
                    sign_algorithm = .ecdsaSignatureMessageRFC4754SHA256
                } else {
                    throw SecureEnclaveError.runtimeError("Error generating a new public-private key pair. The macOS-Version is not supported for this algorithm!")
                }
            case "EcdsaSignatureMessageRFC4754SHA384":
                if #available(macOS 14.0, *) {
                    sign_algorithm = .ecdsaSignatureMessageRFC4754SHA384
                } else {
                    throw SecureEnclaveError.runtimeError("Error generating a new public-private key pair. The macOS-Version is not supported for this algorithm!")
                }
            case "EcdsaSignatureMessageRFC4754SHA512":
                if #available(macOS 14.0, *) {
                    sign_algorithm = .ecdsaSignatureMessageRFC4754SHA512
                } else {
                    throw SecureEnclaveError.runtimeError("Error generating a new public-private key pair. The macOS-Version is not supported for this algorithm!")
                }

            default:
                throw SecureEnclaveError.runtimeError("Error generating a new public-private key pair. \(String(describing: new_Sign_algorithm))")
            }
        }catch{
            return "\(error)"
        }
        return "The signature-algorithm was set without problems"
    }

    func getAlgorithm() -> String {
        return "Algorithm = \(algorithm)"
    }
    func getSigitureAlgorithm() -> String {
        return "Algorithm = \(sign_algorithm)"
    }