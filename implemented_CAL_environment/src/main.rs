use crypto_layer::common::crypto::algorithms::encryption::{EccCurves, EccSchemeAlgorithm, SymmetricMode};
use crypto_layer::common::crypto::algorithms::KeyBits;
use crypto_layer::common::factory::{SecModules, SecurityModule};
// use crypto_layer::common::traits::key_handle;
// use crypto_layer::common::traits::log_config::LogConfig;
use crypto_layer::tpm::core::instance::TpmType;
// use crypto_layer::common::error::SecurityModuleError;
use crypto_layer::common::crypto::algorithms::{
    encryption::{AsymmetricEncryption, BlockCiphers},
    // hashes::Hash,
};
// use crypto_layer::common::crypto::KeyUsage;
use crypto_layer::tpm::macos::{SecureEnclaveConfig /*TpmProvider*/};


use crypto_layer::tpm::macos::logger::SecureEnclaveLogger;

// use apple_secure_enclave_bindings::keyhandle::getAlgorithm; 
// use apple_secure_enclave_bindings::keyhandle::setAlgorithm; 


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
    
    let _bitlaenge = crypto_layer::common::crypto::algorithms::KeyBits::Bits1024;
    let _ecc_curve = EccCurves::BrainpoolP256r1;
    let _ecc_scheme_algorithm = crypto_layer::common::crypto::algorithms::encryption::EccSchemeAlgorithm::EcDsa(_ecc_curve);
    let _algo = crypto_layer::common::crypto::algorithms::encryption::AsymmetricEncryption::Ecc(_ecc_scheme_algorithm);

    // print!("Algorithmus = {}", getAlgorithm());
    
    // println!("{}\n",ffi::getAlgorithm()); crypto_layer::tpm::macos::key_handle
    

    let key_algorithm = AsymmetricEncryption::Ecc(EccSchemeAlgorithm::EcDsa(EccCurves::P256));
    let sym_algorithm = Some(BlockCiphers::Aes(SymmetricMode::Cbc, KeyBits::Bits256));
    // let hash = Some(Hash::Sha2(Sha2Bits::Sha256));
    // let key_usages = vec![KeyUsage::SignEncrypt, KeyUsage::Decrypt];
    
    let config: SecureEnclaveConfig = SecureEnclaveConfig::new(Some(key_algorithm), sym_algorithm); 

    match tpm_provider.lock().unwrap().create_key(
        key_id,
        Box::new(config),
    ) {
        Ok(()) => println!("Key created successfully"),
        Err(e) => println!("Failed to create key: {:?}", e),
    }; 

    // Signing Data
    let data = b"Hello, world!";

    match tpm_provider.lock().unwrap().sign_data(data) {
        Ok(signature) => println!("Signature: {:?}", signature),
        Err(e) => println!("Failed to sign data: {:?}", e),
    }

    // Verifying Signature
    let data = b"Hello, world!";
    let signature = b"Test"; // ... obtained signature ...

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


    println!("Hello World"); 

}
