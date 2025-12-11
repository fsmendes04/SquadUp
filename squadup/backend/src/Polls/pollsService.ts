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
import * as DOMPurify from 'isomorphic-dompurify';
import { CreatePollDto } from './dto/create-poll.dto';
import { UpdatePollDto } from './dto/update-poll.dto';
import { CreateVoteDto } from './dto/create-vote.dto';
import { CreateOptionDto } from './dto/create-option.dto';
import { Poll, PollOption, PollVote } from './pollModel';

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
      const sanitizedOptions = createPollDto.options.map(option =>
        this.sanitizeString(option),
      );

      // Validate title length
      if (sanitizedTitle.length > this.MAX_TITLE_LENGTH) {
        throw new BadRequestException(
          `Title cannot exceed ${this.MAX_TITLE_LENGTH} characters`,
        );
      }

      // Validate option text lengths
      for (const option of sanitizedOptions) {
        if (option.length > this.MAX_OPTION_TEXT_LENGTH) {
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
      const optionsToInsert = sanitizedOptions.map(optionText => ({
        poll_id: pollData.id,
        text: optionText,
        vote_count: 0,
        created_at: new Date().toISOString(),
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

      // Verify user is the creator or group admin
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
        .eq('poll_id', pollId);

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
            .eq('poll_id', poll.id);

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
            .eq('poll_id', poll.id);

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

  private sanitizeString(input: string): string {
    if (!input) return '';
    const cleaned = DOMPurify.sanitize(input, {
      ALLOWED_TAGS: [],
      ALLOWED_ATTR: [],
    });
    return cleaned.trim();
  }
}