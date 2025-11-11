import 'dart:io';

void usage() {
  print('Usage: dart script.dart <start_port> <end_port>');
  print('Example: dart script.dart 7000 7005');
  exit(1);
}

void detectOS() {
  final os = Platform.operatingSystem;
  String osType;
  switch (os) {
    case 'linux':
      osType = 'Linux';
      break;
    case 'macos':
      osType = 'macOS';
      break;
    case 'windows':
      osType = 'Windows';
      break;
    default:
      osType = 'UNKNOWN';
  }

  if (osType == 'macOS') {
    noticeToMacOS();
  } else if (osType == 'UNKNOWN') {
    print('Error: Unsupported Operating System. Terminating script.');
    exit(1);
  }
}

void noticeToMacOS() {
  print(
      'On macOS, port 7000 is reserved by the system (ControlCenter/AirPlay).');
  print('Please start your Valkey cluster from port 7001 instead.');
}

Future<void> printOutput(int port) async {
  try {
    final socket = await Socket.connect('127.0.0.1', port,
        timeout: const Duration(milliseconds: 200));
    socket.destroy();
    print('Checking port $port... in use');

    if (Platform.isMacOS || Platform.isLinux) {
      final result = await Process.run('bash', [
        '-c',
        "lsof -nP | grep ':$port' | awk '{print \$2}' | sort -u | xargs -I{} ps -p {} -o comm="
      ]);
      print(result.stdout);
    } else if (Platform.isWindows) {
      final result = await Process.run('netstat', ['-ano']);
      final lines = result.stdout.toString().split('\n');
      for (var line in lines) {
        if (line.contains(':$port')) {
          print(line.trim());
        }
      }
    }
  } catch (_) {
    print('Checking port $port... available');
  }
  print('');
}

Future<void> checkPorts(int start, int end) async {
  if (start > end) {
    print('Error: start_port must be <= end_port.');
    usage();
  }
  for (var port = start; port <= end; port++) {
    await printOutput(port);
  }
}

Future<void> main(List<String> args) async {
  if (args.length < 2) {
    usage();
  }

  detectOS();

  final start = int.tryParse(args[0]);
  final end = int.tryParse(args[1]);

  if (start == null || end == null) {
    print('Error: Ports must be numeric.');
    usage();
  }

  await checkPorts(start!, end!);
}
