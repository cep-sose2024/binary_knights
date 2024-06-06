use crypto_layer::common::crypto::algorithms::encryption::{EccCurves, EccSchemeAlgorithm};
use crypto_layer::common::crypto::algorithms::hashes::Hash;
use crypto_layer::common::factory::{SecModules, SecurityModule};
use crypto_layer::tpm::core::instance::TpmType;
use crypto_layer::common::crypto::algorithms::encryption::AsymmetricEncryption;
use crypto_layer::tpm::macos::SecureEnclaveConfig;
use crypto_layer::tpm::macos::logger::SecureEnclaveLogger;
use crypto_layer::SecurityModuleError;

fn main() {

    // Creating a TPM Provider
    let key_id = "3344";
    let string = "Hello, world!";
    let swiftlogger = Box::new(SecureEnclaveLogger); 
    let tpm_provider = SecModules::get_instance(key_id.to_string(), SecurityModule::Tpm(TpmType::MacOs), Some(swiftlogger))
    .expect("Failed to create TPM provider"); 

    //Algoritmen Testen Asymmetric
    let key_algorithm = AsymmetricEncryption::Ecc(EccSchemeAlgorithm::EcDsa(EccCurves::Secp256k1));
    let asym_algorithm = AsymmetricEncryption::Ecc(EccSchemeAlgorithm::Null);
    let hash = Hash::Sha1; 
    let config: SecureEnclaveConfig = SecureEnclaveConfig::new(Some(key_algorithm), Some(asym_algorithm), Some(hash)); 
    
    println!("\nInitialize Module: - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"); 
    // Initialize Module
    match tpm_provider.lock().unwrap().initialize_module() {
        Ok(()) => println!("TPM module initialized successfully"),
        Err(e) => println!("Failed to initialize TPM module: {:?}", e),
    }

    println!("\nLoading Key:  - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"); 
    // Load Key
    match tpm_provider.lock().unwrap().load_key(key_id, Box::new(config.clone())) {
        Ok(()) => println!("Key existing and ready for operations"),
        Err(e) => println!("Failed to initialize TPM module: {:?}", e),
    }
    
    println!("\nCreating Key: - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"); 

    // Create Key
    match tpm_provider.lock().unwrap().create_key(key_id,Box::new(config.clone())) {
        Ok(()) => println!("Key created successfully"),
        Err(e) => println!("Failed to create key: {:?}", e),
    }; 

    println!("\nEncrypt Data:  - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"); 

    // Encrypt Data
    let data = string.as_bytes();
    match tpm_provider.lock().unwrap().encrypt_data(data) {
        Ok(encrypted_data) => println!("\nEncrypted '{}' as Byte Array: \n{:?}", string ,encrypted_data),
        Err(e) => println!("Failed to encrypt data: {:?}", e),
    }; 

    println!("\nDecrypt Data: - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"); 
    
    // Decrypt Data
    let encrypted_data_string = "BENhQ662ksZiSQiaANnbD8/Gsr1BH58PzcQAaVq8Lm9QR9kG+4PwVpEHLAdGdhtZuK6ukGbPIdAZod92sFFAAdryX8LjbpjPZvJUjHHJCqnEBwvjWqGfciF2Aso6IQ=="; 
    let encrypted_data = encrypted_data_string.as_bytes(); 

    match tpm_provider.lock().unwrap().decrypt_data(encrypted_data) {
        Ok(decrypted_data) => println!("DecryptedData of {}: \n{:?}",encrypted_data_string, String::from_utf8(decrypted_data)),
        Err(e) => println!("Failed to decrypt data: {:?}", e),
    }; 

    println!("\nSigning Data: - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"); 

    // Signing Data
    let data = string.as_bytes();
    match tpm_provider.lock().unwrap().sign_data(data) {
        Ok(signature) => println!("Signature of '{}' => \n{:?}", string, signature),
        Err(e) => println!("Failed to sign data: {:?}", e),
    }; 

    println!("\nVerifying Data: - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"); 

    // Verifying Signature
    let data = string.as_bytes();
    let signature: &[u8; 96] = &[77, 69, 81, 67, 73, 66, 49, 90, 85, 85, 72, 67, 53, 82, 68, 75, 121, 122, 83, 107, 100, 104, 119, 111, 112, 100, 101, 74, 52, 83, 88, 89, 110, 48, 84, 79, 104, 122, 111, 70, 70, 115, 103, 113, 98, 80, 57, 97, 65, 105, 65, 55, 118, 73, 69, 107, 80, 110, 51, 85, 75, 117, 110, 68, 105, 68, 115, 54, 69, 48, 90, 51, 76, 88, 49, 106, 102, 97, 117, 81, 88, 105, 73, 105, 114, 105, 72, 74, 114, 112, 52, 110, 98, 65, 61, 61]; 
    let signature_as_string: String = "[77, 69, 81, 67, 73, 66, 49, 90, 85, 85, 72, 67, 53, 82, 68, 75, 121, 122, 83, 107, 100, 104, 119, 111, 112, 100, 101, 74, 52, 83, 88, 89, 110, 48, 84, 79, 104, 122, 111, 70, 70, 115, 103, 113, 98, 80, 57, 97, 65, 105, 65, 55, 118, 73, 69, 107, 80, 110, 51, 85, 75, 117, 110, 68, 105, 68, 115, 54, 69, 48, 90, 51, 76, 88, 49, 106, 102, 97, 117, 81, 88, 105, 73, 105, 114, 105, 72, 74, 114, 112, 52, 110, 98, 65, 61, 61]".to_string(); 

    match tpm_provider.lock().unwrap().verify_signature(data, signature) {
        Ok(valid) => {
            if valid {
                println!("Signature of {} and {} is valid", string, signature_as_string);
            } else {
                println!("Signature of {} and {} is invalid", string, signature_as_string);
            }
        }
        Err(e) => println!("Failed to verify signature: {:?}", e),
    }

    println!("Ende"); 

}
