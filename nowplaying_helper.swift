// nowplaying_helper.swift — run via: swift nowplaying_helper.swift
// Outputs: title|||artist|||source|||isPlaying|||duration|||elapsed|||artworkBase64
import Foundation
import AppKit

let path = "/System/Library/PrivateFrameworks/MediaRemote.framework/MediaRemote"
guard let handle = dlopen(path, RTLD_NOW) else { print("Not Playing||||||false|||0|||0|||"); exit(0) }

guard let infoSym = dlsym(handle, "MRMediaRemoteGetNowPlayingInfo"),
      let playingSym = dlsym(handle, "MRMediaRemoteGetNowPlayingApplicationIsPlaying"),
      let pidSym = dlsym(handle, "MRMediaRemoteGetNowPlayingApplicationPID") else {
    print("Not Playing||||||false|||0|||0|||"); exit(0)
}

typealias GetInfoFn = @convention(c) (DispatchQueue, @escaping @convention(block) ([String: Any]) -> Void) -> Void
typealias IsPlayingFn = @convention(c) (DispatchQueue, @escaping @convention(block) (Bool) -> Void) -> Void
typealias GetPIDFn = @convention(c) (DispatchQueue, @escaping @convention(block) (Int32) -> Void) -> Void

let getInfo = unsafeBitCast(infoSym, to: GetInfoFn.self)
let getIsPlaying = unsafeBitCast(playingSym, to: IsPlayingFn.self)
let getPID = unsafeBitCast(pidSym, to: GetPIDFn.self)

var title = "Not Playing", artist = "", playing = false, source = ""
var duration: Double = 0
var elapsed: Double = 0
var artworkBase64 = ""
var done = 0

getInfo(DispatchQueue.main) { info in
    title = info["kMRMediaRemoteNowPlayingInfoTitle"] as? String ?? "Not Playing"
    artist = info["kMRMediaRemoteNowPlayingInfoArtist"] as? String ?? ""
    duration = info["kMRMediaRemoteNowPlayingInfoDuration"] as? Double ?? 0
    elapsed = info["kMRMediaRemoteNowPlayingInfoElapsedTime"] as? Double ?? 0
    
    if let artworkData = info["kMRMediaRemoteNowPlayingInfoArtworkData"] as? Data {
        artworkBase64 = artworkData.base64EncodedString()
    }
    done += 1
}
getIsPlaying(DispatchQueue.main) { p in playing = p; done += 1 }
getPID(DispatchQueue.main) { pid in
    if pid > 0, let app = NSRunningApplication(processIdentifier: pid) { source = app.localizedName ?? "" }
    done += 1
}

// Run loop is required for MediaRemote callbacks to fire
RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.5))
print("\(title)|||\(artist)|||\(source)|||\(playing)|||\(duration)|||\(elapsed)|||\(artworkBase64)")
