import Foundation

actor Prompt13CycleStore {
    static let shared =
        Prompt13CycleStore()

    private var archive:
        Prompt13CycleArchive

    private let persistence:
        any Prompt13CyclePersistence

    private let engine:
        Prompt13CycleLogicEngine

    private var isLoaded:
        Bool

    init(
        archive:
            Prompt13CycleArchive =
            Prompt13CycleArchive(),
        persistence:
            any Prompt13CyclePersistence =
            Prompt13FileCyclePersistence(),
        engine:
            Prompt13CycleLogicEngine =
            Prompt13CycleLogicEngine(),
        isLoaded:
            Bool = false
    ) {
        self.archive =
            archive

        self.persistence =
            persistence

        self.engine =
            engine

        self.isLoaded =
            isLoaded
    }

    static func inMemory(
        archive:
            Prompt13CycleArchive =
            Prompt13CycleArchive()
    ) -> Prompt13CycleStore {
        Prompt13CycleStore(
            archive:
                archive,
            persistence:
                Prompt13InMemoryCyclePersistence(
                    archive: archive
                ),
            engine:
                Prompt13CycleLogicEngine(),
            isLoaded:
                true
        )
    }

    // MARK: - Lifecycle

    func loadIfNeeded()
        async throws
    {
        guard !isLoaded else {
            return
        }

        archive =
            try await
                persistence
                    .load()

        isLoaded =
            true
    }

    func snapshot()
        async throws
        -> Prompt13CycleArchive
    {
        try await
            loadIfNeeded()

        return archive
    }

    func derivedState(
        on currentDate:
            Prompt13LocalDate,
        generatedAt:
            Date = Date()
    ) async throws
        -> Prompt13DerivedState
    {
        try await
            loadIfNeeded()

        return
            try engine
                .rebuildDerivedState(
                    from:
                        archive,
                    currentDate:
                        currentDate,
                    generatedAt:
                        generatedAt
                )
    }

    // MARK: - Cycle starts

    @discardableResult
    func recordCycleStart(
        on date:
            Prompt13LocalDate,
        source:
            Prompt13CycleStartSource =
            .userConfirmed,
        accountID:
            UUID? = nil,
        now:
            Date = Date(),
        today:
            Prompt13LocalDate? = nil
    ) async throws
        -> CycleStart
    {
        try await
            loadIfNeeded()

        try validateObservationDate(
            date,
            today: today
        )

        try ensureNoActiveCycleStart(
            on: date
        )

        let record =
            CycleStart(
                date:
                    date,
                source:
                    source,
                metadata:
                    metadata(
                        accountID:
                            accountID,
                        now:
                            now
                    )
            )

        archive
            .cycleStarts
            .append(
                record
            )

        try await
            recomputeAndPersist(
                now:
                    now,
                referenceDate:
                    date
            )

        return record
    }

    /// One-time ownership migration for period starts that were originally
    /// committed by Prompt 14 before onboarding had a distinct provenance.
    func adoptCycleStartsAsOnboarding(
        dates: Set<Prompt13LocalDate>,
        now: Date = Date()
    ) async throws {
        try await loadIfNeeded()
        var changed = false
        for index in archive.cycleStarts.indices {
            guard !archive.cycleStarts[index].metadata.isDeleted,
                  dates.contains(archive.cycleStarts[index].date),
                  archive.cycleStarts[index].source == .userConfirmed else { continue }
            archive.cycleStarts[index].source = .onboardingConfirmed
            archive.cycleStarts[index].metadata.touch(at: now)
            changed = true
        }
        if changed, let referenceDate = dates.sorted().last {
            try await recomputeAndPersist(now: now, referenceDate: referenceDate)
        }
    }

    @discardableResult
    func editCycleStart(
        id:
            UUID,
        newDate:
            Prompt13LocalDate,
        now:
            Date = Date(),
        today:
            Prompt13LocalDate? = nil
    ) async throws
        -> CycleStart
    {
        try await
            loadIfNeeded()

        try validateObservationDate(
            newDate,
            today: today
        )

        guard
            let index =
                archive
                    .cycleStarts
                    .firstIndex(
                        where: {
                            $0.id == id
                        }
                    )
        else {
            throw
                Prompt13CycleError
                    .recordNotFound
        }

        guard
            !archive
                .cycleStarts[index]
                .metadata
                .isDeleted
        else {
            throw
                Prompt13CycleError
                    .recordNotFound
        }

        if
            archive
                .cycleStarts[index]
                .date !=
            newDate
        {
            try ensureNoActiveCycleStart(
                on:
                    newDate,
                excluding:
                    id
            )
        }

        archive
            .cycleStarts[index]
            .date =
            newDate

        archive
            .cycleStarts[index]
            .metadata
            .touch(
                at: now
            )

        let edited =
            archive
                .cycleStarts[index]

        try await
            recomputeAndPersist(
                now:
                    now,
                referenceDate:
                    newDate
            )

        return edited
    }

    func deleteCycleStart(
        id:
            UUID,
        now:
            Date = Date(),
        referenceDate:
            Prompt13LocalDate
    ) async throws {
        try await
            loadIfNeeded()

        guard
            let index =
                archive
                    .cycleStarts
                    .firstIndex(
                        where: {
                            $0.id == id &&
                            !$0.metadata.isDeleted
                        }
                    )
        else {
            throw
                Prompt13CycleError
                    .recordNotFound
        }

        archive
            .cycleStarts[index]
            .metadata
            .softDelete(
                at: now
            )

        try await
            recomputeAndPersist(
                now:
                    now,
                referenceDate:
                    referenceDate
            )
    }

    func restoreCycleStart(
        id:
            UUID,
        now:
            Date = Date(),
        referenceDate:
            Prompt13LocalDate
    ) async throws {
        try await
            loadIfNeeded()

        guard
            let index =
                archive
                    .cycleStarts
                    .firstIndex(
                        where: {
                            $0.id == id &&
                            $0.metadata.isDeleted
                        }
                    )
        else {
            throw
                Prompt13CycleError
                    .recordNotFound
        }

        let date =
            archive
                .cycleStarts[index]
                .date

        try ensureNoActiveCycleStart(
            on:
                date,
            excluding:
                id
        )

        archive
            .cycleStarts[index]
            .metadata
            .restore(
                at: now
            )

        try await
            recomputeAndPersist(
                now:
                    now,
                referenceDate:
                    referenceDate
            )
    }

    // MARK: - Daily logs

    @discardableResult
    func dailyLog(
        for date:
            Prompt13LocalDate,
        createIfMissing:
            Bool,
        accountID:
            UUID? = nil,
        now:
            Date = Date(),
        today:
            Prompt13LocalDate? = nil
    ) async throws
        -> DailyLog?
    {
        try await
            loadIfNeeded()

        if let existing =
            archive
                .dailyLogs
                .first(
                    where: {
                        $0.date == date &&
                        !$0.metadata.isDeleted
                    }
                )
        {
            return existing
        }

        guard createIfMissing else {
            return nil
        }

        try validateObservationDate(
            date,
            today: today
        )

        let state =
            try engine
                .rebuildDerivedState(
                    from:
                        archive,
                    currentDate:
                        date,
                    generatedAt:
                        now
                )

        let log =
            DailyLog(
                date:
                    date,
                cycleID:
                    state.currentCycleID,
                metadata:
                    metadata(
                        accountID:
                            accountID,
                        now:
                            now
                    )
            )

        archive
            .dailyLogs
            .append(
                log
            )

        archive
            .lastUpdatedAt =
            now

        try await
            persistence
                .save(
                    archive
                )

        return log
    }

    // MARK: - Observations

    @discardableResult
    func recordBleeding(
        on date:
            Prompt13LocalDate,
        flowLevel:
            Prompt13BleedingFlowLevel,
        accountID:
            UUID? = nil,
        now:
            Date = Date(),
        today:
            Prompt13LocalDate? = nil
    ) async throws
        -> BleedingObservation
    {
        try await
            loadIfNeeded()

        try validateObservationDate(
            date,
            today: today
        )

        let link =
            try await linkage(
                for:
                    date,
                accountID:
                    accountID,
                now:
                    now,
                today:
                    today
            )

        let observation =
            BleedingObservation(
                dailyLogID:
                    link.logID,
                cycleID:
                    link.cycleID,
                date:
                    date,
                flowLevel:
                    flowLevel,
                metadata:
                    metadata(
                        accountID:
                            accountID,
                        now:
                            now
                    )
            )

        archive
            .bleedingObservations
            .append(
                observation
            )

        try await
            recomputeAndPersist(
                now:
                    now,
                referenceDate:
                    date
            )

        return observation
    }

    @discardableResult
    func recordSymptom(
        on date:
            Prompt13LocalDate,
        type:
            Prompt13SymptomType,
        severity:
            Prompt13SymptomSeverity,
        userLabel:
            String? = nil,
        accountID:
            UUID? = nil,
        now:
            Date = Date(),
        today:
            Prompt13LocalDate? = nil
    ) async throws
        -> SymptomObservation
    {
        try await
            loadIfNeeded()

        try validateObservationDate(
            date,
            today: today
        )

        let link =
            try await linkage(
                for:
                    date,
                accountID:
                    accountID,
                now:
                    now,
                today:
                    today
            )

        let observation =
            SymptomObservation(
                dailyLogID:
                    link.logID,
                cycleID:
                    link.cycleID,
                date:
                    date,
                symptomType:
                    type,
                severity:
                    severity,
                userLabel:
                    userLabel,
                metadata:
                    metadata(
                        accountID:
                            accountID,
                        now:
                            now
                    )
            )

        archive
            .symptomObservations
            .append(
                observation
            )

        try await
            recomputeAndPersist(
                now:
                    now,
                referenceDate:
                    date
            )

        return observation
    }

    @discardableResult
    func recordTemperature(
        on date:
            Prompt13LocalDate,
        value:
            Double,
        unit:
            Prompt13TemperatureUnit,
        timeRecorded:
            Date? = nil,
        measurementContext:
            Prompt13TemperatureMeasurementContext =
            .basal,
        accountID:
            UUID? = nil,
        now:
            Date = Date(),
        today:
            Prompt13LocalDate? = nil
    ) async throws
        -> TemperatureObservation
    {
        try await
            loadIfNeeded()

        try validateObservationDate(
            date,
            today: today
        )

        let link =
            try await linkage(
                for:
                    date,
                accountID:
                    accountID,
                now:
                    now,
                today:
                    today
            )

        let observation =
            try TemperatureObservation(
                dailyLogID:
                    link.logID,
                cycleID:
                    link.cycleID,
                date:
                    date,
                value:
                    value,
                unit:
                    unit,
                timeRecorded:
                    timeRecorded,
                measurementContext:
                    measurementContext,
                metadata:
                    metadata(
                        accountID:
                            accountID,
                        now:
                            now
                    )
            )

        archive
            .temperatureObservations
            .append(
                observation
            )

        try await
            recomputeAndPersist(
                now:
                    now,
                referenceDate:
                    date
            )

        return observation
    }

    @discardableResult
    func recordCervicalFluid(
        on date:
            Prompt13LocalDate,
        category:
            Prompt13CervicalFluidCategory,
        accountID:
            UUID? = nil,
        now:
            Date = Date(),
        today:
            Prompt13LocalDate? = nil
    ) async throws
        -> CervicalFluidObservation
    {
        try await
            loadIfNeeded()

        try validateObservationDate(
            date,
            today: today
        )

        let link =
            try await linkage(
                for:
                    date,
                accountID:
                    accountID,
                now:
                    now,
                today:
                    today
            )

        let observation =
            CervicalFluidObservation(
                dailyLogID:
                    link.logID,
                cycleID:
                    link.cycleID,
                date:
                    date,
                category:
                    category,
                metadata:
                    metadata(
                        accountID:
                            accountID,
                        now:
                            now
                    )
            )

        archive
            .cervicalFluidObservations
            .append(
                observation
            )

        try await
            recomputeAndPersist(
                now:
                    now,
                referenceDate:
                    date
            )

        return observation
    }

    @discardableResult
    func recordMedication(
        on date:
            Prompt13LocalDate,
        medicationName:
            String,
        dose:
            Double? = nil,
        unit:
            String? = nil,
        time:
            Date? = nil,
        userNote:
            String? = nil,
        accountID:
            UUID? = nil,
        now:
            Date = Date(),
        today:
            Prompt13LocalDate? = nil
    ) async throws
        -> MedicationObservation
    {
        try await
            loadIfNeeded()

        try validateObservationDate(
            date,
            today: today
        )

        let link =
            try await linkage(
                for:
                    date,
                accountID:
                    accountID,
                now:
                    now,
                today:
                    today
            )

        let observation =
            try MedicationObservation(
                dailyLogID:
                    link.logID,
                cycleID:
                    link.cycleID,
                date:
                    date,
                medicationName:
                    medicationName,
                dose:
                    dose,
                unit:
                    unit,
                time:
                    time,
                userNote:
                    userNote,
                metadata:
                    metadata(
                        accountID:
                            accountID,
                        now:
                            now
                    )
            )

        archive
            .medicationObservations
            .append(
                observation
            )

        try await
            recomputeAndPersist(
                now:
                    now,
                referenceDate:
                    date
            )

        return observation
    }

    @discardableResult
    func recordNote(
        on date:
            Prompt13LocalDate,
        text:
            String,
        accountID:
            UUID? = nil,
        now:
            Date = Date(),
        today:
            Prompt13LocalDate? = nil
    ) async throws
        -> Note
    {
        try await
            loadIfNeeded()

        try validateObservationDate(
            date,
            today: today
        )

        let link =
            try await linkage(
                for:
                    date,
                accountID:
                    accountID,
                now:
                    now,
                today:
                    today
            )

        let note =
            try Note(
                dailyLogID:
                    link.logID,
                cycleID:
                    link.cycleID,
                date:
                    date,
                text:
                    text,
                metadata:
                    metadata(
                        accountID:
                            accountID,
                        now:
                            now
                    )
            )

        archive
            .notes
            .append(
                note
            )

        try await
            recomputeAndPersist(
                now:
                    now,
                referenceDate:
                    date
            )

        return note
    }

    @discardableResult
    func recordPregnancyTest(
        on date:
            Prompt13LocalDate,
        result:
            Prompt13PregnancyTestResult,
        timeRecorded:
            Date? = nil,
        userNote:
            String? = nil,
        accountID:
            UUID? = nil,
        now:
            Date = Date(),
        today:
            Prompt13LocalDate? = nil
    ) async throws
        -> PregnancyTestObservation
    {
        try await
            loadIfNeeded()

        try validateObservationDate(
            date,
            today: today
        )

        let link =
            try await linkage(
                for:
                    date,
                accountID:
                    accountID,
                now:
                    now,
                today:
                    today
            )

        let observation =
            PregnancyTestObservation(
                dailyLogID:
                    link.logID,
                cycleID:
                    link.cycleID,
                date:
                    date,
                result:
                    result,
                timeRecorded:
                    timeRecorded,
                userNote:
                    userNote,
                metadata:
                    metadata(
                        accountID:
                            accountID,
                        now:
                            now
                    )
            )

        archive
            .pregnancyTestObservations
            .append(
                observation
            )

        try await
            recomputeAndPersist(
                now:
                    now,
                referenceDate:
                    date
            )

        return observation
    }

    func deleteObservation(
        id:
            UUID,
        now:
            Date = Date(),
        referenceDate:
            Prompt13LocalDate
    ) async throws {
        try await
            loadIfNeeded()

        if
            softDelete(
                id:
                    id,
                in:
                    &archive
                        .bleedingObservations,
                now:
                    now
            ) ||
            softDelete(
                id:
                    id,
                in:
                    &archive
                        .symptomObservations,
                now:
                    now
            ) ||
            softDelete(
                id:
                    id,
                in:
                    &archive
                        .temperatureObservations,
                now:
                    now
            ) ||
            softDelete(
                id:
                    id,
                in:
                    &archive
                        .cervicalFluidObservations,
                now:
                    now
            ) ||
            softDelete(
                id:
                    id,
                in:
                    &archive
                        .medicationObservations,
                now:
                    now
            ) ||
            softDelete(
                id:
                    id,
                in:
                    &archive
                        .notes,
                now:
                    now
            ) ||
            softDelete(
                id:
                    id,
                in:
                    &archive
                        .pregnancyTestObservations,
                now:
                    now
            )
        {
            try await
                recomputeAndPersist(
                    now:
                        now,
                    referenceDate:
                        referenceDate
                )

            return
        }

        throw
            Prompt13CycleError
                .recordNotFound
    }

    // MARK: - Privacy / local control

    func exportArchiveJSON()
        async throws
        -> Data
    {
        try await
            loadIfNeeded()

        let encoder =
            JSONEncoder()

        encoder.dateEncodingStrategy =
            .iso8601

        encoder.outputFormatting = [
            .prettyPrinted,
            .sortedKeys
        ]

        return
            try encoder.encode(
                archive
            )
    }

    func eraseAllLocalCycleData(
        preserveLocalIdentity:
            Bool = true
    ) async throws {
        try await
            loadIfNeeded()

        let profileID =
            archive.localProfileID

        let deviceID =
            archive.deviceID

        archive =
            Prompt13CycleArchive(
                localProfileID:
                    preserveLocalIdentity
                    ? profileID
                    : UUID(),
                deviceID:
                    preserveLocalIdentity
                    ? deviceID
                    : UUID()
            )

        try await
            persistence
                .erase()

        try await
            persistence
                .save(
                    archive
                )
    }

    // MARK: - Sync conflict detection

    func detectConflicts(
        with remote:
            Prompt13CycleArchive
    ) async throws
        -> [Prompt13SyncConflict]
    {
        try await
            loadIfNeeded()

        return
            Prompt13SyncConflictDetector()
                .conflicts(
                    local:
                        archive,
                    remote:
                        remote
                )
    }

    // MARK: - Internal

    private func validateObservationDate(
        _ date:
            Prompt13LocalDate,
        today:
            Prompt13LocalDate?
    ) throws {
        let comparisonDate:
            Prompt13LocalDate

        if let today {
            comparisonDate =
                today
        } else {
            comparisonDate =
                try Prompt13LocalDate(
                    Date(),
                    calendar:
                        Calendar
                            .autoupdatingCurrent
                )
        }

        if date > comparisonDate {
            throw
                Prompt13CycleError
                    .futureObservationNotAllowed
        }
    }

    private func ensureNoActiveCycleStart(
        on date:
            Prompt13LocalDate,
        excluding excludedID:
            UUID? = nil
    ) throws {
        let duplicate =
            archive
                .cycleStarts
                .contains {
                    !$0.metadata.isDeleted &&
                    $0.id != excludedID &&
                    $0.date == date
                }

        if duplicate {
            throw
                Prompt13CycleError
                    .duplicateCycleStartDate(
                        date
                    )
        }
    }

    private func metadata(
        accountID:
            UUID?,
        now:
            Date
    ) -> Prompt13RecordMetadata {
        Prompt13RecordMetadata(
            createdAt:
                now,
            updatedAt:
                now,
            localProfileID:
                archive.localProfileID,
            accountID:
                accountID,
            deviceID:
                archive.deviceID
        )
    }

    private func linkage(
        for date:
            Prompt13LocalDate,
        accountID:
            UUID?,
        now:
            Date,
        today:
            Prompt13LocalDate?
    ) async throws
        -> (
            logID: UUID,
            cycleID: UUID?
        )
    {
        if let existing =
            archive
                .dailyLogs
                .first(
                    where: {
                        $0.date == date &&
                        !$0.metadata.isDeleted
                    }
                )
        {
            return (
                existing.id,
                existing.cycleID
            )
        }

        let state =
            try engine
                .rebuildDerivedState(
                    from:
                        archive,
                    currentDate:
                        date,
                    generatedAt:
                        now
                )

        let log =
            DailyLog(
                date:
                    date,
                cycleID:
                    state.currentCycleID,
                metadata:
                    metadata(
                        accountID:
                            accountID,
                        now:
                            now
                    )
            )

        archive
            .dailyLogs
            .append(
                log
            )

        return (
            log.id,
            log.cycleID
        )
    }

    private func recomputeAndPersist(
        now:
            Date,
        referenceDate:
            Prompt13LocalDate
    ) async throws {
        let state =
            try engine
                .rebuildDerivedState(
                    from:
                        archive,
                    currentDate:
                        referenceDate,
                    generatedAt:
                        now
                )

        archive
            .predictionSnapshots =
            state.activePredictions

        archive
            .patternInsights =
            state.patternInsights

        refreshDailyLogCycleLinks(
            using:
                state.cycles,
            now:
                now
        )

        archive
            .lastUpdatedAt =
            now

        try await
            persistence
                .save(
                    archive
                )
    }

    private func refreshDailyLogCycleLinks(
        using cycles:
            [Cycle],
        now:
            Date
    ) {
        for index in
            archive.dailyLogs.indices
        where
            !archive
                .dailyLogs[index]
                .metadata
                .isDeleted
        {
            let date =
                archive
                    .dailyLogs[index]
                    .date

            let cycleID =
                cycles.last {
                    cycle in

                    guard
                        cycle.startDate <=
                        date
                    else {
                        return false
                    }

                    if let end =
                        cycle.endDate
                    {
                        return
                            date <= end
                    }

                    return
                        cycle.status ==
                        .open
                }?.id

            if
                archive
                    .dailyLogs[index]
                    .cycleID !=
                cycleID
            {
                archive
                    .dailyLogs[index]
                    .cycleID =
                    cycleID

                archive
                    .dailyLogs[index]
                    .metadata
                    .touch(
                        at: now
                    )
            }
        }

        let cycleByLogID =
            Dictionary(
                uniqueKeysWithValues:
                    archive
                        .dailyLogs
                        .map {
                            (
                                $0.id,
                                $0.cycleID
                            )
                        }
            )

        for index in
            archive
                .bleedingObservations
                .indices
        {
            if let logID =
                archive
                    .bleedingObservations[index]
                    .dailyLogID
            {
                archive
                    .bleedingObservations[index]
                    .cycleID =
                    cycleByLogID[logID] ??
                    nil
            }
        }

        for index in
            archive
                .symptomObservations
                .indices
        {
            if let logID =
                archive
                    .symptomObservations[index]
                    .dailyLogID
            {
                archive
                    .symptomObservations[index]
                    .cycleID =
                    cycleByLogID[logID] ??
                    nil
            }
        }

        for index in
            archive
                .temperatureObservations
                .indices
        {
            if let logID =
                archive
                    .temperatureObservations[index]
                    .dailyLogID
            {
                archive
                    .temperatureObservations[index]
                    .cycleID =
                    cycleByLogID[logID] ??
                    nil
            }
        }

        for index in
            archive
                .cervicalFluidObservations
                .indices
        {
            if let logID =
                archive
                    .cervicalFluidObservations[index]
                    .dailyLogID
            {
                archive
                    .cervicalFluidObservations[index]
                    .cycleID =
                    cycleByLogID[logID] ??
                    nil
            }
        }

        for index in
            archive
                .medicationObservations
                .indices
        {
            if let logID =
                archive
                    .medicationObservations[index]
                    .dailyLogID
            {
                archive
                    .medicationObservations[index]
                    .cycleID =
                    cycleByLogID[logID] ??
                    nil
            }
        }

        for index in
            archive.notes.indices
        {
            if let logID =
                archive
                    .notes[index]
                    .dailyLogID
            {
                archive
                    .notes[index]
                    .cycleID =
                    cycleByLogID[logID] ??
                    nil
            }
        }

        for index in
            archive
                .pregnancyTestObservations
                .indices
        {
            if let logID =
                archive
                    .pregnancyTestObservations[index]
                    .dailyLogID
            {
                archive
                    .pregnancyTestObservations[index]
                    .cycleID =
                    cycleByLogID[logID] ??
                    nil
            }
        }
    }

    private func softDelete<
        T: Prompt13SoftDeletable
    >(
        id:
            UUID,
        in records:
            inout [T],
        now:
            Date
    ) -> Bool {
        guard
            let index =
                records
                    .firstIndex(
                        where: {
                            $0.id == id &&
                            !$0.metadata.isDeleted
                        }
                    )
        else {
            return false
        }

        records[index]
            .metadata
            .softDelete(
                at: now
            )

        return true
    }
}

nonisolated protocol Prompt13SoftDeletable:
    Identifiable
where ID == UUID
{
    var metadata:
        Prompt13RecordMetadata
    {
        get
        set
    }
}

nonisolated extension BleedingObservation:
    Prompt13SoftDeletable
{}

nonisolated extension SymptomObservation:
    Prompt13SoftDeletable
{}

nonisolated extension TemperatureObservation:
    Prompt13SoftDeletable
{}

nonisolated extension CervicalFluidObservation:
    Prompt13SoftDeletable
{}

nonisolated extension MedicationObservation:
    Prompt13SoftDeletable
{}

nonisolated extension Note:
    Prompt13SoftDeletable
{}

nonisolated extension PregnancyTestObservation:
    Prompt13SoftDeletable
{}
