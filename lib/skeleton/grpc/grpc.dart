import 'dart:async';

import 'package:flutter_manager/entities.dart';
import 'package:flutter_manager/framework/skeleton.dart';
import 'package:flutter_manager/logic/app.dart';
import 'package:recase/recase.dart';


class GrpcModule extends ModuleBone {

  GrpcModule() : super(
    name: 'grpc',
    children: [
      KeyBone<GrpcServices>('services'),
      KeyBone<GrpcPort>('port'),
      KeyBone<GrpcTimeout>('timeout'),

      GrpcPort(),
      GrpcTimeout(),

      OutputBone(
        output: Output(
          language: Language.Dart,
          target: Target.Client,
          g: true
        ),
        children: [
          Folder('proto', [
            GrpcProtoFiles(
              protoFolder: '${server.root}/build/generated/source/proto/main/dart'
            ),
          ]),
          GrpcClient(),
        ]
      ),
      OutputBone(
        output: Output(
          language: Language.Dart,
          target: Target.Client,
          g: false
        ),
        children: [
          Folder('interceptors',[
            GrpcClientInterceptors()
          ])
        ]
      ),
      OutputBone(
        output: Output(
          language: Language.Kotlin,
          target: Target.Server,
          g: true
        ),
        children: [
          GrpcServer()
        ]
      ),
      OutputBone(
        output: Output(
          language: Language.Kotlin,
          target: Target.Server,
          g: false
        ),
        children: [
          Folder('interceptors', [
            GrpcInterceptors(),
          ]),
          Folder('services',[
            GrpcServices(),
          ]),
        ]
      )
    ]
  );
}

class GrpcTimeout extends ValueBone<int> {}

class GrpcInterceptors extends ListReaderBone<Interceptor> {
  @override
  String get regexp => 'class (.*)Interceptor : ServerInterceptor {';
  @override
  Interceptor createOnMatch(RegExpMatch match) => Interceptor(match.group(1) + 'Interceptor');
}

class GrpcPort extends ValueBone<int> {}

class GrpcClientInterceptors extends ListWriterBone<GrpcInterceptors, Interceptor> {
  @override
  String writeElement(Interceptor interceptor) {
    return '''
import 'package:grpc/grpc.dart';
${get<GrpcClient>().import()}

class ${interceptor.name} extends ServiceCallInterceptor {

  @override
  get outboundMetadataProvider => null;

}
   ''';
  }
}

class GrpcProtoFiles extends CopyFilesBone {
  GrpcProtoFiles({String protoFolder}) : super(fromFolder: protoFolder);
}

class GrpcServices extends ListReaderBone<Service> {

//  @override
//  FutureOr<List<Service>> readList(yaml) {
//    return listFromDir(
//      dirPath: serverRootPath + '/src/main/proto',
//      regExp: r'service (.*) {',
//      yaml: yaml,
//      createOnMatch: (fileName, match) => Service(match.group(1))..fileName = fileName
//    );
//  }

  @override
  Service readElement(Service service, dynamic yaml) {
    return service
      ..interceptors = yaml['interceptors']?.cast<String>() ?? [];
  }

  @override
  String get regexp => r'class (.*)Service : (.*) {';

  @override
  Service createOnMatch(RegExpMatch match) => Service(match.group(1) + 'Service');
}

class GrpcServer extends FileBone {
  GrpcServer() : super('GrpcBone', 'GrpcBone.kt');

  @override
  String write() {
    return '''
import io.grpc.Server
import io.grpc.ServerBuilder
import io.grpc.ServerInterceptors
${get<GrpcServices>().import()}
${get<GrpcInterceptors>().import()}
    
class GrpcBone {

    val server: Server

    init {
        ${loop(get<GrpcClientInterceptors>().list, 4, '\n', (Interceptor interceptor) {
          final interceptorName = interceptor.name.camelCase;
          final InterceptorName = interceptorName.pascalCase; // ignore: non_constant_identifier_names

          return 'val $interceptorName = $InterceptorName()';
        })}

        ${loop(_servicesNoInterceptors, 4, '\n', (Service service) {
          final serviceName = service.name.camelCase;
          final ServiceName = serviceName.pascalCase; // ignore: non_constant_identifier_names

          return 'val $serviceName = $ServiceName()';
        })}

        ${loop(_servicesInterceptors, 4, '\n', (Service service) {
          final serviceName = service.name.camelCase;
          final ServiceName = serviceName.pascalCase; // ignore: non_constant_identifier_names

          final interceptors = loop(service.interceptors, 0, ', ', (String name) =>
            name.camelCase
          );

          return 'val $serviceName = ServerInterceptors.intercept($ServiceName(), $interceptors)';
        })}

        server = ServerBuilder.forPort(${get<GrpcPort>().value})
            ${loop(_services, 6, '\n', (Service service) {
              final serviceName = service.name.camelCase;

              return '.addService($serviceName)';
            })}
            .build()

        server.start().awaitTermination()
    }
}
    ''';
  }

  List<Service> get _services => get<GrpcServices>().list;
  Iterable<Service> get _servicesNoInterceptors => _services.where((service)
    => service.interceptors.isEmpty);
  Iterable<Service> get _servicesInterceptors => _services.where((service)
    => service.interceptors.isNotEmpty);
}

Line l(String line) {
  return Line(line);
}

String block(String lead, List<Line> lines) {
  return Block(lead).write();
}

class Line {
  final String line;
  Line(this.line);
}

class Block {
  final String lead;
  String trail;
  Block(this.lead);

  String write() => '';
}

class GrpcClient extends FileBone {
  GrpcClient() : super('GrpcBone', 'grpc.dart');

  @override
  String write() {
    return '''
import 'package:flutter_managed/locator.dart';
import 'package:grpc/grpc.dart';
${get<GrpcClientInterceptors>().import()}
${get<GrpcProtoFiles>().import(where: (elem, fileInfo) => fileInfo.fileName.contains('.pbgrpc.'))}

class GrpcBone {

  final GrpcBoneHostConfig _hostConfig;

  GrpcBone(this._hostConfig) {
    final channel = ClientChannel(
      _hostConfig.host,
      port: ${get<GrpcPort>().value},
      options: const ChannelOptions(credentials: ChannelCredentials.insecure()),
    );
    
    ${loop(get<GrpcClientInterceptors>().list, 2, '\n', (Interceptor interceptor) {
      final interceptorName = interceptor.name.camelCase;
      final InterceptorName = interceptorName.pascalCase; // ignore: non_constant_identifier_names
      return 'final $interceptorName = $InterceptorName();';
    })}
    
    const timeout = const Duration(milliseconds: ${get<GrpcTimeout>().value});
    
    ${loop(get<GrpcServices>().list, 2, '\n', (Service service) {
      // ignore: non_constant_identifier_names
      final ServiceClient = service.name.replaceFirst('Service', 'Client').pascalCase;


      return'''
service($ServiceClient(channel, options: CallOptions(
  timeout: timeout, ${
  notEmptyThenLoop(service.interceptors,
    'providers: [',
      (String name) => '${name.camelCase}.outboundMetadataProvider',
    ']'
  )}
)));''';
    })}
  }

  static GrpcBoneHostConfig configureHost(String host) {
    return GrpcBoneHostConfig(host);
  }
}

class GrpcBoneHostConfig {
  final String host;

  GrpcBoneHostConfig(this.host);
}

abstract class ServiceCallInterceptor {

  MetadataProvider get outboundMetadataProvider;

}
  ''';
  }

  List<Service> get services => get<GrpcServices>().list;
  Iterable<Service> get _servicesNoInterceptors => services.where((service)
    => service.interceptors.isEmpty);
  Iterable<Service> get _servicesInterceptors => services.where((service)
    => service.interceptors.isNotEmpty);

}