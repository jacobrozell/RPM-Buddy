import Foundation

enum ILTYAlbumCatalog {
    static let albumName = "I Love Life Thank You"

    /// Title track and Boom Bap Rap from public databases; others lock earlier analyzer output as regression anchors.
    static let verificationTracks: [AlbumReferenceTrack] = [
        AlbumReferenceTrack(filenameContains: "I Love Life Thank You", expectedBPM: 93),
        AlbumReferenceTrack(filenameContains: "Willie Dynamite", expectedBPM: 88),
        AlbumReferenceTrack(filenameContains: "Love Lost", expectedBPM: 110),
        AlbumReferenceTrack(filenameContains: "Pranks 4 Players", expectedBPM: 81),
        AlbumReferenceTrack(filenameContains: "Boom Bap Rap", expectedBPM: 110),
    ]
}
