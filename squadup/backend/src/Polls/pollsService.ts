import {
  Injectable,
  NotFoundException,
  BadRequestException,
  ForbiddenException,
  Logger,
  UnauthorizedException
} from '@nestjs/common';
import { SupabaseService } from '../Supabase/supabaseService';
import { GroupsService } from '../Groups/groupsService';
import xss from 'xss';
import { CreatePollDto } from './dto/create-poll.dto';
import { UpdatePollDto } from './dto/update-poll.dto';
import { Poll, PollVote } from './pollModel';

@Injectable()
export class PollsService {
  private readonly logger = new Logger(PollsService.name);
  private readonly MAX_OPTIONS = 10;
  private readonly MIN_OPTIONS = 2;
  private readonly MAX_TITLE_LENGTH = 255;
  private readonly MAX_OPTION_TEXT_LENGTH = 255;

  constructor(
    private readonly supabaseService: SupabaseService,
    private readonly groupsService: GroupsService,
  ) { }

  async createPoll(
    createPollDto: CreatePollDto,
    userId: string,
    token: string,
  ): Promise<Poll> {
    try {
      if (!token) {
        throw new UnauthorizedException('Access token is required');
      }

      // Verify user is admin of the group
      const isGroupAdmin = await this.groupsService.checkUserIsAdmin(
        createPollDto.group_id,
        userId,
        token,
      );

      if (!isGroupAdmin) {
        throw new ForbiddenException('Only group admins can create polls');
      }

      // Validate options count
      if (
        createPollDto.options.length < this.MIN_OPTIONS ||
        createPollDto.options.length > this.MAX_OPTIONS
      ) {
        throw new BadRequestException(
          `Options must be between ${this.MIN_OPTIONS} and ${this.MAX_OPTIONS}`,
        );
      }

      // Sanitize inputs
      const sanitizedTitle = this.sanitizeString(createPollDto.title);
      const sanitizedOptions = createPollDto.options.map(option => ({
        text: this.sanitizeString(option.text),
        proposer_reward: option.proposer_reward,
        challenger_reward: option.challenger_reward,
        challenger_user_id: option.challenger_user_id,
      }));

      // Validate title length
      if (sanitizedTitle.length > this.MAX_TITLE_LENGTH) {
        throw new BadRequestException(
          `Title cannot exceed ${this.MAX_TITLE_LENGTH} characters`,
        );
      }

      // Validate option text lengths
      for (const option of sanitizedOptions) {
        if (option.text.length > this.MAX_OPTION_TEXT_LENGTH) {
          throw new BadRequestException(
            `Option text cannot exceed ${this.MAX_OPTION_TEXT_LENGTH} characters`,
          );
        }
      }

      const userClient = this.supabaseService.getClientWithToken(token);

      // Create poll in database
      const pollInsertData: any = {
        group_id: createPollDto.group_id,
        title: sanitizedTitle,
        type: createPollDto.type,
        status: 'active',
        created_by: userId,
        created_at: new Date().toISOString(),
        updated_at: new Date().toISOString(),
      };

      // Add closed_at if provided
      if (createPollDto.closed_at) {
        pollInsertData.closed_at = createPollDto.closed_at;
      }

      const { data: pollData, error: pollError } = await userClient
        .from('polls')
        .insert([pollInsertData])
        .select('*')
        .single();

      if (pollError) {
        this.logger.error('Poll creation error', pollError.message);
        throw new BadRequestException('Failed to create poll');
      }

      // Create poll options
      const optionsToInsert = sanitizedOptions.map(option => ({
        poll_id: pollData.id,
        text: option.text,
        vote_count: 0,
        created_at: new Date().toISOString(),
        proposer_reward_amount: option.proposer_reward?.amount || null,
        proposer_reward_text: option.proposer_reward?.text || null,
        challenger_reward_amount: option.challenger_reward?.amount || null,
        challenger_reward_text: option.challenger_reward?.text || null,
        challenger_user_id: option.challenger_user_id || null,
      }));

      const { data: optionsData, error: optionsError } = await userClient
        .from('poll_options')
        .insert(optionsToInsert)
        .select('*');

      if (optionsError) {
        this.logger.error('Poll options creation error', optionsError.message);
        throw new BadRequestException('Failed to create poll options');
      }

      this.logger.log(`Poll created successfully: ${pollData.id} by user: ${userId}`);

      return {
        ...pollData,
        options: optionsData,
        votes: [],
      };
    } catch (error) {
      if (
        error instanceof ForbiddenException ||
        error instanceof BadRequestException ||
        error instanceof UnauthorizedException
      ) {
        throw error;
      }
      this.logger.error('Unexpected error creating poll', error);
      throw new BadRequestException('Failed to create poll');
    }
  }

  async updatePoll(
    pollId: string,
    updatePollDto: UpdatePollDto,
    userId: string,
    token: string,
  ): Promise<Poll> {
    try {
      if (!token) {
        throw new UnauthorizedException('Access token is required');
      }

      if (!pollId) {
        throw new BadRequestException('Poll ID is required');
      }

      const userClient = this.supabaseService.getClientWithToken(token);

      // Get poll to verify ownership
      const { data: poll, error: pollError } = await userClient
        .from('polls')
        .select('*')
        .eq('id', pollId)
        .single();

      if (pollError || !poll) {
        throw new NotFoundException('Poll not found');
      }

      const isGroupAdmin = await this.groupsService.checkUserIsAdmin(
        poll.group_id,
        userId,
        token,
      );

      if (poll.created_by !== userId && !isGroupAdmin) {
        throw new ForbiddenException('You can only update your own polls');
      }

      // If setting correct_option_id, verify it belongs to this poll
      if (updatePollDto.correct_option_id) {
        const { data: option, error: optionError } = await userClient
          .from('poll_options')
          .select('*')
          .eq('id', updatePollDto.correct_option_id)
          .eq('poll_id', pollId)
          .single();

        if (optionError || !option) {
          throw new BadRequestException('Correct option does not belong to this poll');
        }

        // Verify poll is betting type
        if (poll.type !== 'betting') {
          throw new BadRequestException('Only betting type polls can have a correct answer');
        }
      }

      // Sanitize and build update payload
      const updateData: Record<string, any> = {};

      if (updatePollDto.title) {
        const sanitizedTitle = this.sanitizeString(updatePollDto.title);
        if (sanitizedTitle.length > this.MAX_TITLE_LENGTH) {
          throw new BadRequestException(
            `Title cannot exceed ${this.MAX_TITLE_LENGTH} characters`,
          );
        }
        updateData.title = sanitizedTitle;
      }

      if (updatePollDto.status) {
        updateData.status = updatePollDto.status;
        if (updatePollDto.status === 'closed') {
          updateData.closed_at = new Date().toISOString();
        }
      }

      if (updatePollDto.correct_option_id) {
        updateData.correct_option_id = updatePollDto.correct_option_id;
      }

      updateData.updated_at = new Date().toISOString();

      const { data: updatedPoll, error: updateError } = await userClient
        .from('polls')
        .update(updateData)
        .eq('id', pollId)
        .select('*')
        .single();

      if (updateError) {
        this.logger.error('Poll update error', updateError.message);
        throw new BadRequestException('Failed to update poll');
      }

      this.logger.log(`Poll updated successfully: ${pollId} by user: ${userId}`);

      // Get full poll with options and votes
      return await this.getPollWithDetails(pollId, token);
    } catch (error) {
      if (
        error instanceof NotFoundException ||
        error instanceof ForbiddenException ||
        error instanceof BadRequestException ||
        error instanceof UnauthorizedException
      ) {
        throw error;
      }
      this.logger.error('Unexpected error updating poll', error);
      throw new BadRequestException('Failed to update poll');
    }
  }

  private async getPollWithDetails(pollId: string, token: string): Promise<Poll> {
    try {
      if (!token) {
        throw new UnauthorizedException('Access token is required');
      }

      const userClient = this.supabaseService.getClientWithToken(token);

      const { data: poll, error: pollError } = await userClient
        .from('polls')
        .select('*')
        .eq('id', pollId)
        .single();

      if (pollError || !poll) {
        throw new NotFoundException('Poll not found');
      }

      const { data: options, error: optionsError } = await userClient
        .from('poll_options')
        .select('*')
        .eq('poll_id', pollId)
        .order('id', { ascending: true });

      if (optionsError) {
        this.logger.warn('Failed to fetch poll options', optionsError.message);
      }

      const { data: votes, error: votesError } = await userClient
        .from('poll_votes')
        .select('*')
        .eq('poll_id', pollId);

      if (votesError) {
        this.logger.warn('Failed to fetch poll votes', votesError.message);
      }

      return {
        ...poll,
        options: options || [],
        votes: votes || [],
      };
    } catch (error) {
      if (error instanceof NotFoundException || error instanceof UnauthorizedException) {
        throw error;
      }
      this.logger.error('Error fetching poll details', error);
      throw new BadRequestException('Failed to retrieve poll details');
    }
  }

  async getPollsByGroup(
    groupId: string,
    token: string,
  ): Promise<Poll[]> {
    try {
      if (!token) {
        throw new UnauthorizedException('Access token is required');
      }

      if (!groupId) {
        throw new BadRequestException('Group ID is required');
      }

      const userClient = this.supabaseService.getClientWithToken(token);

      const { data: polls, error: pollsError } = await userClient
        .from('polls')
        .select('*')
        .eq('group_id', groupId)
        .order('created_at', { ascending: false });

      if (pollsError) {
        this.logger.error('Error fetching polls by group', pollsError.message);
        throw new BadRequestException('Failed to fetch polls');
      }

      if (!polls || polls.length === 0) {
        return [];
      }

      // Fetch options and votes for each poll
      const pollsWithDetails = await Promise.all(
        polls.map(async (poll) => {
          const { data: options } = await userClient
            .from('poll_options')
            .select('*')
            .eq('poll_id', poll.id)
            .order('id', { ascending: true });

          const { data: votes } = await userClient
            .from('poll_votes')
            .select('*')
            .eq('poll_id', poll.id);

          return {
            ...poll,
            options: options || [],
            votes: votes || [],
          };
        }),
      );

      this.logger.log(`Fetched ${pollsWithDetails.length} polls for group: ${groupId}`);
      return pollsWithDetails;
    } catch (error) {
      if (
        error instanceof BadRequestException ||
        error instanceof UnauthorizedException
      ) {
        throw error;
      }
      this.logger.error('Unexpected error fetching polls by group', error);
      throw new BadRequestException('Failed to fetch polls');
    }
  }

  async getPollsByUser(
    userId: string,
    token: string,
  ): Promise<Poll[]> {
    try {
      if (!token) {
        throw new UnauthorizedException('Access token is required');
      }

      if (!userId) {
        throw new BadRequestException('User ID is required');
      }

      const userClient = this.supabaseService.getClientWithToken(token);

      const { data: polls, error: pollsError } = await userClient
        .from('polls')
        .select('*')
        .eq('created_by', userId)
        .order('created_at', { ascending: false });

      if (pollsError) {
        this.logger.error('Error fetching polls by user', pollsError.message);
        throw new BadRequestException('Failed to fetch polls');
      }

      if (!polls || polls.length === 0) {
        return [];
      }

      // Fetch options and votes for each poll
      const pollsWithDetails = await Promise.all(
        polls.map(async (poll) => {
          const { data: options } = await userClient
            .from('poll_options')
            .select('*')
            .eq('poll_id', poll.id)
            .order('id', { ascending: true });

          const { data: votes } = await userClient
            .from('poll_votes')
            .select('*')
            .eq('poll_id', poll.id);

          return {
            ...poll,
            options: options || [],
            votes: votes || [],
          };
        }),
      );

      this.logger.log(`Fetched ${pollsWithDetails.length} polls for user: ${userId}`);
      return pollsWithDetails;
    } catch (error) {
      if (
        error instanceof BadRequestException ||
        error instanceof UnauthorizedException
      ) {
        throw error;
      }
      this.logger.error('Unexpected error fetching polls by user', error);
      throw new BadRequestException('Failed to fetch polls');
    }
  }

  async castVote(
    pollId: string,
    optionId: string,
    userId: string,
    token: string,
  ): Promise<{ vote: PollVote; updatedPoll: Poll }> {
    try {
      if (!token) {
        throw new UnauthorizedException('Access token is required');
      }

      if (!pollId || !optionId) {
        throw new BadRequestException('Poll ID and Option ID are required');
      }

      const userClient = this.supabaseService.getClientWithToken(token);

      // Get poll to verify status and membership
      const { data: poll, error: pollError } = await userClient
        .from('polls')
        .select('*')
        .eq('id', pollId)
        .single();

      if (pollError || !poll) {
        throw new NotFoundException('Poll not found');
      }

      // Check if poll is still active
      if (poll.status !== 'active') {
        throw new BadRequestException('This poll is closed');
      }

      // Verify user is a member of the group
      const isMember = await this.groupsService.checkUserIsMember(
        poll.group_id,
        userId,
        token,
      );

      if (!isMember) {
        throw new ForbiddenException('You must be a group member to vote');
      }

      // Verify option belongs to this poll
      const { data: option, error: optionError } = await userClient
        .from('poll_options')
        .select('*')
        .eq('id', optionId)
        .eq('poll_id', pollId)
        .single();

      if (optionError || !option) {
        throw new BadRequestException('Invalid option for this poll');
      }

      // Check if user has already voted
      const { data: existingVote, error: existingVoteError } = await userClient
        .from('poll_votes')
        .select('*')
        .eq('poll_id', pollId)
        .eq('user_id', userId)
        .maybeSingle();

      if (existingVoteError && existingVoteError.code !== 'PGRST116') {
        this.logger.error('Error checking existing vote', existingVoteError.message);
        throw new BadRequestException('Failed to process vote');
      }

      let vote: PollVote;

      if (existingVote) {
        // User is changing their vote
        const oldOptionId = existingVote.option_id;

        // Update the vote
        const { data: updatedVote, error: updateError } = await userClient
          .from('poll_votes')
          .update({
            option_id: optionId,
          })
          .eq('id', existingVote.id)
          .select('*')
          .single();

        if (updateError) {
          this.logger.error('Error updating vote', updateError.message);
          throw new BadRequestException('Failed to update vote');
        }

        vote = updatedVote;

        // O trigger na base de dados trata do incremento/decremento do vote_count

        // Para betting polls, atualizar challenger_user_id
        if (poll.type === 'betting') {
          // Remove challenger_user_id from old option
          await userClient
            .from('poll_options')
            .update({ challenger_user_id: null })
            .eq('id', oldOptionId);

          // Add challenger_user_id to new option se não for o criador
          if (userId !== poll.created_by) {
            await userClient
              .from('poll_options')
              .update({ challenger_user_id: userId })
              .eq('id', optionId);
          }
        }

        this.logger.log(`Vote updated: poll ${pollId}, user ${userId}, from ${oldOptionId} to ${optionId}`);
      } else {
        // User is voting for the first time
        const { data: newVote, error: voteError } = await userClient
          .from('poll_votes')
          .insert([{
            poll_id: pollId,
            option_id: optionId,
            user_id: userId,
          }])
          .select('*')
          .single();

        if (voteError) {
          this.logger.error('Error creating vote', voteError.message);
          throw new BadRequestException('Failed to cast vote');
        }

        vote = newVote;

        // Para betting polls, registar challenger_user_id se não for o criador
        if (poll.type === 'betting' && userId !== poll.created_by) {
          const { error: updateError } = await userClient
            .from('poll_options')
            .update({ challenger_user_id: userId })
            .eq('id', optionId);

          if (updateError) {
            this.logger.warn('Error registering challenger user', updateError.message);
            // Continua mesmo se houver erro, pois o voto foi criado
          }
        }
      }
      const updatedPoll = await this.getPollWithDetails(pollId, token);

      return { vote, updatedPoll };
    } catch (error) {
      if (
        error instanceof NotFoundException ||
        error instanceof ForbiddenException ||
        error instanceof BadRequestException ||
        error instanceof UnauthorizedException
      ) {
        throw error;
      }
      throw new BadRequestException('Failed to cast vote');
    }
  }

  async userVotedInPoll(
    pollId: string,
    userId: string,
    token: string,
  ): Promise<string | null> {
    try {
      if (!token) {
        throw new UnauthorizedException('Access token is required');
      }
      if (!pollId || !userId) {
        throw new BadRequestException('Poll ID and User ID are required');
      }
      const userClient = this.supabaseService.getClientWithToken(token);
      const { data: vote, error: voteError } = await userClient
        .from('poll_votes')
        .select('*')
        .eq('poll_id', pollId)
        .eq('user_id', userId)
        .maybeSingle();
      if (voteError && voteError.code !== 'PGRST116') {
        this.logger.error('Error checking user vote', voteError.message);
        throw new BadRequestException('Failed to check vote status');
      }
      return vote ? vote.option_id : null;
    } catch (error) {
      if (
        error instanceof BadRequestException ||
        error instanceof UnauthorizedException
      ) {
        throw error;
      }
      this.logger.error('Unexpected error checking user vote', error);
      throw new BadRequestException('Failed to check vote status');
    }
  }

  async getPollVotes(
    pollId: string,
    userId: string,
    token: string,
  ): Promise<Array<{
    id: string;
    poll_id: string;
    option_id: string;
    user_id: string;
    user_name: string;
    created_at: string;
  }>> {
    try {
      if (!token) {
        throw new UnauthorizedException('Access token is required');
      }

      if (!pollId) {
        throw new BadRequestException('Poll ID is required');
      }

      const userClient = this.supabaseService.getClientWithToken(token);

      // Get poll to verify user belongs to the group
      const { data: poll, error: pollError } = await userClient
        .from('polls')
        .select('group_id')
        .eq('id', pollId)
        .single();

      if (pollError || !poll) {
        throw new NotFoundException('Poll not found');
      }

      // Verify user is a member of the group
      const isMember = await this.groupsService.checkUserIsMember(
        poll.group_id,
        userId,
        token,
      );

      if (!isMember) {
        throw new ForbiddenException('You must be a group member to view poll votes');
      }

      // Fetch all votes for the poll
      const { data: votes, error: votesError } = await userClient
        .from('poll_votes')
        .select('id, poll_id, option_id, user_id, created_at')
        .eq('poll_id', pollId)
        .order('created_at', { ascending: false });

      if (votesError) {
        this.logger.error('Error fetching poll votes', votesError.message);
        throw new BadRequestException('Failed to fetch poll votes');
      }

      if (!votes || votes.length === 0) {
        return [];
      }

      // Get unique user IDs
      const userIds = [...new Set(votes.map((vote: any) => vote.user_id))];

      // Fetch user details using admin client to access all profiles
      const adminClient = this.supabaseService.getAdminClient();
      const { data: users, error: usersError } = await adminClient
        .from('profiles')
        .select('id, name, avatar_url')
        .in('id', userIds);

      if (usersError) {
        this.logger.warn('Error fetching user details', usersError.message);
      }

      // Create a map of user IDs to user info (name and avatar_url)
      const userMap = new Map(
        (users || []).map((user: any) => [user.id, { name: user.name, avatar_url: user.avatar_url }]),
      );

      // Combine votes with user names and avatar_url
      return votes.map((vote: any) => {
        const user = userMap.get(vote.user_id) || { name: 'Unknown User', avatar_url: null };
        return {
          id: vote.id,
          poll_id: vote.poll_id,
          option_id: vote.option_id,
          user_id: vote.user_id,
          user_name: user.name,
          avatar_url: user.avatar_url,
          created_at: vote.created_at,
        };
      });
    } catch (error) {
      if (
        error instanceof BadRequestException ||
        error instanceof UnauthorizedException
      ) {
        throw error;
      }
      this.logger.error('Unexpected error fetching poll votes', error);
      throw new BadRequestException('Failed to retrieve poll votes');
    }
  }

  private sanitizeString(input: string): string {
    if (!input) return '';
    return xss(input, {
      whiteList: {},
      stripIgnoreTag: true,
      stripIgnoreTagBody: ['script']
    }).trim();
  }
}