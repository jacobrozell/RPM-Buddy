import Testing
@testable import RPMBuddy

@Suite("Accessibility identifiers")
struct AccessibilityIdentifierTests {
    @Test("Critical controls expose stable identifiers")
    func identifiers() {
        #expect(A11yID.bpmValue == "detector.bpm.value")
        #expect(A11yID.confidenceMeter == "detector.confidence.meter")
        #expect(A11yID.listenToggle == "detector.listen.toggle")
        #expect(A11yID.settingsButton == "detector.settings.button")
        #expect(A11yID.loggedTimestamp == "detector.logged.timestamp")
        #expect(A11yID.tempoAlternatives == "detector.tempo.alternatives")
    }
}
