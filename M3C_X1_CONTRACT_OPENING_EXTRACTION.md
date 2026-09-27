# FBS M3-C / X1 — Contract Opening Extraction

Status: **X1 IMPLEMENTATION CANDIDATE / DRAFT PR**. P2-A1 remains BLOCKED — EXTRACTION REQUIRED; M3-C remains BLOCKED / PRECONDITION. X2/P2-A1/P2-B/C/D are not authorized.

## Source and parity
The single rule source is now `InitialContractOpeningGenerator`, exposed through the already-exported `player_contract_controller.dart`. It receives the real opening players/leagues and the `careerSeed`, `simulationVersion`, `seasonIndex` from their authoritative config. It has no controller, fixture, SeasonEngine, annual-wage, finance, transfer or checkpoint dependency.

The pre-X1 production `PlayerContractController._ensureInitialized` remains **lazy**: the first eligible `annualWagesByClub` request first checks `seasonIndex == initialSeasonIndex`, then invokes that exact generator and installs the immutable contracts/events into the existing controller. Construction, reads of `activeContracts`/`events`, and calls to the pure generator do not initialize the controller. The restore constructor remains initialized and never regenerates initial contracts. `AdvancedTransferController` still delegates to the same controller and retains loan/installment behavior.

The common `_ContractGenerationRules` preserves the old player-ID sort, per-player seed tuple `[careerSeed, simulationVersion, seasonIndex, StableHash.string32(playerId), StableHash.string32('initial-contract')]`, `SeededRng` draw order, age-dependent term 3–5 / 2–5 / 1–3, `WageModel.annualWage` then league cost factor then 9300–10799 random bps then default 10000 premium bps and 60000-unit floor, and exact `Money.scaleBasisPoints` integer rounding. Existing renewal/youth/transfer/free-agent wages and seed helper also consume the same kernel, with no gameplay rebalance.

Legacy missing tier (including an initial free agent) throws `StateError`; duplicated player IDs retain map-overwrite + one event per input occurrence. A failed pure generation does not publish a partial output or mutate the controller. This is a fail-closed failure-path hardening, not a new successful input rule.

## Opening contract
`InitialContractOpeningState`: immutable `activeContracts` (sorted by player ID, as the legacy getter) and `initialEvents` (original sorted-generation order), source seed/version/season, source player/league counts, SHA-256 source digest. `matchesSource` compares against **independently provided** original source data and exact original league/player ordering. The digest is a content fingerprint, NOT independent source authentication, a transaction revision or a disk CAS token. The source list/objects are not modified and no new persisted authority/save namespace exists.

Fixed independent pre-extraction fixture `fixed_mid`, `fixed_old`, `fixed_young` pins exact contract/event signature, term, wage and annual-wage totals. A real `WorldOpeningStateInitializer` 864-player sample tests full equality with the **production lazy controller** after its first wage invocation. Existing M7/M8, P1, M3-B v1 historical bytes and M0–M88 canonical suites remain mandatory CI regression gates.

## Explicit non-scope
No X2 president/domain opening, W1 owner, weekly decisions, effectiveClubs proof, M2 commit, M65/M75/M80 changes, restore factory, CAS, manager lifecycle, UI/Flutter or RC1/release work. No merge without a new exact-HEAD owner approval.
