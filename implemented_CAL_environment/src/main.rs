use crypto_layer::common::crypto::algorithms::encryption::{EccCurves, EccSchemeAlgorithm, SymmetricMode};
use crypto_layer::common::crypto::algorithms::KeyBits;
use crypto_layer::common::factory::{SecModules, SecurityModule};
use crypto_layer::tpm::core::instance::TpmType;
use crypto_layer::common::crypto::algorithms::{
    encryption::{AsymmetricEncryption, BlockCiphers},
};
use crypto_layer::tpm::macos::{SecureEnclaveConfig /*TpmProvider*/};
use crypto_layer::tpm::macos::logger::SecureEnclaveLogger;

fn main() {

    // Creating a TPM Provider
    let key_id = "3344";
    let swiftlogger = Box::new(SecureEnclaveLogger); 
    let tpm_provider = SecModules::get_instance(key_id.to_string(), SecurityModule::Tpm(TpmType::default()), Some(swiftlogger))
    .expect("Failed to create TPM provider");

    // Initializing the TPM Module 
    match tpm_provider.lock().unwrap().initialize_module() {
        Ok(()) => println!("TPM module initialized successfully"),
        Err(e) => println!("Failed to initialize TPM module: {:?}", e),
    }

    //Algoritmen Testen Asymmetric
    // let key_algorithm = AsymmetricEncryption::Ecc(EccSchemeAlgorithm::EcDsa(EccCurves::P256)); 
    // let key_algorithm = AsymmetricEncryption::Ecc(EccSchemeAlgorithm::EcDsa(EccCurves::P384)); 
    // let key_algorithm = AsymmetricEncryption::Ecc(EccSchemeAlgorithm::EcDsa(EccCurves::P521)); 
    let key_algorithm = AsymmetricEncryption::Ecc(EccSchemeAlgorithm::EcDsa(EccCurves::Secp256k1)); 

    // Algorithmen Testen Symmetric
    // let key_algorithm = BlockCiphers::Aes(SymmetricMode::Gcm, KeyBits::Bits256); 

    let config: SecureEnclaveConfig = SecureEnclaveConfig::new(Some(key_algorithm), None); 
    // Create Key
    match tpm_provider.lock().unwrap().create_key(
        key_id,
        Box::new(config),
    ) {
        Ok(()) => println!("Key created successfully"),
        Err(e) => println!("Failed to create key: {:?}", e),
    }; 

    //Encrypt Data
    let data = b"Hello, world!";

    match tpm_provider.lock().unwrap().encrypt_data(data) {
        Ok(encrypted_data) => println!("EncryptedData: {:?}", encrypted_data),
        Err(e) => println!("Failed to sign data: {:?}", e),
    }; 
    
    let encrypted_data = b"BENhQ662ksZiSQiaANnbD8/Gsr1BH58PzcQAaVq8Lm9QR9kG+4PwVpEHLAdGdhtZuK6ukGbPIdAZod92sFFAAdryX8LjbpjPZvJUjHHJCqnEBwvjWqGfciF2Aso6IQ=="; 
    match tpm_provider.lock().unwrap().decrypt_data(encrypted_data) {
        Ok(decrypted_data) => println!("DecryptedData: {:?}", String::from_utf8(decrypted_data)),
        Err(e) => println!("Failed to sign data: {:?}", e),
    }; 

    // Signing Data
    let data = b"Hello, world!";

    match tpm_provider.lock().unwrap().sign_data(data) {
        Ok(signature) => println!("Signature: {:?}", signature),
        Err(e) => println!("Failed to sign data: {:?}", e),
    }; 

    // Verifying Signature
    let data = b"Hello, world!";
    let signature: &[u8; 96] = &[77, 69, 85, 67, 73, 65, 75, 121, 66, 56, 87, 113, 81, 50, 120, 72, 73, 99, 75, 67, 70, 78, 106, 70, 84, 106, 106, 76, 84, 112, 121, 113, 75, 78, 66, 79, 120, 48, 68, 68, 66, 56, 67, 68, 115, 122, 102, 69, 65, 105, 69, 65, 52, 77, 70, 70, 69, 109, 67, 100, 113, 75, 121, 51, 120, 88, 86, 69, 73, 104, 82, 67, 66, 117, 86, 87, 85, 68, 121, 108, 86, 98, 80, 83, 52, 90, 88, 53, 70, 115, 107, 66, 87, 116, 99, 61]; 

    match tpm_provider.lock().unwrap().verify_signature(data, signature) {
        Ok(valid) => {
            if valid {
                println!("Signature is valid");
            } else {
                println!("Signature is invalid");
            }
        }
        Err(e) => println!("Failed to verify signature: {:?}", e),
    }

    println!("Ende"); 

}
