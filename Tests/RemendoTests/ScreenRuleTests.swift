import CoreGraphics
import Testing
@testable import Remendo

/// Laptop como tela principal e um monitor externo à esquerda, um pouco mais alto.
private let laptop = CGRect(x: 0, y: 0, width: 1512, height: 982)
private let external = CGRect(x: -2560, y: 100, width: 2560, height: 1440)

/// Áreas úteis (sem menu e Dock) das mesmas telas.
private let laptopVisible = CGRect(x: 0, y: 0, width: 1512, height: 949)
private let externalVisible = CGRect(x: -2560, y: 100, width: 2560, height: 1415)

struct ScreenRuleNeighborTests {
    @Test("vai pra tela encostada na direção")
    func screenBeside() {
        #expect(ScreenRule.neighbor(of: 0, toward: .left, among: [laptop, external]) == 1)
        #expect(ScreenRule.neighbor(of: 1, toward: .right, among: [laptop, external]) == 0)
    }

    @Test("sem tela na direção, não move")
    func nothingThatWay() {
        #expect(ScreenRule.neighbor(of: 0, toward: .right, among: [laptop, external]) == nil)
        #expect(ScreenRule.neighbor(of: 0, toward: .down, among: [laptop, external]) == nil)
    }

    @Test("monitor do lado e um pouco mais alto não conta como em cima")
    func sideScreenIsNotAbove() {
        #expect(ScreenRule.neighbor(of: 0, toward: .up, among: [laptop, external]) == nil)
    }

    @Test("tela encostada ganha da diagonal mais perto")
    func besideBeatsCloserDiagonal() {
        let above = CGRect(x: 0, y: 982, width: 1920, height: 1080)
        let diagonal = CGRect(x: 1512, y: 500, width: 800, height: 600)
        #expect(ScreenRule.neighbor(of: 0, toward: .up, among: [laptop, above, diagonal]) == 1)
    }

    @Test("diagonal canto com canto conta pro eixo em que está mais longe")
    func cornerScreen() {
        let corner = CGRect(x: 1512, y: 982, width: 2560, height: 1440)
        #expect(ScreenRule.neighbor(of: 0, toward: .right, among: [laptop, corner]) == 1)
        #expect(ScreenRule.neighbor(of: 0, toward: .up, among: [laptop, corner]) == nil)
    }

    @Test("três telas em linha: pega a vizinha, não a do fim")
    func closestInRow() {
        let near = CGRect(x: -1920, y: 0, width: 1920, height: 1080)
        let far = CGRect(x: -3840, y: 0, width: 1920, height: 1080)
        #expect(ScreenRule.neighbor(of: 1, toward: .left, among: [near, laptop, far]) == 0)
    }
}

struct ScreenRuleScreenTests {
    @Test("a tela da janela é a que tem a maior parte dela")
    func largestOverlap() {
        let window = CGRect(x: -800, y: 300, width: 900, height: 600)
        #expect(ScreenRule.screen(containing: window, among: [laptop, external]) == 1)
    }

    @Test("janela fora de todas as telas fica com a mais próxima")
    func offScreen() {
        let window = CGRect(x: 3000, y: 0, width: 400, height: 300)
        #expect(ScreenRule.screen(containing: window, among: [laptop, external]) == 0)
    }
}

struct ScreenRulePlaceTests {
    @Test("maximizada continua maximizada")
    func maximized() {
        #expect(ScreenRule.place(laptopVisible, from: laptopVisible, to: externalVisible) == externalVisible)
    }

    @Test("encostada na direita continua na direita, com o mesmo tamanho")
    func keepsEdge() {
        let window = CGRect(x: externalVisible.maxX - 800, y: 300, width: 800, height: 500)
        let placed = ScreenRule.place(window, from: externalVisible, to: laptopVisible)
        #expect(placed.maxX == laptopVisible.maxX)
        #expect(placed.size == window.size)
    }

    @Test("maior que a tela de destino encolhe pra caber")
    func shrinksToFit() {
        let window = CGRect(x: -2500, y: 150, width: 2000, height: 1200)
        let placed = ScreenRule.place(window, from: externalVisible, to: laptopVisible)
        #expect(laptopVisible.contains(placed))
    }

    @Test("ida e volta devolve a janela pro mesmo lugar")
    func roundTrip() {
        let window = CGRect(x: 200, y: 150, width: 700, height: 500)
        let there = ScreenRule.place(window, from: laptopVisible, to: externalVisible)
        let back = ScreenRule.place(there, from: externalVisible, to: laptopVisible)
        #expect(abs(back.minX - window.minX) < 0.5)
        #expect(abs(back.minY - window.minY) < 0.5)
        #expect(back.size == window.size)
    }
}
