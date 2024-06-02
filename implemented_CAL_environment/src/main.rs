use crypto_layer::common::crypto::algorithms::encryption::EccCurves;
use crypto_layer::common::factory::{SecModules, SecurityModule};
use crypto_layer::common::traits::key_handle;
use crypto_layer::common::traits::log_config::LogConfig;
use crypto_layer::tpm::core::instance::TpmType;
use crypto_layer::common::error::SecurityModuleError;
use crypto_layer::common::crypto::algorithms::{
    encryption::{AsymmetricEncryption, BlockCiphers},
    hashes::Hash,
};
use crypto_layer::common::crypto::KeyUsage;

use crypto_layer::tpm::macos::logger::SwiftLogger;

use apple_secure_enclave_bindings::keyhandle::getAlgorithm; 
use apple_secure_enclave_bindings::keyhandle::setAlgorithm; 


fn main() {

    // Creating a TPM Provider
    let key_id = "3344".to_string();
    let swiftlogger = Box::new(SwiftLogger); 
    let tpm_provider = SecModules::get_instance(key_id, SecurityModule::Tpm(TpmType::default()), Some(swiftlogger))
    .expect("Failed to create TPM provider");

    // Initializing the TPM Module 
    match tpm_provider.lock().unwrap().initialize_module() {
        Ok(()) => println!("TPM module initialized successfully"),
        Err(e) => println!("Failed to initialize TPM module: {:?}", e),
    }
    
    let bitlaenge = crypto_layer::common::crypto::algorithms::KeyBits::Bits1024;
    let eccCurve = EccCurves::BrainpoolP256r1;
    let EccSchemeAlgorithm = crypto_layer::common::crypto::algorithms::encryption::EccSchemeAlgorithm::EcDsa(eccCurve);
    let algo = crypto_layer::common::crypto::algorithms::encryption::AsymmetricEncryption::Ecc(EccSchemeAlgorithm);

    print!("Algorithmus = {}", getAlgorithm());
    
    // println!("{}\n",ffi::getAlgorithm()); crypto_layer::tpm::macos::key_handle
    

    // let sym_algorithm = Some(BlockCiphers::Aes(SymmetricMode::Cbc, KeyBits::Bits256));
    // let hash = Some(Hash::Sha2(Sha2Bits::Sha256));


// //* /// Brainpool P256r1 curve.
//     BrainpoolP256r1,
//     /// Brainpool P384r1 curve.
//     BrainpoolP384r1,
//     /// Brainpool P512r1 curve.
//     BrainpoolP512r1,
//     /// Brainpool P638 curve.
//     BrainpoolP638, */




    // use tpm_poc::common::crypto::algorithms::{KeyBits, encryption::AsymmetricEncryption};
    // use tpm_poc::common::crypto::algorithms::encryption::{AsymmetricEncryption, EccSchemeAlgorithm, EccCurves};

    // let encryption_method = AsymmetricEncryption::Ecc(EccSchemeAlgorithm::EcDsa(EccCurves::Secp256k1));




    // let key_usages = vec![KeyUsage::SignEncrypt, KeyUsage::Decrypt];
    
    // match tpm_provider.lock().unwrap().create_key(
    //     "my_key_id",
    //     key_algorithm,
    //     sym_algorithm,
    //     hash,
    //     key_usages,
    // ) {
    //     Ok(()) => println!("Key created successfully"),
    //     Err(e) => println!("Failed to create key: {:?}", e),
    // }

    // // Signing Data
    // let data = b"Hello, world!";

    // match tpm_provider.lock().unwrap().sign_data(data) {
    //     Ok(signature) => println!("Signature: {:?}", signature),
    //     Err(e) => println!("Failed to sign data: {:?}", e),
    // }

    // // Verifying Signature
    // let data = b"Hello, world!";
    // let signature = "Test"; // ... obtained signature ...

    // match tpm_provider.lock().unwrap().verify_signature(data, &signature) {
    //     Ok(valid) => {
    //         if valid {
    //             println!("Signature is valid");
    //         } else {
    //             println!("Signature is invalid");
    //         }
    //     }
    //     Err(e) => println!("Failed to verify signature: {:?}", e),
    // }

    println!("Hello World"); 

}
