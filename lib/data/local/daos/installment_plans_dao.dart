import 'package:spendwise/data/local/daos/base_dao.dart';
import 'package:spendwise/data/local/database.dart';

class InstallmentPlansDao extends BaseDao {
  InstallmentPlansDao(AppDatabase db)
    : super(db, 'installment_plans', syncColumn: true);
}
