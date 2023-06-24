import 'package:todo_api/config/env.dart';
import 'package:todo_api/core/orm/prisma_client.dart';

final prisma =
    PrismaClient(datasources: const Datasources(db: Env.databaseUrl));
