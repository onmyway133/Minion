#!/usr/bin/swift

import Foundation

enum Action: String {
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

// MARK: - Helper
struct Helper {
  static func pluginFolderPath() -> String {
    return "\(NSHomeDirectory())/Library/Application Support/Developer/Shared/Xcode/Plug-ins"
  }
}

// MARK: - Action
struct Minion {
  static func update() throws {
    print("Begin updating")
    
    let plugins = try NSFileManager().contentsOfDirectoryAtPath(Helper.pluginFolderPath()).filter { !$0.hasPrefix(".") }
    let uuid = Minion.UUID()
    
    plugins.forEach { plugin in
      print(plugin)
      
      let plist = "\(Helper.pluginFolderPath())/\(plugin)/Contents/Info.plist"
      let change = "Add :DVTPlugInCompatibilityUUIDs: string \(uuid)"
      
      Command.execute("/usr/libexec/PlistBuddy", arguments: ["-c", change, "\(plist)"])
    }
    
    print("Done. Please restart Xcoce")
  }
  
  static func UUID() -> String {
    return Command.read(Command.which("defaults"), arguments: ["read", "/Applications/Xcode.app/Contents/Info", "DVTPlugInCompatibilityUUID"])
  }
  
  static func printUUID() {
    print(Minion.UUID())
  }
  
  static func goToPluginFolder() {
    Command.execute(Command.which("open"), arguments: [Helper.pluginFolderPath()])
  }
}


// MARK: - Main
func main(arguments: [String]) {
  guard let argument = arguments.last,
    action = Action(rawValue: argument)
    else { return }
  
  switch action {
  case .Update:
    try! Minion.update()
  case .DVTPlugInCompatibilityUUID:
    Minion.printUUID()
  case .PluginFolder:
    Minion.goToPluginFolder()
  }
}

main(Process.arguments)
