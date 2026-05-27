import SwiftUI

// MARK: - Your Live Server URL
let SERVER_URL = "https://pixelbrawl.onrender.com/api"

// MARK: - Models
struct User: Codable {
    let userId: Int
    let username: String
    let trophies: Int
    let prestige: Int
    let coins: Int
    let gems: Int
    let selectedBrawler: String
    let totalWins: Int
}

struct PlayerBrawler: Codable, Identifiable {
    let id = UUID()
    let name: String
    let powerLevel: Int
    let health: Int
    let damage: Int
    let range: Int
    let speed: Double
}

struct BattleBot: Codable, Identifiable {
    let id: Int
    let name: String
    let brawler: String
    var x: Double
    var y: Double
    var health: Double
    var alive: Bool
    let isBot: Bool
}

// MARK: - API Service
class APIService {
    static let shared = APIService()
    
    func register(username: String, password: String, completion: @escaping (Bool, Int?) -> Void) {
        let url = URL(string: "\(SERVER_URL)/register")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = ["username": username, "password": password]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { data, _, _ in
            guard let data = data else { completion(false, nil); return }
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let success = json["success"] as? Bool,
               let userId = json["user_id"] as? Int {
                completion(success, userId)
            } else {
                completion(false, nil)
            }
        }.resume()
    }
    
    func login(username: String, password: String, completion: @escaping (Bool, Int?) -> Void) {
        let url = URL(string: "\(SERVER_URL)/login")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = ["username": username, "password": password]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { data, _, _ in
            guard let data = data else { completion(false, nil); return }
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let success = json["success"] as? Bool,
               let userId = json["user_id"] as? Int {
                completion(success, userId)
            } else {
                completion(false, nil)
            }
        }.resume()
    }
    
    func getUserData(userId: Int, completion: @escaping ([String: Any]?) -> Void) {
        let url = URL(string: "\(SERVER_URL)/player/\(userId)")!
        
        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data = data else { completion(nil); return }
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
            completion(json?["player"] as? [String: Any])
        }.resume()
    }
    
    func getPlayerBrawlers(userId: Int, completion: @escaping ([PlayerBrawler]) -> Void) {
        let url = URL(string: "\(SERVER_URL)/player/\(userId)/brawlers")!
        
        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data = data else { completion([]); return }
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let brawlersData = json["brawlers"] as? [[String: Any]] {
                let brawlers = brawlersData.compactMap { dict -> PlayerBrawler? in
                    guard let name = dict["name"] as? String,
                          let powerLevel = dict["power_level"] as? Int,
                          let health = dict["health"] as? Int,
                          let damage = dict["damage"] as? Int,
                          let range = dict["range"] as? Int,
                          let speed = dict["speed"] as? Double else { return nil }
                    return PlayerBrawler(name: name, powerLevel: powerLevel, health: health, damage: damage, range: range, speed: speed)
                }
                completion(brawlers)
            } else {
                completion([])
            }
        }.resume()
    }
    
    func upgradeBrawler(userId: Int, brawlerName: String, completion: @escaping (Bool, Int?) -> Void) {
        let url = URL(string: "\(SERVER_URL)/player/\(userId)/upgrade")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = ["brawler_name": brawlerName]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { data, _, _ in
            guard let data = data else { completion(false, nil); return }
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let success = json["success"] as? Bool {
                let newLevel = json["new_level"] as? Int
                completion(success, newLevel)
            } else {
                completion(false, nil)
            }
        }.resume()
    }
    
    func startBattle(userId: Int, brawler: String, mode: String, boostMode: Bool, completion: @escaping (Int?) -> Void) {
        let url = URL(string: "\(SERVER_URL)/start_battle")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = ["user_id": userId, "brawler": brawler, "mode": mode, "boost_mode": boostMode]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { data, _, _ in
            guard let data = data else { completion(nil); return }
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let gameId = json["game_id"] as? Int {
                completion(gameId)
            } else {
                completion(nil)
            }
        }.resume()
    }
    
    func getBattleState(gameId: Int, completion: @escaping ([String: Any]?) -> Void) {
        let url = URL(string: "\(SERVER_URL)/battle_state?game_id=\(gameId)")!
        
        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data = data else { completion(nil); return }
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
            completion(json)
        }.resume()
    }
    
    func sendBattleAction(gameId: Int, userId: Int, action: String, direction: Double, targetBotId: Int?, completion: @escaping ([String: Any]?) -> Void) {
        let url = URL(string: "\(SERVER_URL)/battle_action")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        var body: [String: Any] = ["game_id": gameId, "user_id": userId, "action": action, "direction": direction]
        if let target = targetBotId {
            body["target_bot_id"] = target
        }
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { data, _, _ in
            guard let data = data else { completion(nil); return }
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
            completion(json)
        }.resume()
    }
    
    func endBattle(gameId: Int, userId: Int, placement: Int, kills: Int, completion: @escaping ([String: Any]?) -> Void) {
        let url = URL(string: "\(SERVER_URL)/end_battle")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = ["game_id": gameId, "user_id": userId, "placement": placement, "kills": kills]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { data, _, _ in
            guard let data = data else { completion(nil); return }
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
            completion(json)
        }.resume()
    }
    
    func getShopItems(completion: @escaping ([[String: Any]]) -> Void) {
        let url = URL(string: "\(SERVER_URL)/shop/items")!
        
        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data = data else { completion([]); return }
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let items = json["items"] as? [[String: Any]] {
                completion(items)
            } else {
                completion([])
            }
        }.resume()
    }
    
    func buyItem(userId: Int, itemId: Int, completion: @escaping (Bool, String?) -> Void) {
        let url = URL(string: "\(SERVER_URL)/shop/buy")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = ["user_id": userId, "item_id": itemId]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { data, _, _ in
            guard let data = data else { completion(false, nil); return }
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let success = json["success"] as? Bool {
                let message = json["message"] as? String
                completion(success, message)
            } else {
                completion(false, nil)
            }
        }.resume()
    }
    
    func getLeaderboard(completion: @escaping ([[String: Any]]) -> Void) {
        let url = URL(string: "\(SERVER_URL)/leaderboard")!
        
        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data = data else { completion([]); return }
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let leaderboard = json["leaderboard"] as? [[String: Any]] {
                completion(leaderboard)
            } else {
                completion([])
            }
        }.resume()
    }
}

// MARK: - ContentView (Main Entry Point)
struct ContentView: View {
    @State private var isLoggedIn = false
    @State private var userId: Int?
    @State private var username = ""
    
    var body: some View {
        if isLoggedIn, let userId = userId {
            MainMenuView(userId: userId, username: username)
        } else {
            LoginView(isLoggedIn: $isLoggedIn, userId: $userId, username: $username)
        }
    }
}

// MARK: - Login View
struct LoginView: View {
    @Binding var isLoggedIn: Bool
    @Binding var userId: Int?
    @Binding var username: String
    
    @State private var loginUsername = ""
    @State private var loginPassword = ""
    @State private var registerUsername = ""
    @State private var registerPassword = ""
    @State private var isRegistering = false
    @State private var errorMessage = ""
    @State private var isLoading = false
    
    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [Color.blue, Color.purple]), 
                          startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            
            VStack(spacing: 30) {
                VStack(spacing: 10) {
                    Text("PIXELBRAWL")
                        .font(.system(size: 42, weight: .bold))
                        .foregroundColor(.yellow)
                    Text("Brawl Stars Private Server")
                        .font(.caption)
                        .foregroundColor(.white)
                }
                .padding(.top, 80)
                
                if !isRegistering {
                    VStack(spacing: 20) {
                        TextField("Username", text: $loginUsername)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .autocapitalization(.none)
                            .padding(.horizontal)
                        
                        SecureField("Password", text: $loginPassword)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding(.horizontal)
                        
                        if !errorMessage.isEmpty {
                            Text(errorMessage)
                                .foregroundColor(.red)
                                .font(.caption)
                        }
                        
                        Button(action: login) {
                            if isLoading {
                                ProgressView()
                            } else {
                                Text("LOGIN")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.blue)
                                    .cornerRadius(25)
                            }
                        }
                        .disabled(isLoading)
                        .padding(.horizontal)
                        
                        Button(action: { isRegistering = true }) {
                            Text("CREATE PIXELPASS ACCOUNT")
                                .foregroundColor(.yellow)
                        }
                    }
                } else {
                    VStack(spacing: 20) {
                        TextField("Username", text: $registerUsername)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .autocapitalization(.none)
                            .padding(.horizontal)
                        
                        SecureField("Password", text: $registerPassword)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding(.horizontal)
                        
                        if !errorMessage.isEmpty {
                            Text(errorMessage)
                                .foregroundColor(.red)
                                .font(.caption)
                        }
                        
                        Button(action: register) {
                            if isLoading {
                                ProgressView()
                            } else {
                                Text("REGISTER")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.green)
                                    .cornerRadius(25)
                            }
                        }
                        .disabled(isLoading)
                        .padding(.horizontal)
                        
                        Button(action: { isRegistering = false }) {
                            Text("BACK TO LOGIN")
                                .foregroundColor(.yellow)
                        }
                    }
                }
                
                Spacer()
            }
        }
    }
    
    func login() {
        isLoading = true
        APIService.shared.login(username: loginUsername, password: loginPassword) { success, id in
            DispatchQueue.main.async {
                isLoading = false
                if success, let id = id {
                    userId = id
                    username = loginUsername
                    isLoggedIn = true
                } else {
                    errorMessage = "Invalid credentials"
                }
            }
        }
    }
    
    func register() {
        isLoading = true
        APIService.shared.register(username: registerUsername, password: registerPassword) { success, id in
            DispatchQueue.main.async {
                isLoading = false
                if success {
                    isRegistering = false
                    loginUsername = registerUsername
                    loginPassword = registerPassword
                    errorMessage = "Account created! Please login."
                } else {
                    errorMessage = "Username already exists"
                }
            }
        }
    }
}

// MARK: - Main Menu View
struct MainMenuView: View {
    let userId: Int
    let username: String
    
    @State private var trophies = 0
    @State private var prestige = 0
    @State private var coins = 0
    @State private var gems = 0
    @State private var selectedBrawler = "Shelly"
    @State private var brawlerPowerLevel = 1
    @State private var showBrawlerSelect = false
    @State private var showShop = false
    @State private var showLeaderboard = false
    @State private var boostMode = false
    @State private var isInBattle = false
    @State private var gameId: Int?
    
    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [Color(red: 0.1, green: 0.1, blue: 0.2), Color.purple]), 
                          startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            
            VStack(spacing: 15) {
                // Header
                HStack {
                    VStack(alignment: .leading) {
                        Text(username)
                            .font(.title2)
                            .foregroundColor(.white)
                        Text("🏆 \(trophies) Trophies")
                            .font(.headline)
                            .foregroundColor(.yellow)
                        Text("⭐ Prestige \(prestige)")
                            .font(.caption)
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing) {
                        HStack {
                            Image(systemName: "bitcoin.circle.fill")
                                .foregroundColor(.yellow)
                            Text("\(coins)")
                                .foregroundColor(.white)
                        }
                        HStack {
                            Image(systemName: "gemsymbol")
                                .foregroundColor(.blue)
                            Text("\(gems)")
                                .foregroundColor(.white)
                        }
                    }
                }
                .padding()
                .background(Color.black.opacity(0.4))
                .cornerRadius(15)
                .padding(.horizontal)
                
                // Selected Brawler Card
                VStack(spacing: 8) {
                    Circle()
                        .fill(getBrawlerColor(selectedBrawler))
                        .frame(width: 100, height: 100)
                        .overlay(
                            Text(selectedBrawler.prefix(2))
                                .font(.system(size: 36, weight: .bold))
                                .foregroundColor(.black)
                        )
                    
                    Text(selectedBrawler)
                        .font(.title2)
                        .foregroundColor(.white)
                    
                    Text("Power Level \(brawlerPowerLevel)")
                        .font(.caption)
                        .foregroundColor(.yellow)
                    
                    Button(action: { showBrawlerSelect = true }) {
                        Text("Change Brawler")
                            .font(.caption)
                            .foregroundColor(.yellow)
                    }
                }
                .padding()
                .background(Color.black.opacity(0.3))
                .cornerRadius(20)
                .padding(.horizontal)
                
                // Game Modes
                VStack(spacing: 12) {
                    GameModeButton(title: "SOLO SHOWDOWN", color: .red, icon: "person.fill") {
                        startGame(mode: "solo")
                    }
                    
                    GameModeButton(title: "DUO SHOWDOWN", color: .orange, icon: "person.2.fill") {
                        startGame(mode: "duo")
                    }
                    
                    GameModeButton(title: "TRIO SHOWDOWN", color: .purple, icon: "person.3.fill") {
                        startGame(mode: "trio")
                    }
                }
                .padding(.horizontal)
                
                // Boost Mode Toggle
                Toggle(isOn: $boostMode) {
                    HStack {
                        Image(systemName: "bolt.fill")
                            .foregroundColor(.yellow)
                        Text("BOOST MODE")
                            .foregroundColor(.yellow)
                            .font(.headline)
                        Text("(+200 trophies)")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
                .padding()
                .background(Color.black.opacity(0.4))
                .cornerRadius(15)
                .padding(.horizontal)
                
                // Bottom Buttons
                HStack(spacing: 30) {
                    MenuButton(title: "Shop", icon: "cart.fill", color: .green) {
                        showShop = true
                    }
                    
                    MenuButton(title: "Leaderboard", icon: "trophy.fill", color: .yellow) {
                        showLeaderboard = true
                    }
                }
                .padding(.horizontal)
                
                Spacer()
            }
        }
        .sheet(isPresented: $showBrawlerSelect) {
            BrawlerSelectView(selectedBrawler: $selectedBrawler, userId: userId, onBrawlerSelected: loadPlayerData)
        }
        .sheet(isPresented: $showShop) {
            ShopView(userId: userId)
        }
        .sheet(isPresented: $showLeaderboard) {
            LeaderboardView()
        }
        .fullScreenCover(isPresented: $isInBattle) {
            if let gameId = gameId {
                BattleView(userId: userId, gameId: gameId, boostMode: boostMode, onBattleEnd: loadPlayerData)
            }
        }
        .onAppear {
            loadPlayerData()
        }
    }
    
    func loadPlayerData() {
        APIService.shared.getUserData(userId: userId) { player in
            DispatchQueue.main.async {
                if let player = player {
                    trophies = player["trophies"] as? Int ?? 0
                    prestige = player["prestige"] as? Int ?? 0
                    coins = player["coins"] as? Int ?? 0
                    gems = player["gems"] as? Int ?? 0
                    selectedBrawler = player["selected_brawler"] as? String ?? "Shelly"
                }
            }
        }
        
        // Load brawler power level
        APIService.shared.getPlayerBrawlers(userId: userId) { brawlers in
            if let brawler = brawlers.first(where: { $0.name == selectedBrawler }) {
                DispatchQueue.main.async {
                    brawlerPowerLevel = brawler.powerLevel
                }
            }
        }
    }
    
    func startGame(mode: String) {
        APIService.shared.startBattle(userId: userId, brawler: selectedBrawler, mode: mode, boostMode: boostMode) { id in
            DispatchQueue.main.async {
                if let id = id {
                    gameId = id
                    isInBattle = true
                }
            }
        }
    }
    
    func getBrawlerColor(_ name: String) -> Color {
        let colors: [String: Color] = [
            "Shelly": .yellow, "Colt": .blue, "Edgar": .purple, "Nita": .brown,
            "Frank": .gray, "Bibi": .pink, "Jacky": .orange, "Lou": .cyan,
            "Pam": .yellow, "Sprout": .green, "Mortis": .purple, "Barley": .orange,
            "Buster": .blue, "Tara": .purple, "Mina": .green
        ]
        return colors[name] ?? .gray
    }
}

struct GameModeButton: View {
    let title: String
    let color: Color
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                Text(title)
                    .font(.headline)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(color)
            .cornerRadius(25)
        }
    }
}

struct MenuButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.title2)
                Text(title)
                    .font(.caption)
            }
            .foregroundColor(.white)
            .frame(width: 70, height: 70)
            .background(color.opacity(0.8))
            .cornerRadius(15)
        }
    }
}

// MARK: - Brawler Select View
struct BrawlerSelectView: View {
    @Binding var selectedBrawler: String
    let userId: Int
    let onBrawlerSelected: () -> Void
    @Environment(\.dismiss) var dismiss
    @State private var brawlers: [PlayerBrawler] = []
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack {
                Text("SELECT BRAWLER")
                    .font(.largeTitle)
                    .foregroundColor(.yellow)
                    .padding()
                
                ScrollView {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]) {
                        ForEach(brawlers) { brawler in
                            Button(action: {
                                selectedBrawler = brawler.name
                                onBrawlerSelected()
                                dismiss()
                            }) {
                                VStack {
                                    Circle()
                                        .fill(getBrawlerColor(brawler.name))
                                        .frame(width: 80, height: 80)
                                        .overlay(
                                            Text(brawler.name.prefix(2))
                                                .font(.title)
                                                .foregroundColor(.black)
                                        )
                                        .overlay(
                                            Circle()
                                                .stroke(selectedBrawler == brawler.name ? Color.yellow : Color.clear, lineWidth: 3)
                                        )
                                    
                                    Text(brawler.name)
                                        .font(.caption)
                                        .foregroundColor(.white)
                                    
                                    Text("Lv.\(brawler.powerLevel)")
                                        .font(.caption2)
                                        .foregroundColor(.yellow)
                                }
                                .padding()
                            }
                        }
                    }
                }
            }
        }
        .onAppear {
            APIService.shared.getPlayerBrawlers(userId: userId) { brawlers in
                DispatchQueue.main.async {
                    self.brawlers = brawlers
                }
            }
        }
    }
    
    func getBrawlerColor(_ name: String) -> Color {
        let colors: [String: Color] = [
            "Shelly": .yellow, "Colt": .blue, "Edgar": .purple, "Nita": .brown,
            "Frank": .gray, "Bibi": .pink, "Jacky": .orange, "Lou": .cyan,
            "Pam": .yellow, "Sprout": .green, "Mortis": .purple, "Barley": .orange,
            "Buster": .blue, "Tara": .purple, "Mina": .green
        ]
        return colors[name] ?? .gray
    }
}

// MARK: - Shop View
struct ShopView: View {
    let userId: Int
    @Environment(\.dismiss) var dismiss
    @State private var items: [[String: Any]] = []
    @State private var message: String?
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack {
                Text("SHOP")
                    .font(.largeTitle)
                    .foregroundColor(.yellow)
                    .padding()
                
                ScrollView {
                    ForEach(0..<items.count, id: \.self) { index in
                        let item = items[index]
                        ShopItemCard(
                            name: item["name"] as? String ?? "",
                            priceCoins: item["price_coins"] as? Int ?? 0,
                            priceGems: item["price_gems"] as? Int ?? 0,
                            description: item["description"] as? String ?? ""
                        ) {
                            buyItem(itemId: item["id"] as? Int ?? 0)
                        }
                    }
                }
                
                if let message = message {
                    Text(message)
                        .foregroundColor(.green)
                        .font(.caption)
                        .padding()
                }
                
                Button("Close") {
                    dismiss()
                }
                .foregroundColor(.yellow)
                .padding()
            }
        }
        .onAppear {
            loadShop()
        }
    }
    
    func loadShop() {
        APIService.shared.getShopItems { items in
            DispatchQueue.main.async {
                self.items = items
            }
        }
    }
    
    func buyItem(itemId: Int) {
        APIService.shared.buyItem(userId: userId, itemId: itemId) { success, msg in
            DispatchQueue.main.async {
                if success {
                    message = msg ?? "Purchase successful!"
                } else {
                    message = msg ?? "Purchase failed"
                }
            }
        }
    }
}

struct ShopItemCard: View {
    let name: String
    let priceCoins: Int
    let priceGems: Int
    let description: String
    let onBuy: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(name)
                    .font(.headline)
                    .foregroundColor(.white)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            HStack {
                if priceCoins > 0 {
                    HStack {
                        Image(systemName: "bitcoin")
                            .foregroundColor(.yellow)
                        Text("\(priceCoins)")
                            .foregroundColor(.white)
                    }
                }
                if priceGems > 0 {
                    HStack {
                        Image(systemName: "gemsymbol")
                            .foregroundColor(.blue)
                        Text("\(priceGems)")
                            .foregroundColor(.white)
                    }
                }
                
                Button(action: onBuy) {
                    Text("BUY")
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(.horizontal, 15)
                        .padding(.vertical, 5)
                        .background(Color.green)
                        .cornerRadius(10)
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.2))
        .cornerRadius(15)
        .padding(.horizontal)
    }
}

// MARK: - Leaderboard View
struct LeaderboardView: View {
    @Environment(\.dismiss) var dismiss
    @State private var leaderboard: [[String: Any]] = []
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack {
                Text("LEADERBOARD")
                    .font(.largeTitle)
                    .foregroundColor(.yellow)
                    .padding()
                
                ScrollView {
                    VStack(spacing: 10) {
                        ForEach(0..<leaderboard.count, id: \.self) { index in
                            let player = leaderboard[index]
                            HStack {
                                Text("#\(index + 1)")
                                    .font(.headline)
                                    .foregroundColor(.yellow)
                                    .frame(width: 50)
                                
                                Text(player["username"] as? String ?? "")
                                    .foregroundColor(.white)
                                
                                Spacer()
                                
                                Text("🏆 \(player["trophies"] as? Int ?? 0)")
                                    .foregroundColor(.yellow)
                                
                                Text("⭐ \(player["prestige"] as? Int ?? 0)")
                                    .foregroundColor(.white)
                            }
                            .padding()
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(10)
                            .padding(.horizontal)
                        }
                    }
                }
                
                Button("Close") {
                    dismiss()
                }
                .foregroundColor(.yellow)
                .padding()
            }
        }
        .onAppear {
            loadLeaderboard()
        }
    }
    
    func loadLeaderboard() {
        APIService.shared.getLeaderboard { leaderboard in
            DispatchQueue.main.async {
                self.leaderboard = leaderboard
            }
        }
    }
}

// MARK: - Battle View
struct BattleView: View {
    let userId: Int
    let gameId: Int
    let boostMode: Bool
    let onBattleEnd: () -> Void
    @Environment(\.dismiss) var dismiss
    
    @State private var playerHealth: Double = 100
    @State private var playerX: Double = 400
    @State private var playerY: Double = 300
    @State private var bots: [BattleBot] = []
    @State private var kills = 0
    @State private var gameOver = false
    @State private var placement = 0
    @State private var joystickActive = false
    @State private var joystickDirection = Angle.zero
    @State private var lastUpdateTime = Date()
    @State private var showResults = false
    @State private var trophiesGained = 0
    
    let moveSpeed: Double = 5
    
    var body: some View {
        ZStack {
            GeometryReader { geometry in
                ZStack {
                    // Background
                    Color(red: 0.1, green: 0.2, blue: 0.1)
                        .ignoresSafeArea()
                    
                    // Draw grass pattern
                    ForEach(0..<20) { i in
                        Circle()
                            .fill(Color.green.opacity(0.3))
                            .frame(width: 40, height: 40)
                            .position(x: CGFloat(i * 50) % 800, y: CGFloat(i * 30) % 700)
                    }
                    
                    // Draw bots
                    ForEach(bots) { bot in
                        if bot.alive {
                            BotView(bot: bot)
                                .position(x: bot.x, y: bot.y)
                        }
                    }
                    
                    // Draw player
                    PlayerView(health: playerHealth, brawlerName: "Shelly")
                        .position(x: playerX, y: playerY)
                }
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
                            let vector = CGVector(dx: value.location.x - center.x, dy: value.location.y - center.y)
                            let distance = sqrt(vector.dx * vector.dx + vector.dy * vector.dy)
                            
                            if distance > 30 {
                                let direction = Angle(radians: atan2(vector.dy, vector.dx))
                                joystickDirection = direction
                                joystickActive = true
                                
                                let deltaX = cos(direction.radians) * moveSpeed
                                let deltaY = sin(direction.radians) * moveSpeed
                                playerX += deltaX
                                playerY += deltaY
                                
                                playerX = max(50, min(750, playerX))
                                playerY = max(50, min(550, playerY))
                                
                                sendPlayerPosition(direction: direction.radians)
                            }
                        }
                        .onEnded { _ in
                            joystickActive = false
                        }
                )
                
                // Joystick visual
                if joystickActive {
                    Circle()
                        .fill(Color.white.opacity(0.3))
                        .frame(width: 100, height: 100)
                        .position(x: 80, y: geometry.size.height - 80)
                    
                    Circle()
                        .fill(Color.white.opacity(0.6))
                        .frame(width: 35, height: 35)
                        .position(
                            x: 80 + cos(joystickDirection.radians) * 35,
                            y: geometry.size.height - 80 + sin(joystickDirection.radians) * 35
                        )
                }
                
                // Attack button
                Button(action: attackNearestBot) {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 80, height: 80)
                        .overlay(
                            Image(systemName: "bolt.fill")
                                .font(.title)
                                .foregroundColor(.white)
                        )
                        .shadow(radius: 5)
                }
                .position(x: geometry.size.width - 70, y: geometry.size.height - 70)
            }
            
            // UI Overlay
            VStack {
                HStack {
                    VStack(alignment: .leading) {
                        Text("Health")
                            .font(.caption)
                            .foregroundColor(.white)
                        Rectangle()
                            .fill(Color.red)
                            .frame(width: 120, height: 8)
                            .overlay(
                                Rectangle()
                                    .fill(Color.green)
                                    .frame(width: 120 * (playerHealth / 100), height: 8),
                                alignment: .leading
                            )
                    }
                    .padding(8)
                    .background(Color.black.opacity(0.6))
                    .cornerRadius(10)
                    
                    Spacer()
                    
                    HStack {
                        Image(systemName: "skull")
                            .foregroundColor(.red)
                        Text("\(kills)")
                            .foregroundColor(.white)
                            .font(.title2)
                            .bold()
                    }
                    .padding(8)
                    .background(Color.black.opacity(0.6))
                    .cornerRadius(10)
                    
                    if boostMode {
                        Text("BOOST")
                            .font(.caption)
                            .foregroundColor(.yellow)
                            .bold()
                            .padding(8)
                            .background(Color.black.opacity(0.6))
                            .cornerRadius(10)
                    }
                }
                .padding(.top, 50)
                .padding(.horizontal)
                
                Spacer()
            }
        }
        .onAppear {
            startGameLoop()
        }
        .alert("Game Over", isPresented: $showResults) {
            Button("OK") {
                onBattleEnd()
                dismiss()
            }
        } message: {
            Text("Placement: #\(placement)\nKills: \(kills)\nTrophies: +\(trophiesGained)")
        }
    }
    
    func sendPlayerPosition(direction: Double) {
        APIService.shared.sendBattleAction(gameId: gameId, userId: userId, action: "move", direction: direction, targetBotId: nil) { _ in }
    }
    
    func attackNearestBot() {
        var nearestBot: BattleBot?
        var nearestDistance = Double.infinity
        
        for bot in bots where bot.alive {
            let dx = bot.x - playerX
            let dy = bot.y - playerY
            let distance = sqrt(dx*dx + dy*dy)
            
            if distance < nearestDistance && distance < 150 {
                nearestDistance = distance
                nearestBot = bot
            }
        }
        
        if let bot = nearestBot {
            APIService.shared.sendBattleAction(gameId: gameId, userId: userId, action: "attack", direction: 0, targetBotId: bot.id) { result in
                if let result = result {
                    DispatchQueue.main.async {
                        if let newPlayer = result["player"] as? [String: Any] {
                            playerHealth = newPlayer["health"] as? Double ?? 100
                        }
                        if let newBots = result["bots"] as? [[String: Any]] {
                            bots = newBots.compactMap { dict in
                                guard let id = dict["id"] as? Int,
                                      let name = dict["name"] as? String,
                                      let brawler = dict["brawler"] as? String,
                                      let x = dict["x"] as? Double,
                                      let y = dict["y"] as? Double,
                                      let health = dict["health"] as? Double,
                                      let alive = dict["alive"] as? Bool else { return nil }
                                return BattleBot(id: id, name: name, brawler: brawler, x: x, y: y, health: health, alive: alive, isBot: true)
                            }
                            
                            kills = bots.filter { !$0.alive }.count
                        }
                    }
                }
            }
        }
    }
    
    func startGameLoop() {
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { timer in
            APIService.shared.getBattleState(gameId: gameId) { result in
                DispatchQueue.main.async {
                    if let result = result {
                        if let gameOver = result["game_over"] as? Bool, gameOver {
                            self.gameOver = true
                            self.placement = result["placement"] as? Int ?? 10
                            timer.invalidate()
                            
                            APIService.shared.endBattle(gameId: gameId, userId: userId, placement: placement, kills: kills) { endResult in
                                if let endResult = endResult {
                                    trophiesGained = endResult["trophies_gained"] as? Int ?? 0
                                }
                                showResults = true
                            }
                        } else {
                            if let player = result["player"] as? [String: Any] {
                                playerHealth = player["health"] as? Double ?? 100
                                playerX = player["x"] as? Double ?? 400
                                playerY = player["y"] as? Double ?? 300
                            }
                            if let newBots = result["bots"] as? [[String: Any]] {
                                bots = newBots.compactMap { dict in
                                    guard let id = dict["id"] as? Int,
                                          let name = dict["name"] as? String,
                                          let brawler = dict["brawler"] as? String,
                                          let x = dict["x"] as? Double,
                                          let y = dict["y"] as? Double,
                                          let health = dict["health"] as? Double,
                                          let alive = dict["alive"] as? Bool else { return nil }
                                    return BattleBot(id: id, name: name, brawler: brawler, x: x, y: y, health: health, alive: alive, isBot: true)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

struct PlayerView: View {
    let health: Double
    let brawlerName: String
    
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.yellow)
                .frame(width: 45, height: 45)
                .overlay(
                    Circle()
                        .stroke(Color.black, lineWidth: 2)
                )
                .overlay(
                    Text(brawlerName.prefix(2))
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.black)
                )
                .shadow(radius: 3)
            
            Rectangle()
                .fill(Color.red)
                .frame(width: 50, height: 5)
                .position(x: 0, y: -28)
                .overlay(
                    Rectangle()
                        .fill(Color.green)
                        .frame(width: 50 * (health / 100), height: 5)
                        .position(x: 0, y: -28),
                    alignment: .leading
                )
        }
    }
}

struct BotView: View {
    let bot: BattleBot
    
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.red)
                .frame(width: 40, height: 40)
                .overlay(
                    Circle()
                        .stroke(Color.black, lineWidth: 2)
                )
                .overlay(
                    Text(bot.brawler.prefix(2))
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                )
                .shadow(radius: 3)
            
            Text(bot.name)
                .font(.system(size: 10))
                .foregroundColor(.white)
                .position(x: 0, y: -25)
            
            Rectangle()
                .fill(Color.red)
                .frame(width: 40, height: 4)
                .position(x: 0, y: -20)
                .overlay(
                    Rectangle()
                        .fill(Color.green)
                        .frame(width: 40 * (bot.health / 100), height: 4)
                        .position(x: 0, y: -20),
                    alignment: .leading
                )
        }
    }
}