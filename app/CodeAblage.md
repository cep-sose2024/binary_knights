#  CodeAblage

## SecureEnlcaveManager

/*Ist dieselbe Methode, generateKey() nur etwas abgändert. Die Keys werden bereits schon in generateKey() gestored. Deswegen ist die Metohde unnützlich*/
//    func generate_and_store_Key(_ tag: String) throws -> SEKeyPair? {
//        guard let accessControl = SecAccessControlCreateWithFlags(
//            kCFAllocatorDefault,
//            kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
//            .privateKeyUsage,
//            nil)
//        else{
//            throw SecureEnclaveError.runtimeError("Failed Setup Access Control") as Error
//        }
//        
//        let attributes: NSDictionary = [
//            kSecAttrKeyType: kSecAttrKeyTypeECSECPrimeRandom,
//            kSecAttrKeySizeInBits: 256,
//            kSecAttrTokenID: kSecAttrTokenIDSecureEnclave,
//            kSecPrivateKeyAttrs: [
//                kSecAttrIsPermanent: true,
//                kSecAttrApplicationTag:  tag,
//                kSecAttrAccessControl: accessControl,
//            ]
//        ]
//        
//        var error: Unmanaged<CFError>?
//        guard let privateKeyReference = SecKeyCreateRandomKey(attributes as CFDictionary, &error) else {
//            throw SecureEnclaveError.runtimeError("Error generating a new public-private key pair.")
//        }
//        
//        guard let publicKey = getPublicKeyFromPrivateKey(privateKey: privateKeyReference)
//        else{
//            throw SecureEnclaveError.runtimeError("Failed to get PublicKey from PrivateKey") as Error
//        }
//        
//        return SEKeyPair(publicKey: publicKey, privateKey: privateKeyReference)
//    }
    
//    func get_key_reference(_ tag: String) throws{
//        let query: [String: Any] = [
//            kSecClass as String: kSecClassKey,
//            kSecAttrKeyClass as String: kSecAttrKeyClassPrivate,
//            kSecAttrKeyType as String: kSecAttrKeyTypeRSA,
//            kSecAttrKeySizeInBits as String: 2048,
//            kSecAttrApplicationTag as String: tag,
//            kSecReturnRef as String: true
//        ]
//        // 2. Copy Key Reference
//        var item: CFTypeRef?
//        let status = SecItemCopyMatching(query as CFDictionary, &item)
//        guard status == errSecSuccess 
//        else {
//            throw SecureEnclaveError.runtimeError("Failed to load Key")
//        }
//    }





## Vorbereitet Methode für die Rust Brücke
///** Optimized method off @generateKeyPair() to communicate with the rust-side abstraction-layer.
// Output and input is only in string-forms possible **/
//func rustcall_generateKeyPair(publicKeyName: RustString,privateKeyName: RustString) -> String {
//    // Add-Error-Case: If an Secure Enclave Processor does not exist.
//    do{
//        let keys = try generateKeyPair(publicKeyName.toString(), privateKeyName.toString()).publicKey as! Data
//        let keysString = keys.base64EncodedString()
//        return keysString
//    }catch{
//        return ("\(error)")
//    }
//}
