from pathlib import Path


def replace_once(path: str, old: str, new: str) -> None:
    p = Path(path)
    text = p.read_text()
    count = text.count(old)
    if count != 1:
        raise SystemExit(
            f"{path}: expected exactly one match, got {count}: {old[:80]!r}"
        )
    p.write_text(text.replace(old, new, 1))


# M50: expose the already-tested sponsor-system implementation for composition.
p = Path("lib/src/sponsor/player_president_sponsor_control.dart")
text = p.read_text()
count = text.count("_PlayerPresidentSponsorSystemEngine")
if count != 3:
    raise SystemExit(f"M50 sponsor engine occurrences: expected 3, got {count}")
p.write_text(
    text.replace(
        "_PlayerPresidentSponsorSystemEngine",
        "PlayerPresidentSponsorSystemEngine",
    )
)

# M65: open a default-neutral sponsor-system injection seam.
replace_once(
    "lib/src/facility/player_president_tenure_gated_ticket_pricing_runtime_integration.dart",
    "import '../season/season_report.dart';\n",
    "import '../season/season_report.dart';\nimport '../sponsor/sponsor_system.dart';\n",
)
replace_once(
    "lib/src/facility/player_president_tenure_gated_ticket_pricing_runtime_integration.dart",
    "    this.investment = const PresidentFacilityInvestmentRuntimeEngine(),\n    this.sourceEngine = const PromiseMediaCareerEngine(),\n",
    "    this.investment = const PresidentFacilityInvestmentRuntimeEngine(),\n    this.sponsorSystem = const SponsorSystemEngine(),\n    this.sourceEngine = const PromiseMediaCareerEngine(),\n",
)
replace_once(
    "lib/src/facility/player_president_tenure_gated_ticket_pricing_runtime_integration.dart",
    "  final PresidentFacilityInvestmentRuntimeEngine investment;\n  final PromiseMediaCareerEngine sourceEngine;\n",
    "  final PresidentFacilityInvestmentRuntimeEngine investment;\n  final SponsorSystemEngine sponsorSystem;\n  final PromiseMediaCareerEngine sourceEngine;\n",
)
replace_once(
    "lib/src/facility/player_president_tenure_gated_ticket_pricing_runtime_integration.dart",
    "      runtime: FacilitySponsorCrisisRuntimeCareerEngine(\n        baseWorldEngine: pricedWorld,\n        sourceEngine: sourceEngine,\n      ),\n",
    "      runtime: FacilitySponsorCrisisRuntimeCareerEngine(\n        sponsorSystem: sponsorSystem,\n        baseWorldEngine: pricedWorld,\n        sourceEngine: sourceEngine,\n      ),\n",
)

# M68: forward the same default-neutral seam to M65.
replace_once(
    "lib/src/facility/player_president_tenure_gated_facility_promise_media_transfer_ticket_pricing_runtime_composition.dart",
    "import '../promise/promise_media_career_engine.dart';\n",
    "import '../promise/promise_media_career_engine.dart';\nimport '../sponsor/sponsor_system.dart';\n",
)
replace_once(
    "lib/src/facility/player_president_tenure_gated_facility_promise_media_transfer_ticket_pricing_runtime_composition.dart",
    "    this.baseWorldEngine = const WorldCareerEngine(),\n    this.investment = const PresidentFacilityInvestmentRuntimeEngine(),\n",
    "    this.baseWorldEngine = const WorldCareerEngine(),\n    this.investment = const PresidentFacilityInvestmentRuntimeEngine(),\n    this.sponsorSystem = const SponsorSystemEngine(),\n",
)
replace_once(
    "lib/src/facility/player_president_tenure_gated_facility_promise_media_transfer_ticket_pricing_runtime_composition.dart",
    "  final WorldCareerEngine baseWorldEngine;\n  final PresidentFacilityInvestmentRuntimeEngine investment;\n",
    "  final WorldCareerEngine baseWorldEngine;\n  final PresidentFacilityInvestmentRuntimeEngine investment;\n  final SponsorSystemEngine sponsorSystem;\n",
)
replace_once(
    "lib/src/facility/player_president_tenure_gated_facility_promise_media_transfer_ticket_pricing_runtime_composition.dart",
    "      investment: facilityInvestment,\n      sourceEngine: sourceEngine,\n",
    "      investment: facilityInvestment,\n      sponsorSystem: sponsorSystem,\n      sourceEngine: sourceEngine,\n",
)

# Add M69 canonical runner after M68.
workflow = Path(".github/workflows/m0-tests.yml")
text = workflow.read_text()
marker = (
    "      - name: Run M68 player president facility promise media transfer ticket runtime composition\n"
    "        run: dart run tool/run_m68_player_president_tenure_gated_facility_promise_media_transfer_ticket_pricing_runtime_composition.dart 20260903"
)
if text.count(marker) != 1:
    raise SystemExit("M68 workflow marker missing or duplicated")
workflow.write_text(
    text.replace(
        marker,
        marker
        + "\n\n      - name: Run M69 player president facility sponsor promise media transfer ticket runtime composition\n"
        + "        run: dart run tool/run_m69_player_president_tenure_gated_facility_sponsor_promise_media_transfer_ticket_pricing_runtime_composition.dart 20260903",
        1,
    )
)
