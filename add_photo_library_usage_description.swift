#!/usr/bin/swift

import Foundation

func addPhotoLibraryUsageDescription(to plistURL: URL, forLanguage language: String) {
	let usageDescriptions = [
		"ar": "يُتيح ذلك إرفاق الصور بالرسائل.",
		"da": "Dette giver mulighed for, at billeder kan vedhæftes beskeder.",
		"de": "Dies erlaubt das Anhängen von Bildern an einer Nachricht",
		"el": "Αυτό επιτρέπει στις εικόνες να επισυναφθούν στα μηνύματα.",
		"en": "This allows images to be attached to messages.",
		"es": "Esto permite adjuntar fotografías a los mensajes.",
		"fr-CA": "Ceci permet que des images soient ajoutées en pièce jointe aux messages.",
		"fr": "Ceci permet aux images d'être incluses aux messages.",
		"it": "Ciò consente di allegare immagini ai messaggi.",
		"ja": "これによって画像をメッセージに添付できます。",
		"ko": "이렇게 하면 이미지를 메시지에 첨부할 수 있습니다.",
		"nl": "Hiermee kunnen afbeeldingen aan berichten worden bijgevoegd.",
		"pl": "To pozwala na załączanie zdjęć do wiadomości.",
		"pt-BR": "Isso permite que as imagens sejam anexadas às mensagens.",
		"pt": "Isto permite que imagens sejam anexadas a mensagens.",
		"ru": "Это позволяет прикреплять изображения к сообщениям.",
		"sv": "Detta gör att bilder kan bifogas i meddelanden.",
		"tr": "Bu, mesajlara görüntü eklenmesini sağlar.",
		"zh-Hans": "这能让图片作为消息的附件。",
		"zh-Hant": "這能讓圖片作為消息的附件。"
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

