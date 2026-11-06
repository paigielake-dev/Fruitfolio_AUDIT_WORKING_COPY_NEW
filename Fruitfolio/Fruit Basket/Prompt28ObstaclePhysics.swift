import Foundation

/// Forces affect current trajectories; the object's captured base fall speed and
/// drift never change when a later game-level configuration is selected.
nonisolated enum Prompt28ObstaclePhysics {
    private static func wind(_ active: Bool, direction: Double, weather: Prompt28Weather) -> Double {
        active ? min(max(direction, -1), 1) * (weather == .softRain ? 0.030 : 0.021) : 0
    }
    @discardableResult
    static func advanceFruit(_ fruit: inout Prompt28FallingFruit, delta: TimeInterval,
                             geometry: Prompt28ObstacleGeometry, obstacles: Set<Prompt28ObstacleKind>,
                             lanes: ClosedRange<Double>, windDirection: Double, weather: Prompt28Weather) -> Bool {
        guard delta.isFinite, delta > 0, geometry.isValid else { return false }
        let delta = min(delta, 0.08)
        let oldX = fruit.x; let oldY = fruit.y
        let force = wind(obstacles.contains(.wind), direction: windDirection, weather: weather)
        var velocity = (fruit.horizontalVelocityAfterBranch ?? fruit.horizontalDrift) + force
        let proposedX = min(max(oldX + velocity * delta, lanes.lowerBound), lanes.upperBound)
        let proposedY = oldY + fruit.fallSpeed * delta
        let size = Prompt28CatchGeometry(playfield: geometry.playfield).fruitSize
        let sweep = geometry.objectRect(x: oldX, y: oldY, size: size)
            .union(geometry.objectRect(x: proposedX, y: proposedY, size: size))
        let wasInVines = fruit.isInVines
        fruit.isInVines = fruit.classification == .good && obstacles.contains(.vines) && geometry.touches("vines", object: sweep)
        fruit.vineContactTime = fruit.isInVines ? fruit.vineContactTime + delta : 0
        let vineFactor = fruit.isInVines ? 0.56 : 1.0
        if obstacles.contains(.branch), !fruit.branchDeflected, geometry.touches("branch", object: sweep) {
            fruit.branchDeflected = true
            fruit.branchBounceRemaining = 0.20
            let reflected = -min(max(abs(velocity) + 0.08, 0.08), 0.16)
            fruit.horizontalVelocityAfterBranch = reflected
            velocity = reflected + force
        }
        let bounceFactor: Double
        if fruit.branchBounceRemaining > 0 {
            fruit.branchBounceRemaining = max(0, fruit.branchBounceRemaining - delta)
            bounceFactor = fruit.branchBounceRemaining > 0.10 ? -0.30 : 0.50
        } else { bounceFactor = 1 }
        fruit.x = min(max(oldX + velocity * delta, lanes.lowerBound), lanes.upperBound)
        fruit.y = oldY + fruit.fallSpeed * vineFactor * bounceFactor * delta
        return fruit.isInVines && !wasInVines
    }
    @discardableResult
    static func advanceStar(_ star: inout Prompt28FallingStar, delta: TimeInterval,
                            geometry: Prompt28ObstacleGeometry, obstacles: Set<Prompt28ObstacleKind>,
                            lanes: ClosedRange<Double>, windDirection: Double, weather: Prompt28Weather) -> Bool {
        guard delta.isFinite, delta > 0, geometry.isValid else { return false }
        let delta = min(delta, 0.08)
        let size = Prompt28CatchGeometry(playfield: geometry.playfield).starSize
        let newX = min(max(star.x + (star.horizontalDrift + wind(obstacles.contains(.wind), direction: windDirection, weather: weather)) * delta,
                           lanes.lowerBound), lanes.upperBound)
        let sweep = geometry.objectRect(x: star.x, y: star.y, size: size)
            .union(geometry.objectRect(x: newX, y: star.y + star.fallSpeed * delta, size: size))
        let wasInVines = star.isInVines
        star.isInVines = obstacles.contains(.vines) && geometry.touches("vines", object: sweep)
        star.vineContactTime = star.isInVines ? star.vineContactTime + delta : 0
        star.y += star.fallSpeed * (star.isInVines ? 0.56 : 1) * delta
        star.x = newX
        return star.isInVines && !wasInVines
    }

    /// Persistent target following means a quick drag across water eventually
    /// reaches the finger's target even after touch events stop. Dry travel has
    /// the existing immediate response; only painted-puddle overlap resists it.
    static func moveBasket(position: Double, target: Double, delta: TimeInterval,
                           geometry: Prompt28ObstacleGeometry, puddleActive: Bool) -> (position: Double, resistance: Double) {
        guard position.isFinite, (0...1).contains(position), target.isFinite, delta.isFinite, delta > 0, geometry.isValid else { return (position, 0) }
        let target = min(max(target, 0.10), 0.90)
        guard puddleActive else { return (target, 0) }
        let distance = target - position
        if abs(distance) < 0.0001 { return (target, 0) }
        // Sweep the actual basket footprint through the drag path so a long
        // touch event cannot jump over the puddle without encountering water.
        let steps = max(1, Int(ceil(abs(distance) / 0.02)))
        var firstContact: Double?
        for step in 0...steps {
            let x = position + distance * Double(step) / Double(steps)
            if geometry.basketTouchesPuddle(at: x) { firstContact = x; break }
        }
        guard let firstContact else { return (target, 0) }
        let start = geometry.basketTouchesPuddle(at: position) ? position : firstContact
        let response = 1 - exp(-5 * min(delta, 0.08))
        let next = start + (target - start) * response
        return (min(max(next, 0.10), 0.90), 1)
    }
}
