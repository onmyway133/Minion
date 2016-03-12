#!/usr/bin/swift

import Foundation

enum Action: String {
  case InstallAlcatraz = "install_alcatraz"
  case Update = "update"
  case DVTPlugInCompatibilityUUID = "uuid"
  case PluginFolder = "plugin_folder"
}

// MARK: - Command
struct Command {
  static func execute(command: String, arguments: [String]) {
    let task = NSTask()
    task.launchPath = command
    task.arguments = arguments
    
    task.waitUntilExit()
    task.launch()
  }
  
  static func read(command: String, arguments: [String]) -> String {
    let task = NSTask()
    task.launchPath = command
    task.arguments = arguments
    
    let pipe = NSPipe()
    task.standardOutput = pipe
    
    let handle = pipe.fileHandleForReading
    
    task.launch()
    
    let data = handle.readDataToEndOfFile()
    let string = String(data: data, encoding: NSUTF8StringEncoding) ?? ""
    
    return string.stringByReplacingOccurrencesOfString("\n", withString: "")
  }
  
  static func cd(path path: String) {
    NSFileManager().changeCurrentDirectoryPath(path)
  }
  
  static func which(command: String) -> String {
    return Command.read("/usr/bin/which", arguments: [command])
  }
}


// MARK: - Action
struct Minion {
  static func installAlcatraz() {
    Command.execute(Command.which("curl"), arguments: ["-fsSL", "https://raw.github.com/supermarin/Alcatraz/master/Scripts/install.sh | sh"])
  }
  
  static func update() {
    
  }
  
  static func UUID() -> String {
    let uuid = Command.read(Command.which("defaults"), arguments: ["read", "/Applications/Xcode.app/Contents/Info", "DVTPlugInCompatibilityUUID"])
    
    print(uuid)
    
    return uuid
  }
  
  static func goToPluginFolder() {
    Command.execute("./PluginFolder.command", arguments: [])
  }
}


// MARK: - Main
func main(arguments: [String]) {
  guard let argument = arguments.last,
    action = Action(rawValue: argument)
    else { return }
  
  switch action {
  case .InstallAlcatraz:
    Minion.installAlcatraz()
  case .Update:
    Minion.update()
  case .DVTPlugInCompatibilityUUID:
    Minion.UUID()
  case .PluginFolder:
    Minion.goToPluginFolder()
  }
}

main(Process.arguments)
