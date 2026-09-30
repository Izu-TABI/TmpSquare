import Foundation

/// カーソルの左右の往復（シェイク）を検出する
///
/// 一定距離以上動いてから一定距離以上戻ったときだけ「折り返し」と数えるので、
/// ゆっくりしたドラッグや手ぶれでは反応しない。
struct ShakeDetector {
    struct Configuration {
        /// 折り返しとみなす最小移動距離（pt）
        var minTravel: CGFloat
        /// この時間内に必要な回数の折り返しがあればシェイクとみなす（秒）
        var window: TimeInterval
        /// 必要な折り返し回数
        var reversals: Int

        init(_ sensitivity: ShakeSensitivity) {
            switch sensitivity {
            case .low: self = .init(minTravel: 60, window: 0.5, reversals: 4)
            case .medium: self = .init(minTravel: 40, window: 0.6, reversals: 3)
            case .high: self = .init(minTravel: 25, window: 0.75, reversals: 3)
            }
        }

        init(minTravel: CGFloat, window: TimeInterval, reversals: Int) {
            self.minTravel = minTravel
            self.window = window
            self.reversals = reversals
        }
    }

    var configuration: Configuration

    private var origin: CGFloat?
    private var direction: CGFloat = 0
    private var extreme: CGFloat = 0
    /// 折り返した時刻と地点
    private var turns: [(time: TimeInterval, x: CGFloat)] = []

    init(configuration: Configuration) {
        self.configuration = configuration
    }

    /// カーソルの X 座標を 1 サンプル与え、シェイクを検出したら往復の中心の X 座標を返す
    ///
    /// 検出の瞬間のカーソルは往復の端から戻り始めたところにあり、手はまだ反対側へ動いている。
    /// そこにシェルフを出すとカーソルが外れてしまうので、左右の折り返し地点の真ん中を返す。
    mutating func feed(x: CGFloat, at time: TimeInterval) -> CGFloat? {
        guard let origin else {
            self.origin = x
            extreme = x
            return nil
        }

        if direction == 0 {
            if abs(x - origin) >= configuration.minTravel {
                direction = x > origin ? 1 : -1
                extreme = x
            }
            return nil
        }

        if (x - extreme) * direction > 0 {
            // 同じ向きに進み続けている
            extreme = x
        } else if abs(extreme - x) >= configuration.minTravel {
            // 十分な距離を戻った → extreme で折り返した
            turns.append((time, extreme))
            direction = -direction
            extreme = x
        }

        turns.removeAll { time - $0.time > configuration.window }
        guard turns.count >= configuration.reversals else { return nil }

        let turnXs = turns.map(\.x)
        turns.removeAll()
        return (turnXs.min()! + turnXs.max()!) / 2
    }
}
