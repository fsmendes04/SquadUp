import {
  Controller,
  Post,
  Put,
  Get,
  Body,
  Param,
  UseGuards,
  HttpException,
  HttpStatus,
  Logger,
  BadRequestException,
} from '@nestjs/common';
import { Throttle } from '@nestjs/throttler';
import { AuthGuard } from '../User/userToken';
import { CurrentUser, GetToken } from '../common/decorators';
import { PollsService } from './pollsService';
import { CreatePollDto } from './dto/create-poll.dto';
import { UpdatePollDto } from './dto/update-poll.dto';

@Controller('polls')
@UseGuards(AuthGuard)
export class PollsController {
  private readonly logger = new Logger(PollsController.name);

  constructor(private readonly pollsService: PollsService) { }

  @Post()
  @Throttle({ default: { limit: 20, ttl: 60000 } })
  async createPoll(
    @Body() createPollDto: CreatePollDto,
    @CurrentUser() user: any,
    @GetToken() token: string,
  ) {
    try {
      if (!createPollDto.group_id) {
        throw new BadRequestException('Group ID is required');
      }

      if (!createPollDto.options || createPollDto.options.length < 2) {
        throw new BadRequestException('At least 2 options are required');
      }

      const poll = await this.pollsService.createPoll(createPollDto, user.id, token);

      return {
        success: true,
        message: 'Poll created successfully',
        data: poll,
      };
    } catch (error) {
      this.logger.error('Poll creation error', error.message);

      const statusCode = error.status || HttpStatus.BAD_REQUEST;
      throw new HttpException(
        {
          success: false,
          message: error.message || 'Failed to create poll',
        },
        statusCode,
      );
    }
  }

  @Put(':pollId')
  @Throttle({ default: { limit: 20, ttl: 60000 } })
  async updatePoll(
    @Param('pollId') pollId: string,
    @Body() updatePollDto: UpdatePollDto,
    @CurrentUser() user: any,
    @GetToken() token: string,
  ) {
    try {
      if (!pollId) {
        throw new BadRequestException('Poll ID is required');
      }

      const poll = await this.pollsService.updatePoll(pollId, updatePollDto, user.id, token);

      return {
        success: true,
        message: 'Poll updated successfully',
        data: poll,
      };
    } catch (error) {
      this.logger.error('Poll update error', error.message);

      const statusCode = error.status || HttpStatus.BAD_REQUEST;
      throw new HttpException(
        {
          success: false,
          message: error.message || 'Failed to update poll',
        },
        statusCode,
      );
    }
  }

  @Get('group/:groupId')
  @Throttle({ default: { limit: 30, ttl: 60000 } })
  async getPollsByGroup(
    @Param('groupId') groupId: string,
    @GetToken() token: string,
  ) {
    try {
      if (!groupId) {
        throw new BadRequestException('Group ID is required');
      }

      const polls = await this.pollsService.getPollsByGroup(groupId, token);

      return {
        success: true,
        message: 'Polls retrieved successfully',
        data: polls,
      };
    } catch (error) {
      this.logger.error('Error fetching polls by group', error.message);

      const statusCode = error.status || HttpStatus.BAD_REQUEST;
      throw new HttpException(
        {
          success: false,
          message: error.message || 'Failed to retrieve polls',
        },
        statusCode,
      );
    }
  }

  @Get('user/:userId')
  @Throttle({ default: { limit: 30, ttl: 60000 } })
  async getPollsByUser(
    @Param('userId') userId: string,
    @GetToken() token: string,
  ) {
    try {
      if (!userId) {
        throw new BadRequestException('User ID is required');
      }

      const polls = await this.pollsService.getPollsByUser(userId, token);

      return {
        success: true,
        message: 'Polls retrieved successfully',
        data: polls,
      };
    } catch (error) {
      this.logger.error('Error fetching polls by user', error.message);

      const statusCode = error.status || HttpStatus.BAD_REQUEST;
      throw new HttpException(
        {
          success: false,
          message: error.message || 'Failed to retrieve polls',
        },
        statusCode,
      );
    }
  }
}