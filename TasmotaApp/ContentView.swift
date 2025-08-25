import SwiftUI

#if canImport(UIKit)
import UIKit
#endif

extension Notification.Name {
    static let refreshDeviceStates = Notification.Name("refreshDeviceStates")
}

struct ContentView: View {
    @StateObject private var deviceManager = DeviceManager()
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.scenePhase) private var scenePhase
    @State private var isAddingDevice = false
    @State private var isImportingJSON = false
    @State private var refreshTimer: Timer?
    
    init() {
        // Complete navigation bar border removal for macOS
        #if targetEnvironment(macCatalyst)
        // Create completely clean appearance
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.systemBackground
        appearance.shadowColor = UIColor.clear
        appearance.shadowImage = UIImage()
        appearance.backgroundImage = UIImage()
        appearance.titleTextAttributes = [:]
        appearance.largeTitleTextAttributes = [:]
        
        // Apply to all navigation bar states
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        
        // Only set compactScrollEdgeAppearance if available
        if #available(macCatalyst 15.0, *) {
            UINavigationBar.appearance().compactScrollEdgeAppearance = appearance
        }
        
        // Remove separators and borders safely
        UINavigationBar.appearance().isTranslucent = false
        UINavigationBar.appearance().clipsToBounds = false
        UINavigationBar.appearance().layer.shadowOpacity = 0
        #endif
    }
    
    var body: some View {
        NavigationView {
            Group {
                if deviceManager.deviceGroups.isEmpty {
                    EmptyStateView(deviceManager: deviceManager, isImportingJSON: $isImportingJSON, isAddingDevice: $isAddingDevice)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 24) {
                            ForEach(deviceManager.deviceGroups) { group in
                                DeviceGroupView(groupName: group.name, deviceManager: deviceManager)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                    }
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Tasmota")
            .navigationBarTitleDisplayMode(.large)
            .overlay(
                // Cover any remaining separator line
                Rectangle()
                    .fill(Color(.systemBackground))
                    .frame(height: 1)
                    .offset(y: -1)
                , alignment: .top
            )
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if !deviceManager.deviceGroups.isEmpty {
                        Button(action: {
                            isImportingJSON = true
                        }) {
                            Image(systemName: "square.and.arrow.down")
                        }
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        isAddingDevice = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $isAddingDevice) {
                AddEditDeviceView(deviceManager: deviceManager)
                    .preferredColorScheme(.light)
            }
            .sheet(isPresented: $isImportingJSON) {
                ImportJSONView(deviceManager: deviceManager)
                    .preferredColorScheme(.light)
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .onAppear {
            startRefreshTimer()
        }
        .onDisappear {
            stopRefreshTimer()
        }
        .onChange(of: scenePhase) { newPhase in
            switch newPhase {
            case .active:
                // App came to foreground - refresh all device states
                refreshAllDeviceStates()
                startRefreshTimer()
            case .inactive, .background:
                // App went to background - stop timer to save resources
                stopRefreshTimer()
            @unknown default:
                break
            }
        }
    }
    
    private func startRefreshTimer() {
        // Stop existing timer if any
        stopRefreshTimer()
        
        // Start new timer that fires every 8 seconds
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 8.0, repeats: true) { _ in
            refreshAllDeviceStates()
        }
    }
    
    private func stopRefreshTimer() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }
    
    private func refreshAllDeviceStates() {
        // Trigger refresh for all visible device cards
        NotificationCenter.default.post(name: .refreshDeviceStates, object: nil)
    }
}

struct DeviceGroupView: View {
    let groupName: String
    @ObservedObject var deviceManager: DeviceManager
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    
    private var currentGroup: DeviceGroup? {
        deviceManager.deviceGroups.first { $0.name == groupName }
    }
    
    private var formattedGroupName: String {
        return groupName
            .replacingOccurrences(of: "_", with: " ")
            .capitalized
    }
    
    private var columnCount: Int {
        // Use single column in portrait mode on iPhone (compact width + regular height)
        // Use two columns in landscape or on iPad
        if horizontalSizeClass == .compact && verticalSizeClass == .regular {
            return 1
        } else {
            return 2
        }
    }
    
    var body: some View {
        if let group = currentGroup {
            VStack(alignment: .leading, spacing: 16) {
                Text(formattedGroupName)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .padding(.horizontal, 20)
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: columnCount), spacing: 16) {
                    ForEach(group.devices) { device in
                        DeviceCard(device: device, groupName: groupName, deviceManager: deviceManager)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
}

struct DeviceCard: View {
    let device: Device
    let groupName: String
    @ObservedObject var deviceManager: DeviceManager
    let api = TasmotaAPI()
    @State private var switchState = false
    @State private var pollState = false
    @State private var isLoading = false
    @State private var isEditingDevice = false
    @State private var hasLoadedInitialState = false
    @State private var isSettingInitialState = false
    @State private var isUpdatingFromPoll = false
    
    private var formattedDeviceName: String {
        return device.name
            .replacingOccurrences(of: "_", with: " ")
            .capitalized
    }
    
    var body: some View {
        HStack {
            Text(formattedDeviceName)
                .font(.headline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
            
            Spacer()
            
            Toggle("", isOn: $switchState)
                .onChange(of: switchState) { value in
                    print("🔍 onChange triggered for \(device.name): switchState=\(value), pollState=\(pollState), isUpdatingFromPoll=\(isUpdatingFromPoll)")
                    if hasLoadedInitialState && !isSettingInitialState && !isUpdatingFromPoll {
                        // Only call API if this is a user interaction, not a polling update
                        print("🚀 Calling toggleDevice for \(device.name) - user interaction")
                        toggleDevice()
                    } else {
                        print("⏸️ Skipping toggleDevice for \(device.name) - initial state loading or polling update")
                    }
                }
                .disabled(isLoading)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        .onAppear(perform: getInitialState)
        .onReceive(NotificationCenter.default.publisher(for: .refreshDeviceStates)) { _ in
            refreshDeviceState()
        }
        .contextMenu {
            Button(action: {
                isEditingDevice = true
            }) {
                Text("Edit")
                Image(systemName: "pencil")
            }
            
            Button(action: {
                deviceManager.deleteDevice(device, from: groupName)
            }) {
                Text("Delete")
                Image(systemName: "trash")
            }
            .foregroundColor(.red)
            
            Button(action: {
                openDeviceWebUI()
            }) {
                Text("Web UI")
                Image(systemName: "globe")
            }
        }
        .sheet(isPresented: $isEditingDevice) {
            AddEditDeviceView(deviceManager: deviceManager, device: device, groupName: groupName)
                .preferredColorScheme(.light)
        }
    }
    

    private func getInitialState() {
        print("🔄 Getting initial state for \(device.name)")
        isLoading = true
        isSettingInitialState = true
        api.getPowerState(ipAddress: device.ipAddress) { state in
            DispatchQueue.main.async {
                print("📡 Initial state for \(device.name): \(state ?? "nil")")
                isLoading = false
                if let state = state {
                    // Set both states to match the device's actual state
                    let newState = (state == "ON")
                    isUpdatingFromPoll = true
                    switchState = newState
                    pollState = newState
                    print("✅ Set switchState to \(switchState) and pollState to \(pollState) for \(device.name)")
                    hasLoadedInitialState = true // Only set this when we successfully get state
                    
                    // Reset the flag after a brief delay to ensure onChange doesn't trigger
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        isUpdatingFromPoll = false
                    }
                    
                    // Use a small delay to ensure onChange doesn't trigger before we reset the flag
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        isSettingInitialState = false
                        print("🏁 Initial state loading completed for \(device.name)")
                    }
                } else {
                    print("❌ Could not get state for \(device.name) - keeping toggle disabled")
                    isSettingInitialState = false
                    // Don't set hasLoadedInitialState = true here, so toggle remains disabled
                }
            }
        }
    }
    
    private func toggleDevice() {
        isLoading = true
        
        api.toggleDevice(ipAddress: device.ipAddress) { success in
            DispatchQueue.main.async {
                isLoading = false
                if !success {
                    // Revert the switch state if the API call fails
                    switchState.toggle()
                } else {
                    // After successful toggle, refresh the state to ensure accuracy
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        refreshDeviceState()
                    }
                }
            }
        }
    }
    
    private func refreshDeviceState() {
        // Only refresh if we have loaded initial state
        guard hasLoadedInitialState else { 
            print("⏸️ Skipping refresh for \(device.name) - initial state not loaded")
            return 
        }
        
        api.getPowerState(ipAddress: device.ipAddress) { state in
            DispatchQueue.main.async {
                if let state = state {
                    let newPollState = (state == "ON")
                    if newPollState != pollState {
                        print("🔄 Poll state changed for \(device.name): \(pollState) -> \(newPollState)")
                        pollState = newPollState
                        // Update switch state to match polled state (without triggering onChange)
                        isUpdatingFromPoll = true
                        switchState = newPollState
                        // Reset the flag after a brief delay
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            isUpdatingFromPoll = false
                        }
                    }
                }
            }
        }
    }
    
    private func openDeviceWebUI() {
        guard let url = URL(string: "http://\(device.ipAddress)") else {
            print("❌ Invalid URL for device: \(device.ipAddress)")
            return
        }
        
        // UIApplication.shared.open works for both iOS and Mac Catalyst
        UIApplication.shared.open(url)
    }
}

struct EmptyStateView: View {
    @ObservedObject var deviceManager: DeviceManager
    @Binding var isImportingJSON: Bool
    @Binding var isAddingDevice: Bool
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            VStack(spacing: 16) {
                Image(systemName: "lightbulb")
                    .font(.system(size: 64))
                    .foregroundColor(.secondary)
                
                Text("No Devices Added")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Get started by importing your devices from JSON or adding them manually")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            VStack(spacing: 16) {
                Button(action: {
                    isImportingJSON = true
                }) {
                    HStack {
                        Image(systemName: "square.and.arrow.down")
                        Text("Import from JSON")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                
                Button(action: {
                    isAddingDevice = true
                }) {
                    HStack {
                        Image(systemName: "plus")
                        Text("Add Device Manually")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemGray5))
                    .foregroundColor(.primary)
                    .cornerRadius(12)
                }
            }
            .padding(.horizontal, 40)
            
            Spacer()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
