import SwiftUI

struct AddEditDeviceView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var deviceManager: DeviceManager
    
    @State private var name = ""
    @State private var ipAddress = ""
    @State private var selectedGroup = ""
    @State private var newGroupName = ""
    
    var device: Device?
    var groupName: String?
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Device Details")) {
                    TextField("Name", text: $name)
                    TextField("IP Address", text: $ipAddress)
                }
                
                Section(header: Text("Group")) {
                    Picker("Select Group", selection: $selectedGroup) {
                        ForEach(deviceManager.deviceGroups.map { $0.name }, id: \.self) { group in
                            Text(group).tag(group)
                        }
                        Text("New Group").tag("New Group")
                    }
                    
                    if selectedGroup == "New Group" {
                        TextField("New Group Name", text: $newGroupName)
                    }
                }
            }
            .navigationTitle(device == nil ? "Add Device" : "Edit Device")
            .navigationBarItems(leading: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            }, trailing: Button("Save") {
                saveDevice()
                presentationMode.wrappedValue.dismiss()
            })
            .onAppear(perform: setup)
        }
    }
    
    private func setup() {
        if let device = device {
            name = device.name
            ipAddress = device.ipAddress
        }
        
        if let groupName = groupName {
            selectedGroup = groupName
        } else if !deviceManager.deviceGroups.isEmpty {
            selectedGroup = deviceManager.deviceGroups[0].name
        }
    }
    
    private func saveDevice() {
        let group: String
        if selectedGroup == "New Group" {
            group = newGroupName
        } else {
            group = selectedGroup
        }
        
        if let device = device {
            // Preserve the original device's ID when editing
            var updatedDevice = device
            updatedDevice.name = name
            updatedDevice.ipAddress = ipAddress
            deviceManager.editDevice(device, to: updatedDevice, in: group)
        } else {
            // Create new device for adding
            let newDevice = Device(name: name, ipAddress: ipAddress)
            deviceManager.addDevice(newDevice, to: group)
        }
    }
}

