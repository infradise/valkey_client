import 'package:test/test.dart';
// Import the data models
import 'package:valkey_client/src/cluster_info.dart';
// Import the top-level function to test
import 'package:valkey_client/src/cluster_slots_parser.dart';
// Import the exception types
import 'package:valkey_client/src/exceptions.dart';

void main() {
  group('parseClusterSlotsResponse (top-level)', () {
    // A realistic mock response from the 'CLUSTER SLOTS' command.
    final mockSlotsResponse = [
      [
        0,
        5460,
        ['127.0.0.1', 7000, 'master-id-1'],
        ['127.0.0.1', 7003, 'replica-id-1-of-1']
      ],
      [
        5461,
        10922,
        ['127.0.0.1', 7001, 'master-id-2'],
        ['127.0.0.1', 7004, 'replica-id-1-of-2']
      ],
      [
        10923,
        16383,
        ['127.0.0.1', 7002, 'master-id-3'],
        ['127.0.0.1', 7005, 'replica-id-1-of-3']
      ]
    ];

    test('should parse valid CLUSTER SLOTS response correctly', () {
      // Call the top-level function directly
      final result = parseClusterSlotsResponse(mockSlotsResponse);

      expect(result, isA<List<ClusterSlotRange>>());
      expect(result.length, 3);

      // Check first slot range
      expect(result[0].startSlot, 0);
      expect(result[0].endSlot, 5460);
      expect(result[0].master,
          ClusterNodeInfo(host: '127.0.0.1', port: 7000, id: 'master-id-1'));
      expect(result[0].replicas.length, 1);
      expect(result[0].replicas[0],
          ClusterNodeInfo(host: '127.0.0.1', port: 7003, id: 'replica-id-1-of-1'));
    });

    test('should handle nodes without IDs (older format)', () {
      final oldFormatResponse = [
        [
          0,
          16383,
          ['127.0.0.1', 7000], // Master without ID
          ['127.0.0.1', 7001]  // Replica without ID
        ]
      ];

      final result = parseClusterSlotsResponse(oldFormatResponse);
      expect(result.length, 1);
      expect(result[0].master,
          ClusterNodeInfo(host: '127.0.0.1', port: 7000, id: null));
      expect(result[0].replicas[0],
          ClusterNodeInfo(host: '127.0.0.1', port: 7001, id: null));
    });

    test('should handle slot range with no replicas', () {
      final noReplicaResponse = [
        [
          0,
          16383,
          ['127.0.0.1', 7000, 'master-id-1']
        ]
      ];

      final result = parseClusterSlotsResponse(noReplicaResponse);
      expect(result.length, 1);
      expect(result[0].master.id, 'master-id-1');
      expect(result[0].replicas, isEmpty);
    });

    test('should throw ValkeyParsingException on invalid response type', () {
      expect(() => parseClusterSlotsResponse('not a list'),
          throwsA(isA<ValkeyParsingException>()));
    });

    test('should skip invalid slot entry format', () {
      final invalidSlotEntry = [
        [0, 100] // Missing master info
      ];
      // Should skip, not throw
      expect(parseClusterSlotsResponse(invalidSlotEntry), isEmpty);
    });

    test('should throw ValkeyParsingException on invalid node info format', () {
      final invalidNodeInfo = [
        [
          0,
          100,
          ['127.0.0.1'] // Missing port
        ]
      ];
      expect(() => parseClusterSlotsResponse(invalidNodeInfo),
          throwsA(isA<ValkeyParsingException>()));
    });
  });
}