#!/usr/bin/swift

import Foundation

func addPhotoLibraryUsageDescription(to plistURL: URL, forLanguage language: String) {
	let usageDescriptions = [
		"en": "This allows images to be attached to messages.",
		"de": "Auf diese Weise können Bilder an Nachrichten anhängen."
		// TODO: Add all languages
	]
		
	guard let usageDescription = usageDescriptions[language] else {
		print("Warning: This script is missing a localization for language code “\(language)”")
		return;
	}
	
	guard let plist = NSMutableDictionary(contentsOf: plistURL) else {
		print("Warning: Unable to open plist file for language code “\(language)”")
		return
	}
	
	let usageDescriptionKey: NSString = "NSPhotoLibraryUsageDescription"
	
	guard plist.object(forKey: usageDescriptionKey) == nil else {
		print("Warning: plist for language “\(language)” has an existing value for \(usageDescriptionKey) that will not be replaced")
		return;
	}
	
	print("Info: Adding photo library usage description for language “\(language)” (“\(usageDescription)”)")
	
	plist.setObject(usageDescription, forKey: usageDescriptionKey)
	plist.write(to: plistURL, atomically: true)
}

guard CommandLine.arguments.count == 2 else {
	print("Usage: \(CommandLine.arguments[0]) path/to/Info.plist")
	exit(1)
}

let path = CommandLine.arguments[1]
let infoPlistURL = URL(fileURLWithPath: path, isDirectory: true)

guard infoPlistURL.lastPathComponent == "Info.plist",  FileManager.default.fileExists(atPath: infoPlistURL.path) else {
	print("Error: First argument must be a path to your project's Info.plist file.")
	exit(1)
}

let parentURL = infoPlistURL.deletingLastPathComponent()
let isLocalized = parentURL.lastPathComponent == "Base.lproj"

if isLocalized {
	do {
	    let children = try FileManager.default.contentsOfDirectory(at: parentURL.deletingLastPathComponent(), includingPropertiesForKeys: nil, options: [])
			
			for child in children where child.pathExtension == "lproj" {
				let language = child.deletingPathExtension().lastPathComponent	
				
				if language == "Base" {
					continue
				}
							
				let localizedInfoPlistURL = child.appendingPathComponent("Info.plist")
				
				guard FileManager.default.fileExists(atPath: localizedInfoPlistURL.path) else {
					print("Warning: Info.plist file is missing for language \(language)")
					continue
				}
				
				addPhotoLibraryUsageDescription(to: localizedInfoPlistURL, forLanguage: language)
			}
	}
	catch let error as NSError {
	    print("Error: Unable to find contents of URL \(parentURL) (\(error.description))")
	}
}

guard let basePlist = NSDictionary(contentsOf: infoPlistURL) else {
	print("Error: Unable to open base plist file “\(infoPlistURL)”")
	exit(1)
}

guard let region = basePlist.object(forKey: "CFBundleDevelopmentRegion") as? String else {
	print("Error: Unable to get development region from base plist file “\(infoPlistURL)”")
	exit(1)
}

guard let language = region.components(separatedBy: "_").first else {
	print("Error: Unable to get language from region code “\(region)”")
	exit(1)
}

addPhotoLibraryUsageDescription(to: infoPlistURL, forLanguage: language)

