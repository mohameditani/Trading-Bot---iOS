import Testing
@testable import BotDataKit

@Test func loadedStateExposesItsValue() {
    let state = LoadState<Int>.loaded(7)
    #expect(state.value == 7)
    #expect(state.isLoading == false)
}

@Test func loadingStateHasNoValue() {
    let state = LoadState<Int>.loading
    #expect(state.value == nil)
    #expect(state.isLoading)
}
