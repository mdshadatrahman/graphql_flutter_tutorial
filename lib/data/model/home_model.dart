
import 'package:graphql_flutter_tutorial/data/model/user_model.dart';

class HomeModel {
  final UserModel currentUser = UserModel.dummy();

  final List<UserModel> musicMates =  List.generate(9, (index) => UserModel.dummy());

}
