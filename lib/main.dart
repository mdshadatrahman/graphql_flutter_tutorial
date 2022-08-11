import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

void main() async {
  await initHiveForFlutter();
  await dotenv.load(fileName: '.env');

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

final HttpLink httpLink = HttpLink("https://api.github.com/graphql");
final AuthLink authLink = AuthLink(
    getToken: () async => "Bearer ${dotenv.env['PERSONAL_ACCESS_TOKEN']}");
final Link link = authLink.concat(httpLink);

class _MyAppState extends State<MyApp> {
  ValueNotifier<GraphQLClient> client = ValueNotifier(
    GraphQLClient(
      link: link,
      cache: GraphQLCache(),
    ),
  );

  String readRepositories = """
       query ReadRepositories(\$nRepositories: Int!) {
        viewer {
         repositories(last: \$nRepositories) {
          nodes {
            id
            name
            viewerHasStarred
        }
      }
    }
  }
    """;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: GraphQLProvider(
        client: client,
        child: SafeArea(
          child: Scaffold(
            body: SingleChildScrollView(
              child: Query(
                options: QueryOptions(
                  fetchPolicy: FetchPolicy.networkOnly,
                  document: gql(readRepositories),
                  variables: const {
                    'nRepositories': 50,
                  },
                  pollInterval: const Duration(seconds: 10),
                ),
                builder: (QueryResult result,
                    {VoidCallback? refetch, FetchMore? fetchMore}) {
                  if (result.hasException) {
                    debugPrint(result.exception.toString());
                    return Text(result.exception.toString());
                  }
                  if (result.isLoading) {
                    return const CircularProgressIndicator();
                  }

                  List? repositories =
                      result.data?['viewer']?['repositories']?['nodes'];

                  if (repositories == null) {
                    print('No repos');
                    return const Text('No repos');
                  }

                  return SizedBox(
                    height: 900,
                    width: double.infinity,
                    child: ListView.builder(
                      itemCount: repositories.length,
                      itemBuilder: (context, index) {
                        final repo = repositories[index];
                        return Text(
                          repo['name'] ?? '',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w500,
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
