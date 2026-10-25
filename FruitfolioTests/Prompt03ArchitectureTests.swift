import XCTest
@testable import Fruitfolio

final class Prompt03ArchitectureTests: XCTestCase {

    func testAllRequiredTopLevelRoutesExist() {
        XCTAssertEqual(
            Set(FruitfolioRoute.allCases),
            Set([
                .intro,
                .hub,
                .ask,
                .library,
                .guideBuilder,
                .cycle,
                .fruitBasket,
                .faq,
                .contact,
                .settings,
                .account,
                .privacy,
                .purchase
            ])
        )
    }

    func testPaidAppStoreDistributionModelIsCanonical() {
        XCTAssertEqual(
            FruitfolioPurchasePolicy.distributionModel,
            .paidAppStoreDownload
        )

        XCTAssertTrue(
            FruitfolioPurchasePolicy.normalInstalledUserHasAccess
        )

        XCTAssertFalse(
            FruitfolioPurchasePolicy.offersInAppUnlockPurchase
        )

        XCTAssertFalse(
            FruitfolioPurchasePolicy.offersSubscription
        )

        XCTAssertFalse(
            FruitfolioPurchasePolicy.offersFreePremiumSplit
        )
    }

    func testNoNormalRouteRequiresSecondPurchaseGate() {
        for route in FruitfolioRoute.allCases
        where route != .purchase {
            XCTAssertFalse(
                FruitfolioPurchasePolicy.requiresPurchaseGate(
                    for: route
                )
            )
        }
    }

    func testPurchaseRouteIsNotNormalHubDestination() {
        XCTAssertFalse(
            FruitfolioRoute.normalHubDestinations.contains(
                .purchase
            )
        )

        XCTAssertEqual(
            FruitfolioRoute.hubPrimaryDestinations,
            [
                .ask,
                .library,
                .guideBuilder,
                .cycle,
                .fruitBasket,
                .faq
            ]
        )

        XCTAssertEqual(
            FruitfolioRoute.hubUtilityDestinations,
            [
                .contact,
                .settings,
                .account
            ]
        )
    }

    func testInstalledAppStateIsNotSecondarilyPaywalled() async {
        let hasAccess = await MainActor.run {
            AppState().hasAppAccess
        }

        XCTAssertTrue(hasAccess)
    }

    func testNavigationPreventsDuplicateAndRapidPushes() async {
        let path = await MainActor.run {
            () -> [FruitfolioRoute] in

            let popup = PopupCoordinator()

            let navigation = NavigationCoordinator(
                root: .hub,
                popupCoordinator: popup,
                minimumPushInterval: 0.22
            )

            XCTAssertTrue(
                navigation.navigate(
                    to: .cycle,
                    now: 10.0
                )
            )

            XCTAssertFalse(
                navigation.navigate(
                    to: .cycle,
                    now: 10.01
                )
            )

            XCTAssertFalse(
                navigation.navigate(
                    to: .faq,
                    now: 10.02
                )
            )

            return navigation.path
        }

        XCTAssertEqual(
            path,
            [.cycle]
        )
    }

    func testNavigationAllowsNextPushAfterTransitionWindow() async {
        let path = await MainActor.run {
            () -> [FruitfolioRoute] in

            let popup = PopupCoordinator()

            let navigation = NavigationCoordinator(
                root: .hub,
                popupCoordinator: popup,
                minimumPushInterval: 0.22
            )

            XCTAssertTrue(
                navigation.navigate(
                    to: .library,
                    now: 10.0
                )
            )

            XCTAssertTrue(
                navigation.navigate(
                    to: .account,
                    now: 10.3
                )
            )

            return navigation.path
        }

        XCTAssertEqual(
            path,
            [.library, .account]
        )
    }

    func testBackUsesLogicalStack() async {
        let route = await MainActor.run {
            () -> FruitfolioRoute in

            let popup = PopupCoordinator()

            let navigation = NavigationCoordinator(
                root: .hub,
                popupCoordinator: popup,
                minimumPushInterval: 0
            )

            navigation.navigate(
                to: .library,
                now: 1
            )

            navigation.navigate(
                to: .account,
                now: 2
            )

            navigation.back()

            XCTAssertEqual(
                navigation.currentRoute,
                .library
            )

            navigation.back()

            return navigation.currentRoute
        }

        XCTAssertEqual(
            route,
            .hub
        )
    }

    func testReturnToHubClearsPath() async {
        let result = await MainActor.run {
            () -> (FruitfolioRoute, [FruitfolioRoute]) in

            let popup = PopupCoordinator()

            let navigation = NavigationCoordinator(
                root: .hub,
                popupCoordinator: popup,
                minimumPushInterval: 0
            )

            navigation.navigate(
                to: .settings,
                now: 1
            )

            navigation.returnToHub()

            return (
                navigation.root,
                navigation.path
            )
        }

        XCTAssertEqual(
            result.0,
            .hub
        )

        XCTAssertTrue(
            result.1.isEmpty
        )
    }

    func testSettingsPersistAcrossInstances() async {
        let values = await MainActor.run {
            () -> [Bool] in

            let suite =
                "FruitfolioPrompt03Tests.\(UUID().uuidString)"

            guard let defaults =
                    UserDefaults(suiteName: suite) else {
                return []
            }

            defaults.removePersistentDomain(
                forName: suite
            )

            defer {
                defaults.removePersistentDomain(
                    forName: suite
                )
            }

            let first = SettingsStore(
                defaults: defaults
            )

            first.musicEnabled = false
            first.rainEnabled = false
            first.soundEffectsEnabled = false
            first.typingASMREnabled = false
            first.reduceAnimationOverride = true
            first.onboardingCompleted = true

            let second = SettingsStore(
                defaults: defaults
            )

            return [
                second.musicEnabled,
                second.rainEnabled,
                second.soundEffectsEnabled,
                second.typingASMREnabled,
                second.reduceAnimationOverride,
                second.onboardingCompleted
            ]
        }

        XCTAssertEqual(
            values,
            [
                false,
                false,
                false,
                false,
                true,
                true
            ]
        )
    }

    func testVolumePersistenceClampsToValidRange() async {
        let values = await MainActor.run {
            () -> [Double] in

            let suite =
                "FruitfolioPrompt03VolumeTests.\(UUID().uuidString)"

            guard let defaults =
                    UserDefaults(suiteName: suite) else {
                return []
            }

            defaults.removePersistentDomain(
                forName: suite
            )

            defer {
                defaults.removePersistentDomain(
                    forName: suite
                )
            }

            let first = SettingsStore(
                defaults: defaults
            )

            first.musicVolume = 3
            first.rainVolume = -2

            let second = SettingsStore(
                defaults: defaults
            )

            return [
                second.musicVolume,
                second.rainVolume
            ]
        }

        XCTAssertEqual(
            values.count,
            2
        )

        if values.count == 2 {
            XCTAssertEqual(
                values[0],
                1,
                accuracy: 0.0001
            )

            XCTAssertEqual(
                values[1],
                0,
                accuracy: 0.0001
            )
        }
    }

    func testMotionPreferencesRespectSystemAndAppReduction() async {
        let result = await MainActor.run {
            () -> [Bool] in

            let motion = MotionPreferences()

            motion.update(
                systemReduceMotion: false,
                appOverride: false
            )

            let normal =
                motion.allowStorybookMotion

            motion.update(
                systemReduceMotion: true,
                appOverride: false
            )

            let systemReduced =
                motion.allowStorybookMotion

            motion.update(
                systemReduceMotion: false,
                appOverride: true
            )

            let appReduced =
                motion.allowCelebrationMotion

            return [
                normal,
                systemReduced,
                appReduced
            ]
        }

        XCTAssertEqual(
            result,
            [
                true,
                false,
                false
            ]
        )
    }

    func testPrompt01RegistryStillHasAllProductionAssets() {
        XCTAssertEqual(
            AssetConstants.productionAssetCount,
            265
        )

        XCTAssertEqual(
            AssetRegistry.all.count,
            AssetRegistry.expectedProductionPNGCount
        )
    }

    func testAudioCategoriesRemainIndependent() {
        XCTAssertEqual(
            Set(FruitfolioAudioCategory.allCases),
            Set([
                .music,
                .rainAmbience,
                .soundEffects,
                .typingASMR
            ])
        )
    }
}
