use crypto_layer::common::crypto::algorithms::encryption::{EccCurves, EccSchemeAlgorithm};
use crypto_layer::common::crypto::algorithms::hashes::Hash;
use crypto_layer::common::factory::{SecModules, SecurityModule};
use crypto_layer::tpm::core::instance::TpmType;
use crypto_layer::common::crypto::algorithms::encryption::AsymmetricEncryption;
use crypto_layer::tpm::macos::SecureEnclaveConfig;
use crypto_layer::tpm::macos::logger::SecureEnclaveLogger;

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
