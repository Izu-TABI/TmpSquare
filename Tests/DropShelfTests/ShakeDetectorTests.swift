import Foundation
import Testing
@testable import DropShelf

struct ShakeDetectorTests {
    /// 60Hz でサンプリングした X 座標列を与え、検出したときのカーソル位置と往復の中心を返す
    private func detection(
        _ positions: [CGFloat],
        sensitivity: ShakeSensitivity = .medium
    ) -> (cursorX: CGFloat, centerX: CGFloat)? {
        var detector = ShakeDetector(configuration: .init(sensitivity))
        for (index, x) in positions.enumerated() {
            if let centerX = detector.feed(x: x, at: Double(index) / 60) {
                return (x, centerX)
            }
        }
        return nil
    }

    private func detects(_ positions: [CGFloat], sensitivity: ShakeSensitivity = .medium) -> Bool {
        detection(positions, sensitivity: sensitivity) != nil
    }

    /// center を中心に、振幅 amplitude・周期 period 秒で cycles 回往復するカーソルの軌跡
    private func wave(center: CGFloat = 500, amplitude: CGFloat, period: TimeInterval, cycles: Double) -> [CGFloat] {
        let count = Int(period * cycles * 60)
        return (0..<count).map { index in
            center + amplitude * sin(2 * .pi * Double(index) / 60 / period)
        }
    }

    /// 地点を順に直線で結んだ軌跡（1 区間 = 6 サンプル = 0.1 秒）
    private func path(_ points: [CGFloat]) -> [CGFloat] {
        var samples: [CGFloat] = []
        for (from, to) in zip(points, points.dropFirst()) {
            for step in 0..<6 {
                samples.append(from + (to - from) * CGFloat(step) / 6)
            }
        }
        samples.append(points[points.count - 1])
        return samples
    }

    @Test func quickShakeIsDetected() {
        #expect(detects(wave(amplitude: 60, period: 0.25, cycles: 2)))
    }

    @Test func steadyDragIsIgnored() {
        #expect(!detects((0..<120).map { CGFloat($0) * 8 }))
    }

    @Test func smallJitterIsIgnored() {
        #expect(!detects(wave(amplitude: 8, period: 0.1, cycles: 10)))
    }

    @Test func slowBackAndForthIsIgnored() {
        #expect(!detects(wave(amplitude: 100, period: 2, cycles: 2)))
    }

    @Test func returnsCenterOfShakeInsteadOfCursorPosition() throws {
        let result = try #require(detection(wave(center: 800, amplitude: 100, period: 0.25, cycles: 3)))
        // 検出の瞬間のカーソルは往復の端寄りにある
        #expect(abs(result.cursorX - 800) > 40)
        // シェルフは往復の中心に出す
        #expect(abs(result.centerX - 800) < 6)
    }

    @Test func centerFollowsTurningPointsOfUnevenShake() throws {
        // 右に大きく振ってから左右に往復する: 折り返し地点は 650, 450, 640
        let result = try #require(detection(path([500, 650, 450, 640, 460, 630])))
        #expect(result.centerX == 550)
    }

    @Test func lowSensitivityNeedsBiggerShake() {
        let moderateShake = wave(amplitude: 45, period: 0.25, cycles: 2)
        #expect(detects(moderateShake, sensitivity: .high))
        #expect(detects(moderateShake, sensitivity: .medium))
        #expect(!detects(moderateShake, sensitivity: .low))
    }
}
