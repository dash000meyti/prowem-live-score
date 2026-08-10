import 'package:flutter_test/flutter_test.dart';
import 'package:prowem_live_score/features/tournament/domain/team.dart';

void main() {
  group('Team.fromJson', () {
    test('parses a team with a logo', () {
      final team = Team.fromJson({
        'id': 1,
        'name': 'Juventus',
        'logo_url': 'http://localhost/storage/teams/1/logo.png',
      });

      expect(team.id, 1);
      expect(team.name, 'Juventus');
      expect(team.logoUrl, 'http://localhost/storage/teams/1/logo.png');
    });

    test('parses a team without a logo', () {
      final team = Team.fromJson({'id': 2, 'name': 'Inter', 'logo_url': null});

      expect(team.id, 2);
      expect(team.name, 'Inter');
      expect(team.logoUrl, isNull);
    });
  });
}
