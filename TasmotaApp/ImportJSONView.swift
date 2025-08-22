import SwiftUI

struct ImportJSONView: View {
    @ObservedObject var deviceManager: DeviceManager
    @Environment(\.presentationMode) var presentationMode
    @State private var jsonText = ""
    @State private var showingAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Import Devices from JSON")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .padding(.top)
                
                Text("Paste your JSON data below. The format should be:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                Text("""
                {
                    "group_name": {
                        "device_name": "ip_address",
                        "device_name2": "ip_address2"
                    }
                }
                """)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                
                TextEditor(text: $jsonText)
                    .font(.system(.body, design: .monospaced))
                    .padding(12)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .frame(minHeight: 200)
                
                Button(action: importJSON) {
                    HStack {
                        Image(systemName: "square.and.arrow.down")
                        Text("Import JSON")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(jsonText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Clear") {
                    jsonText = ""
                }
                .disabled(jsonText.isEmpty)
            )
            .alert(isPresented: $showingAlert) {
                Alert(
                    title: Text(alertTitle),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("OK")) {
                        if alertTitle == "Success" {
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                )
            }
        }
    }
    
    private func importJSON() {
        let trimmedJSON = jsonText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmedJSON.isEmpty {
            alertTitle = "Error"
            alertMessage = "Please enter JSON data"
            showingAlert = true
            return
        }
        
        if deviceManager.importFromJSON(trimmedJSON) {
            alertTitle = "Success"
            alertMessage = "Devices imported successfully!"
            showingAlert = true
        } else {
            alertTitle = "Error"
            alertMessage = "Invalid JSON format. Please check your data and try again."
            showingAlert = true
        }
    }
}

struct ImportJSONView_Previews: PreviewProvider {
    static var previews: some View {
        ImportJSONView(deviceManager: DeviceManager())
    }
}
