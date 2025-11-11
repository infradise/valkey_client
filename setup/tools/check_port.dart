import 'dart:io';

void usage() {
  print('Usage: dart script.dart <start_port> <end_port>');
  print('Example: dart script.dart 7000 7005');
  exit(1);
}

Future<void> printOutput(int port, String status, String output) async {
  print('Checking port $port... $status');
  if (output.isNotEmpty) {
    var pidResult = await Process.run(
      'bash',
      ['-c', "lsof -nP | grep ':$port' | awk '{print \$2}' | sort -u"],
    );
    var pid = pidResult.stdout.toString().trim();
    if (pid.isNotEmpty) {
      var procResult = await Process.run('ps', ['-p', pid, '-o', 'comm=']);
      print(procResult.stdout.toString().trim());
    }
    print('');
  }
}

Future<void> checkPorts(int start, int end) async {
  if (start > end) {
    print('Error: start_port must be <= end_port.');
    usage();
  }

  for (var port = start; port <= end; port++) {
    var result = await Process.run('lsof', ['-i', ':$port']);
    var output = result.stdout.toString().trim();
    var status = output.isNotEmpty ? 'in use' : 'available';
    await printOutput(port, status, output);
  }
}

void detectOS() {
  var os = Platform.operatingSystem;
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

Future<void> main(List<String> args) async {
  if (args.length < 2) {
    usage();
  }

  detectOS();

  var start = int.tryParse(args[0]);
  var end = int.tryParse(args[1]);

  if (start == null || end == null) {
    print('Error: Ports must be numeric.');
    usage();
  }

  await checkPorts(start!, end!);
}
