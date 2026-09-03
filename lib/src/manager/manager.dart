import 'manager_profile.dart';

class Manager {
  const Manager({
    required this.id,
    required this.name,
    required this.profile,
    required this.startAge,
    required this.retirementAge,
    required this.reputation,
    required this.coaching,
    required this.youthDevelopment,
    required this.manManagement,
    required this.boardCooperation,
    required this.budgetDemand,
  });

  final String id;
  final String name;
  final ManagerProfile profile;
  final int startAge;
  final int retirementAge;
  final int reputation;
  final int coaching;
  final int youthDevelopment;
  final int manManagement;
  final int boardCooperation;
  final int budgetDemand;

  String get signature =>
      '$id|${profile.name}|$startAge|$retirementAge|$reputation|$coaching|'
      '$youthDevelopment|$manManagement|$boardCooperation|$budgetDemand';
}
