
import 'package:dio/dio.dart';
import 'api_service.dart';

class PollsService {
	final ApiService _api = ApiService();

	Future<Response> createPoll(Map<String, dynamic> data) async {
		return await _api.post(ApiService.pollsEndpoint, data: data);
	}

	Future<Response> updatePoll(String pollId, Map<String, dynamic> data) async {
		return await _api.put(ApiService.pollById(pollId), data: data);
	}

	Future<Response> getPollsByGroup(String groupId) async {
		return await _api.get(ApiService.pollsByGroup(groupId));
	}

	Future<Response> getPollsByUser(String userId) async {
		return await _api.get(ApiService.pollsByUser(userId));
	}

  Future<Response> voteInPoll(String pollId, Map<String, dynamic> data) async {
    return await _api.post(ApiService.voteInPoll(pollId), data: data);
  }

  Future<Response> getUserVoteInPoll(String pollId) async {
    return await _api.get(ApiService.userVoteInPoll(pollId));
  }
}
