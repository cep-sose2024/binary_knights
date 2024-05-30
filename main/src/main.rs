// use std::{path::PathBuf, process::Command};
#![allow(unused)]

fn main() {
    // Ausführen des Signatur-Skripts
    // let status = Command::new("sh")
    //     .arg("codesigning.sh")
    //     .status()
    //     .expect("Failed to execute codesigning.sh");

    // if !status.success() {
    //     panic!("codesigning.sh failed");
    // }
    //This Teststring is Used in Encrypt, Sign and Verify
    let test_string = "Hello World"; 

    // Modul gets initialized. When initialization was successfull than the process proceed.
    println!("\n"); 
    if ffi::initializeModule() == true {
        println!("Initialize Module: true"); 
        println!("\n"); 

        let priv_key: String = "3344".to_string(); 
        println!("{}", ffi::rustcall_create_key(priv_key)); 
        println!("\n"); 

        println!("before set algorithms:\n");
        println!("{}\n",ffi::getAlgorithm());
        println!("{}\n",ffi::getSigitureAlgorithm());
        ffi::setAlgorithm(format!("{:?}", SecKeyAlgorithm::EciesEncryptionCofactorVariableIVX963SHA256AESGCM).to_string());
        ffi::setSigitureAlgorithm(format!("{:?}", SecKeyAlgorithm::EcdsaSignatureMessageX962SHA256).to_string());
        println!("after set algorithms:\n");
        println!("{}\n",ffi::getAlgorithm());
        println!("{}\n",ffi::getSigitureAlgorithm());
        println!("\n"); 
       
        println!("Loaded Key Hash: {}", ffi::rustcall_load_key("3344".to_string()));
        println!("\n");

        let encrypted_data = ffi::rustcall_encrypt_data(test_string.to_string(), "3344".to_string()); 
        println!("Encrypted Data of {}:  {}", test_string.to_string(), encrypted_data);
        println!("\n"); 

        let decrypted_data = ffi::rustcall_decrypt_data(encrypted_data, "3344".to_string()); 
        println!("Decrypted Data: {}", decrypted_data); 
        println!("\n"); 

        let signed_data = ffi::rustcall_sign_data(test_string.to_string(),"3344".to_string()); 
        println!("Signed Data: {}", signed_data); 
        println!("\n");

        println!("Verify Signature: {}", ffi::rustcall_verify_data(test_string.to_string(), signed_data.to_string(), "3344".to_string())); 
        println!("\n"); 
    }else{
        println!("Initialize Module: false")
    }
}

#[swift_bridge::bridge]
pub mod ffi{
    // Swift-Methods can be used in Rust 
    extern "Swift" {
        fn rustcall_create_key(privateKeyName: String) -> String;
        fn initializeModule() -> bool; 
        fn rustcall_load_key(keyID: String) -> String;
        fn rustcall_encrypt_data(data: String, publicKeyName: String) -> String; 
        fn rustcall_decrypt_data(data: String, privateKeyName: String) -> String; 
        fn rustcall_sign_data(data: String, privateKeyName: String) -> String;
        fn rustcall_verify_data(data: String, signature: String, publicKeyName: String) -> String; 
        fn setAlgorithm(newAlgorithm: String) -> String;
        fn setSigitureAlgorithm(new_Sign_algorithm: String) -> String;
        fn getAlgorithm() -> String;
        fn getSigitureAlgorithm() -> String;
    }
}

/*
getestet wurden folgende:
    let algorithm: SecKeyAlgorithm = SecKeyAlgorithm.eciesEncryptionCofactorVariableIVX963SHA256AESGCM
    let sign_algorithm: SecKeyAlgorithm = SecKeyAlgorithm.ecdsaSignatureMessageX962SHA256
*/
#[derive(Debug)]
enum SecKeyAlgorithm {
    // RSA Signatures
    RsaSignatureRaw,
    RsaSignatureDigestPKCS1v15Raw,
    RsaSignatureDigestPKCS1v15SHA1,
    RsaSignatureDigestPKCS1v15SHA224,
    RsaSignatureDigestPKCS1v15SHA256,
    RsaSignatureDigestPKCS1v15SHA384,
    RsaSignatureDigestPKCS1v15SHA512,
    RsaSignatureMessagePKCS1v15SHA1,
    RsaSignatureMessagePKCS1v15SHA224,
    RsaSignatureMessagePKCS1v15SHA256,
    RsaSignatureMessagePKCS1v15SHA384,
    RsaSignatureMessagePKCS1v15SHA512,
    RsaSignatureDigestPSSSHA1,
    RsaSignatureDigestPSSSHA224,
    RsaSignatureDigestPSSSHA256,
    RsaSignatureDigestPSSSHA384,
    RsaSignatureDigestPSSSHA512,
    RsaSignatureMessagePSSSHA1,
    RsaSignatureMessagePSSSHA224,
    RsaSignatureMessagePSSSHA256,
    RsaSignatureMessagePSSSHA384,
    RsaSignatureMessagePSSSHA512,
    
    // ECDSA Signatures
    EcdsaSignatureDigestX962,
    EcdsaSignatureDigestX962SHA1,
    EcdsaSignatureDigestX962SHA224,
    EcdsaSignatureDigestX962SHA256,
    EcdsaSignatureDigestX962SHA384,
    EcdsaSignatureDigestX962SHA512,
    EcdsaSignatureMessageX962SHA1,
    EcdsaSignatureMessageX962SHA224,
    EcdsaSignatureMessageX962SHA256,
    EcdsaSignatureMessageX962SHA384,
    EcdsaSignatureMessageX962SHA512,
    EcdsaSignatureDigestRFC4754,
    EcdsaSignatureDigestRFC4754SHA1,
    EcdsaSignatureDigestRFC4754SHA224,
    EcdsaSignatureDigestRFC4754SHA256,
    EcdsaSignatureDigestRFC4754SHA384,
    EcdsaSignatureDigestRFC4754SHA512,
    EcdsaSignatureMessageRFC4754SHA1,
    EcdsaSignatureMessageRFC4754SHA224,
    EcdsaSignatureMessageRFC4754SHA256,
    EcdsaSignatureMessageRFC4754SHA384,
    EcdsaSignatureMessageRFC4754SHA512,
    
    // RSA Encryption
    RsaEncryptionRaw,
    RsaEncryptionPKCS1,
    RsaEncryptionOAEPSHA1,
    RsaEncryptionOAEPSHA224,
    RsaEncryptionOAEPSHA256,
    RsaEncryptionOAEPSHA384,
    RsaEncryptionOAEPSHA512,
    RsaEncryptionOAEPSHA1AESGCM,
    RsaEncryptionOAEPSHA224AESGCM,
    RsaEncryptionOAEPSHA256AESGCM,
    RsaEncryptionOAEPSHA384AESGCM,
    RsaEncryptionOAEPSHA512AESGCM,
    
    // ECIES Encryption
    EciesEncryptionStandardX963SHA1AESGCM,
    EciesEncryptionStandardX963SHA224AESGCM,
    EciesEncryptionStandardX963SHA256AESGCM,
    EciesEncryptionStandardX963SHA384AESGCM,
    EciesEncryptionStandardX963SHA512AESGCM,
    EciesEncryptionCofactorX963SHA1AESGCM,
    EciesEncryptionCofactorX963SHA224AESGCM,
    EciesEncryptionCofactorX963SHA256AESGCM,
    EciesEncryptionCofactorX963SHA384AESGCM,
    EciesEncryptionCofactorX963SHA512AESGCM,
    EciesEncryptionStandardVariableIVX963SHA224AESGCM,
    EciesEncryptionStandardVariableIVX963SHA256AESGCM,
    EciesEncryptionStandardVariableIVX963SHA384AESGCM,
    EciesEncryptionStandardVariableIVX963SHA512AESGCM,
    EciesEncryptionCofactorVariableIVX963SHA224AESGCM,
    EciesEncryptionCofactorVariableIVX963SHA256AESGCM,
    EciesEncryptionCofactorVariableIVX963SHA384AESGCM,
    EciesEncryptionCofactorVariableIVX963SHA512AESGCM,
    
    // ECDH Key Exchange
    EcdhKeyExchangeStandard,
    EcdhKeyExchangeStandardX963SHA1,
    EcdhKeyExchangeStandardX963SHA224,
    EcdhKeyExchangeStandardX963SHA256,
    EcdhKeyExchangeStandardX963SHA384,
    EcdhKeyExchangeStandardX963SHA512,
    EcdhKeyExchangeCofactor,
    EcdhKeyExchangeCofactorX963SHA1,
    EcdhKeyExchangeCofactorX963SHA224,
    EcdhKeyExchangeCofactorX963SHA256,
    EcdhKeyExchangeCofactorX963SHA384,
    EcdhKeyExchangeCofactorX963SHA512,
}



