
import Foundation

class TasmotaAPI {
    func toggleDevice(ipAddress: String, completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: "http://\(ipAddress)/cm?cmnd=Power%20Toggle") else {
            completion(false)
            return
        }

        URLSession.shared.dataTask(with: url) { _, response, error in
            if let error = error {
                print("Error toggling device: \(error)")
                completion(false)
                return
            }

            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                print("Invalid response from device")
                completion(false)
                return
            }

            completion(true)
        }.resume()
    }

    func getPowerState(ipAddress: String, completion: @escaping (String?) -> Void) {
        guard let url = URL(string: "http://\(ipAddress)/cm?cmnd=Power") else {
            print("Invalid URL for device at \(ipAddress)")
            completion(nil)
            return
        }

        print("Fetching power state from \(ipAddress)")
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Network error getting power state from \(ipAddress): \(error)")
                completion(nil)
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                print("Invalid response from \(ipAddress)")
                completion(nil)
                return
            }

            guard httpResponse.statusCode == 200 else {
                print("HTTP error \(httpResponse.statusCode) from \(ipAddress)")
                completion(nil)
                return
            }

            guard let data = data else {
                print("No data received from \(ipAddress)")
                completion(nil)
                return
            }

            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let powerState = json["POWER"] as? String {
                    print("Power state for \(ipAddress): \(powerState)")
                    completion(powerState)
                } else {
                    print("Invalid JSON response from \(ipAddress): \(String(data: data, encoding: .utf8) ?? "unknown")")
                    completion(nil)
                }
            } catch {
                print("Error decoding power state from \(ipAddress): \(error)")
                completion(nil)
            }
        }.resume()
    }
}
