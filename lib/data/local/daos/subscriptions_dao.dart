import 'package:spendwise/data/local/daos/base_dao.dart';
import 'package:spendwise/data/local/database.dart';

class SubscriptionsDao extends BaseDao {
  SubscriptionsDao(AppDatabase db)
    : super(db, 'subscriptions', syncColumn: true);
}
