import '../../models/service_visit.dart';

abstract class ServiceVisitRepository {
  Stream<List<ServiceVisit>> getVisitsStream(String siteId);
  Future<List<ServiceVisit>> getVisits(String siteId);
  Future<void> saveVisit(ServiceVisit visit);
  Future<void> deleteVisit(String visitId);
}
