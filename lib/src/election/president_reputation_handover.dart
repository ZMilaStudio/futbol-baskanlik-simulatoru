import '../fan/fan_state.dart';
import '../media/media_state.dart';

class PresidentReputationHandoverPolicy {
  const PresidentReputationHandoverPolicy({
    this.legacyWeightBps = 2500,
    this.neutralIdentityTrust = 60,
    this.neutralMediaCredibility = 65,
  });

  final int legacyWeightBps;
  final int neutralIdentityTrust;
  final int neutralMediaCredibility;

  FanState resetFan(FanState current) => FanState(
        clubId: current.clubId,
        sportingTrust: current.sportingTrust,
        financialTrust: current.financialTrust,
        transferTrust: current.transferTrust,
        identityTrust: _blend(current.identityTrust, neutralIdentityTrust),
      );

  MediaState resetMedia(MediaState current) => MediaState(
        clubId: current.clubId,
        credibility: _blend(current.credibility, neutralMediaCredibility),
      );

  int _blend(int legacy, int neutral) {
    final legacyBps = legacyWeightBps.clamp(0, 10000);
    final neutralBps = 10000 - legacyBps;
    return ((legacy * legacyBps + neutral * neutralBps) / 10000)
        .round()
        .clamp(0, 100)
        .toInt();
  }
}

class PresidentReputationHandoverEvent {
  const PresidentReputationHandoverEvent({
    required this.clubId,
    required this.electionSeasonIndex,
    required this.effectiveSeasonIndex,
    required this.outgoingPresidentId,
    required this.incomingPresidentId,
    required this.fanBefore,
    required this.fanAfter,
    required this.mediaBefore,
    required this.mediaAfter,
  });

  final String clubId;
  final int electionSeasonIndex;
  final int effectiveSeasonIndex;
  final String outgoingPresidentId;
  final String incomingPresidentId;
  final FanState fanBefore;
  final FanState fanAfter;
  final MediaState mediaBefore;
  final MediaState mediaAfter;

  int get identityDelta => fanAfter.identityTrust - fanBefore.identityTrust;
  int get mediaDelta => mediaAfter.credibility - mediaBefore.credibility;

  String get signature =>
      '$clubId:s$electionSeasonIndex>start$effectiveSeasonIndex:'
      '$outgoingPresidentId>$incomingPresidentId:'
      'fan=${fanBefore.signature}>${fanAfter.signature}:'
      'media=${mediaBefore.signature}>${mediaAfter.signature}';
}
