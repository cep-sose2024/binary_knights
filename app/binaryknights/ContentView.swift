//
//  ContentView.swift
//  binaryknights
//
//  Created by Kiwan Taylan Cakir on 04.05.24.
//

import SwiftUI

struct ContentView: View {
    
    @State private var input: String = "Hello World!"
    @State private var decryptedText: String = "-"
    @State var encryptedText: String = "None"
    @State var signature: CFData = "".data(using: .utf8)! as CFData
    let enclaveManager = SecureEnclaveManager()
    var SEkeyPair: SecureEnclaveManager.SEKeyPair?
    
    init() {
        do {
          SEkeyPair = try enclaveManager.generateKeyPair("priVAteK$y")
            print("Successful generated KeyPair")
        } catch {
            print("\(error)")
        }
    }
    
    
    var body: some View {
        VStack(alignment: .center, spacing: 8) {
            Text("Binary Knights")
                .padding(.bottom, 30.0)
            Text("Enter the text or Key 🔒")
            TextField("Text to encrypt", text: $input)
                .disableAutocorrection(true)
                .frame(width: 250)
                .padding(5)
            
            Text("Decrypted key 🔒")
            TextField("Decrypted key 🔓:", text: $decryptedText)
                .padding(.vertical, 16)
            Text(decryptedText)
                .font(.system(size: 12))
            
            
            Text("Key of Secure Enclave 🔒")
            TextField("Key of Secure Enclave 🔓:", text: $encryptedText)
                .font(.system(size: 12))
            
            VStack {
                HStack{
                    Button("Encrypt") {
                        do{
                            print(SEkeyPair!.privateKey.hashValue as Any)
                            print("private Key: "+String((SEkeyPair?.privateKey.hashValue)!))
                            encryptedText = try enclaveManager.encrypt(data: input.data(using: .utf8)!, publicKey: SEkeyPair!.publicKey).base64EncodedString()
                            
                        } catch {
                            print("Unbehandelter Error!")
                        }
                        //Logik-Methodenaufruf aus Klasse SecureEnclavemanager
                    }.padding(.vertical, 8).padding(.horizontal).cornerRadius(8)
                    
                    Button("Decrypt") {
                        do{
                            print("private Key: "+String((SEkeyPair?.privateKey.hashValue)!))
                            let data = Data(base64Encoded: input)
                            let bla = try enclaveManager.decrypt(data!, privateKey: SEkeyPair!.privateKey)
                            
                            decryptedText = String(data: bla, encoding: .utf8)!
                            
                        } catch {
                            print("Unbehandelter Fehler: \(error)")
                        }
                    }.padding(.vertical, 8).padding(.horizontal).cornerRadius(8)
                    
                    Button("Switch") {
                        input = encryptedText
                    }}
                HStack{
                    Button("Signing Data"){
                        do{
                            signature = try enclaveManager.signing_data(SEkeyPair!.privateKey, input.data(using: String.Encoding.utf8)! as CFData)!
                        }catch{
                            input = ("\(error)")
                        }
                    }.padding(.vertical, 8).padding(.horizontal).cornerRadius(8)
                    
                    Button("Verify") {
                        do{
                            if try enclaveManager.verify_data(SEkeyPair!.publicKey, input, signature){
                                input = "true"
                            }
                        }catch{
                            input = "false"
                        }
                    }.padding(.vertical, 8).padding(.horizontal).cornerRadius(8)
                    
                    Button("getKey") {
                        do{
                            let loadedKey = try SecureEnclaveManager.loadKey(name: input)
                            print("Key Referenze wurde geladen")
                        }catch{
                            print("\(error)")
                        }
                    }.padding(.vertical, 8).padding(.horizontal).cornerRadius(8)
                }
                HStack{
                    Button("StoreKey") {
                        do{
                            try enclaveManager.storeKey_Keychain(input, SEkeyPair!.privateKey)
                            print("Key wurde gestored")
                        }catch{
                            print("\(error)")
                        }
                    }
                }
            }
        }
    }
}
#Preview {
    ContentView()
}
