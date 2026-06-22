import 'package:spendwise/data/local/daos/base_dao.dart';
import 'package:spendwise/data/local/database.dart';

class InstallmentPaymentsDao extends BaseDao {
  InstallmentPaymentsDao(AppDatabase db) : super(db, 'installment_payments');
}
