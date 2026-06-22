import 'package:spendwise/data/local/daos/base_dao.dart';
import 'package:spendwise/data/local/database.dart';

class SubscriptionPaymentsDao extends BaseDao {
  SubscriptionPaymentsDao(AppDatabase db) : super(db, 'subscription_payments');
}
