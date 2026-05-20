import 'api/api_client.dart';
import 'api/auth_api.dart';
import 'api/devices_api.dart';
import 'api/events_api.dart';
import 'api/hub_api.dart';
import 'api/invites_api.dart';
import 'api/logs_api.dart';
import 'api/rfid_api.dart';
import 'api/users_api.dart';

//Facade che espone tutti gli API client. Singleton per semplicità.
//Mantiene anche il token corrente impostato sul client HTTP.
class GateKeeperApi {
  GateKeeperApi._() {
    _client = ApiClient();
    auth = AuthApi(_client);
    hub = HubApi(_client);
    users = UsersApi(_client);
    devices = DevicesApi(_client);
    events = EventsApi(_client);
    logs = LogsApi(_client);
    invites = InvitesApi(_client);
    rfid = RfidApi(_client);
  }

  static final GateKeeperApi instance = GateKeeperApi._();

  late final ApiClient _client;
  late final AuthApi auth;
  late final HubApi hub;
  late final UsersApi users;
  late final DevicesApi devices;
  late final EventsApi events;
  late final LogsApi logs;
  late final InvitesApi invites;
  late final RfidApi rfid;

  void setToken(String? token) => _client.setToken(token);
  String? get token => _client.token;
}
