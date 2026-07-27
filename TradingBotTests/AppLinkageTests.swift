import Testing
import BotDomain
import BotDataKit

@Test func appTargetCanImportPackageModules() {
    #expect(BotDomainInfo.moduleName == "BotDomain")
    #expect(LoadState<Int>.loaded(1).value == 1)
}
