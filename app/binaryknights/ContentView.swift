//
//  ContentView.swift
//  binaryknights
//
//  Created by Kiwan Taylan Cakir on 27.04.24.
//

import SwiftUI

struct ContentView: View {
    
    @State private var text: String = "Hello World!"
    @State private var decryptedText: String = "-"
    @State var encryptedText: String = "None"
    
    var body: some View {
        VStack(alignment: .center, spacing: 8) {
            Text("Binary Knights")
                .padding(.bottom, 30.0)
            Text("Enter the text or Key 🔒")
            TextField("Text to encrypt", text: $text)
                .disableAutocorrection(true)
                .frame(width: 250)
                .padding(5)
            
            
            Text("Decrypted key 🔓:").padding(.vertical, 16)
            Text("BlaBlaBla")
            
            Text("Key of Secure Enclave 🔓:").padding(.vertical, 16)
            Text("Auch Bla Bla Blaﬁ")
            HStack{
                Button("Encrypt") {
                    
                }.padding(.vertical, 8).padding(.horizontal).cornerRadius(8)
                Button("Decrypt") {
                    
                }.padding(.vertical, 8).padding(.horizontal).cornerRadius(8)
            }
        }
    }
}
#Preview {
    ContentView()
}
