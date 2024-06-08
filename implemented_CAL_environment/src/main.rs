use crypto_layer::common::crypto::algorithms::hashes::{Hash, Sha2Bits};
use crypto_layer::common::crypto::algorithms::KeyBits;
use crypto_layer::common::factory::{SecModules, SecurityModule};
use crypto_layer::tpm::core::instance::TpmType;
use crypto_layer::common::crypto::algorithms::encryption::AsymmetricEncryption;
use crypto_layer::tpm::macos::SecureEnclaveConfig;
use crypto_layer::tpm::macos::logger::SecureEnclaveLogger;

fn main() {

    // Creating a TPM Provider
    let key_id = "Beispiel2";
    let string = "Hello, world!";
    let swiftlogger = Box::new(SecureEnclaveLogger); 
    let tpm_provider = SecModules::get_instance(key_id.to_string(), SecurityModule::Tpm(TpmType::MacOs), Some(swiftlogger))
    .expect("Failed to create TPM provider"); 

    //Algoritmen Testen Asymmetric
    // let key_algorithm = AsymmetricEncryption::Ecc(EccSchemeAlgorithm::EcDsa(EccCurves::Secp256k1));
    let asym_algorithm = AsymmetricEncryption::Rsa(KeyBits::Bits1024);
    let hash = Hash::Sha2(Sha2Bits::Sha256); 
    let config: SecureEnclaveConfig = SecureEnclaveConfig::new( Some(asym_algorithm), Some(hash)); 
    
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
        Err(e) => println!("Failed to load Key: {:?}", e),
    }
    
    println!("\nCreating Key: - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"); 

    // Create Key
    match tpm_provider.lock().unwrap().create_key(key_id,Box::new(config.clone())) {
        Ok(()) => println!("Key created successfully"),
        Err(e) => println!("Failed to create key: {:?}", e)
    }; 

    println!("\nEncrypt Data:  - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"); 

    // Encrypt Data
    let mut encrypted_data_bytes: Vec<u8> = Vec::new();
    let data = string.as_bytes();

    match tpm_provider.lock().unwrap().encrypt_data(data) {
        Ok(encrypted_data) => {
            encrypted_data_bytes = encrypted_data;
            println!("\nEncrypted '{}' as Byte Array: \n{:?}", string, encrypted_data_bytes);
        }
        Err(e) => println!("Failed to encrypt data: {:?}", e),
    }


    println!("\nDecrypt Data: - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"); 
    
    // Decrypt Data
    match tpm_provider.lock().unwrap().decrypt_data(&encrypted_data_bytes) {
        Ok(decrypted_data) => println!("DecryptedData of {}: \n{:?}", String::from_utf8_lossy(&encrypted_data_bytes).to_string(), String::from_utf8(decrypted_data)), // String::from_utf8_lossy(bytes).to_string();
        Err(e) => println!("Failed to decrypt data: {:?}", e),
    }

    println!("\nSigning Data: - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"); 

    // Signing Data
    let mut signed_data_bytes: Vec<u8> = Vec::new(); 
    let data = string.as_bytes();

    match tpm_provider.lock().unwrap().sign_data(data) {
        Ok(signature) => {
            signed_data_bytes = signature.clone(); 
            println!("Signature of '{}' => \n{:?}", string, signature)},
        Err(e) => println!("Failed to sign data: {:?}", e),
    }; 

    println!("\nVerifying Data: - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"); 

    // Verifying Signature
    let data = string.as_bytes();

    match tpm_provider.lock().unwrap().verify_signature(data, &signed_data_bytes) {
        Ok(valid) => {
            if valid {
                println!("Signature of {} and {:?} is valid", string, signed_data_bytes);
            } else {
                println!("Signature of {} and {:?} is invalid", string, signed_data_bytes);
            }
        }
        Err(e) => println!("Failed to verify signature: {:?}", e),
    }

    println!("Ende"); 

}
