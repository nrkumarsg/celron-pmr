import '../models/company.dart';

/// Single source of truth for CEL-RON company data.
/// Used across PDF generation, dashboards, and inspection forms.
class CelRonCompany {
  static const Company instance = Company(
    id: 'celron',
    name: 'CEL-RON ENTERPRISES PTE LTD',
    regOffice: '10 Jln Besar,#03-05, Sim Lim Tower, Singapore 208787',
    phone: '+65 66181721',
    fax: '+65 63334636',
    mobile: '+65 97685891',
    email: 'sales@celron.net',
    web: 'www.celron.net',
    brn: '201436227C',
    gstReg: '201436227C',
  );
}
