import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'app/routes/app_router.dart';
import 'app/routes/route_names.dart';
import 'app/theme/app_theme.dart';
import 'features/attendance/data/datasources/attendance_remote_datasource.dart';
import 'features/attendance/data/repositories/attendance_repository_impl.dart';
import 'features/attendance/domain/repositories/attendance_repository.dart';
import 'features/attendance/presentation/bloc/attendance_bloc.dart';
import 'features/auth/data/datasources/auth_local_datasource.dart';
import 'features/auth/data/datasources/auth_remote_datasource.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/leave/data/datasources/leave_local_datasource.dart';
import 'features/leave/data/datasources/leave_remote_datasource.dart';
import 'features/leave/data/repositories/leave_repository_impl.dart';
import 'features/leave/domain/repositories/leave_repository.dart';
import 'features/leave/presentation/bloc/leave_bloc.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final authRemoteDataSource = AuthRemoteDataSourceImpl();
  final authLocalDataSource = AuthLocalDataSourceImpl();
  final authRepository = AuthRepositoryImpl(
    remoteDataSource: authRemoteDataSource,
    localDataSource: authLocalDataSource,
  );

  final attendanceRemoteDataSource = AttendanceRemoteDataSourceImpl();
  final attendanceRepository = AttendanceRepositoryImpl(
    remoteDataSource: attendanceRemoteDataSource,
  );

  final leaveRemoteDataSource = LeaveRemoteDataSourceImpl();
  final leaveLocalDataSource = LeaveLocalDataSourceImpl();
  final leaveRepository = LeaveRepositoryImpl(
    remoteDataSource: leaveRemoteDataSource,
    localDataSource: leaveLocalDataSource,
  );

  runApp(
    KarmaSetuApp(
      authRepository: authRepository,
      attendanceRepository: attendanceRepository,
      leaveRepository: leaveRepository,
    ),
  );
}

class KarmaSetuApp extends StatelessWidget {
  final AuthRepository authRepository;
  final AttendanceRepository attendanceRepository;
  final LeaveRepository leaveRepository;

  const KarmaSetuApp({
    super.key,
    required this.authRepository,
    required this.attendanceRepository,
    required this.leaveRepository,
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (_) => AuthBloc(authRepository: authRepository)
            ..add(const AuthCheckRequested()),
        ),
        BlocProvider<AttendanceBloc>(
          create: (_) => AttendanceBloc(attendanceRepository: attendanceRepository),
        ),
        BlocProvider<LeaveBloc>(
          create: (_) => LeaveBloc(leaveRepository: leaveRepository),
        ),
      ],
      child: MaterialApp(
        title: 'KarmaSetu',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        initialRoute: RouteNames.splash,
        routes: appRoutes,
      ),
    );
  }
}

