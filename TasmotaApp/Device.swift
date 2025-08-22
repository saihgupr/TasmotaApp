import Foundation

struct Device: Identifiable, Hashable, Equatable {
    let id: UUID
    var name: String
    var ipAddress: String
    
    init(id: UUID = UUID(), name: String, ipAddress: String) {
        self.id = id
        self.name = name
        self.ipAddress = ipAddress
    }
    
    static func == (lhs: Device, rhs: Device) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

struct DeviceGroup: Identifiable {
    let id = UUID()
    let name: String
    var devices: [Device]
}

class DeviceManager: ObservableObject {
    @Published var deviceGroups: [DeviceGroup] = []
    private let devicesUrl: URL

    init() {
        let fileManager = FileManager.default
        let urls = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
        self.devicesUrl = urls[0].appendingPathComponent("devices.json")
        
        // Only load devices if the file exists (don't copy from bundle)
        if fileManager.fileExists(atPath: devicesUrl.path) {
            loadDevices()
        }
    }

    func loadDevices() {
        do {
            let data = try Data(contentsOf: devicesUrl)
            let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: [String: String]]
            
            if let json = json {
                self.deviceGroups = json.map { groupName, devicesJson in
                    let devices = devicesJson.map { deviceName, ipAddress in
                        Device(name: deviceName, ipAddress: ipAddress)
                    }
                    return DeviceGroup(name: groupName, devices: devices.sorted(by: { $0.name < $1.name }))
                }.sorted(by: { $0.name < $1.name })
            }
        } catch {
            print("Error decoding devices.json: \(error)")
        }
    }
    
    func saveDevices() {
        var json: [String: [String: String]] = [:]
        
        for group in deviceGroups {
            var devicesJson: [String: String] = [:]
            for device in group.devices {
                devicesJson[device.name] = device.ipAddress
            }
            json[group.name] = devicesJson
        }
        
        do {
            let data = try JSONSerialization.data(withJSONObject: json, options: .prettyPrinted)
            try data.write(to: devicesUrl)
        } catch {
            print("Error saving devices.json: \(error)")
        }
    }
    
    func addDevice(_ device: Device, to groupName: String) {
        if let index = deviceGroups.firstIndex(where: { $0.name == groupName }) {
            deviceGroups[index].devices.append(device)
            deviceGroups[index].devices.sort(by: { $0.name < $1.name })
        } else {
            let newGroup = DeviceGroup(name: groupName, devices: [device])
            deviceGroups.append(newGroup)
            deviceGroups.sort(by: { $0.name < $1.name })
        }
        
        saveDevices()
    }
    
    func editDevice(_ oldDevice: Device, to newDevice: Device, in newGroupName: String) {
        if let oldGroupIndex = deviceGroups.firstIndex(where: { $0.devices.contains(where: { $0.id == oldDevice.id }) }) {
            let oldGroupName = deviceGroups[oldGroupIndex].name
            
            // If the group is the same, just update the device
            if oldGroupName == newGroupName {
                if let deviceIndex = deviceGroups[oldGroupIndex].devices.firstIndex(where: { $0.id == oldDevice.id }) {
                    deviceGroups[oldGroupIndex].devices[deviceIndex] = newDevice
                    deviceGroups[oldGroupIndex].devices.sort(by: { $0.name < $1.name })
                }
            } else {
                // If the group has changed, delete the old device and add the new one
                deleteDevice(oldDevice, from: oldGroupName)
                addDevice(newDevice, to: newGroupName)
            }
        }
        
        saveDevices()
    }
    
    func deleteDevice(_ device: Device, from groupName: String) {
        if let groupIndex = deviceGroups.firstIndex(where: { $0.name == groupName }) {
            deviceGroups[groupIndex].devices.removeAll(where: { $0.id == device.id })
            
            if deviceGroups[groupIndex].devices.isEmpty {
                deviceGroups.remove(at: groupIndex)
            }
        }
        
        saveDevices()
    }
    
    func importFromJSON(_ jsonString: String) -> Bool {
        guard let data = jsonString.data(using: .utf8) else {
            return false
        }
        
        do {
            let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: [String: String]]
            
            if let json = json {
                self.deviceGroups = json.map { groupName, devicesJson in
                    let devices = devicesJson.map { deviceName, ipAddress in
                        Device(name: deviceName, ipAddress: ipAddress)
                    }
                    return DeviceGroup(name: groupName, devices: devices.sorted(by: { $0.name < $1.name }))
                }.sorted(by: { $0.name < $1.name })
                
                saveDevices()
                return true
            }
        } catch {
            print("Error parsing JSON: \(error)")
        }
        
        return false
    }
}