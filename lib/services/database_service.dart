import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/inspection.dart';
import '../models/site.dart';
import '../models/asset.dart';
import '../models/company.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- Sites ---
  Stream<List<Site>> getSites() {
    return _db.collection('sites').snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => Site.fromMap(doc.data())).toList());
  }

  Future<void> saveSite(Site site) async {
    await _db.collection('sites').doc(site.id).set(site.toMap());
  }

  Future<void> deleteSite(String siteId) async {
    await _db.collection('sites').doc(siteId).delete();
    // Delete all assets and their inspections for this site
    final assets = await _db.collection('assets').where('siteId', isEqualTo: siteId).get();
    for (var doc in assets.docs) {
      await deleteAsset(doc.id);
    }
  }

  // --- Assets ---
  Stream<List<Asset>> getAssets(String siteId) {
    return _db
        .collection('assets')
        .where('siteId', isEqualTo: siteId)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Asset.fromMap(doc.data())).toList());
  }

  Future<void> saveAsset(Asset asset) async {
    await _db.collection('assets').doc(asset.id).set(asset.toMap());
  }

  // --- Inspections ---
  Future<void> saveInspection(Inspection inspection) async {
    await _db.collection('inspections').doc(inspection.id).set(inspection.toMap());
  }

  Stream<List<Inspection>> getInspections(String assetId) {
    return _db
        .collection('inspections')
        .where('assetId', isEqualTo: assetId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Inspection.fromMap(doc.data(), doc.id))
            .toList());
  }

  Future<Inspection?> getLatestInspection(String assetId) async {
    final snapshot = await _db.collection('inspections')
        .where('assetId', isEqualTo: assetId)
        .orderBy('date', descending: true)
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) return null;
    return Inspection.fromMap(snapshot.docs.first.data(), snapshot.docs.first.id);
  }

  Future<List<Inspection>> getAllInspectionsForSite(String siteId) async {
    final snapshot = await _db.collection('inspections')
        .where('siteId', isEqualTo: siteId)
        .orderBy('date', descending: true)
        .get();
    return snapshot.docs.map((doc) => Inspection.fromMap(doc.data(), doc.id)).toList();
  }

  // --- Company ---
  Future<Company?> getCompany(String id) async {
    final doc = await _db.collection('companies').doc(id).get();
    if (!doc.exists) return null;
    return Company.fromMap(doc.data()!);
  }

  Future<void> saveCompany(Company company) async {
    await _db.collection('companies').doc(company.id).set(company.toMap());
  }

  Future<void> deleteAsset(String assetId) async {
    await _db.collection('assets').doc(assetId).delete();
    final inspections = await _db.collection('inspections').where('assetId', isEqualTo: assetId).get();
    for (var doc in inspections.docs) {
      await doc.reference.delete();
    }
  }
}
