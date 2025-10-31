import {
  Controller,
  Get,
  Post,
  Body,
  Patch,
  Param,
  Delete,
  HttpCode,
  HttpStatus,
  UseInterceptors,
  UploadedFile,
  ParseFilePipe,
  MaxFileSizeValidator,
  FileTypeValidator,
  UseGuards,
  HttpException,
  Logger,
  BadRequestException,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { Throttle } from '@nestjs/throttler';
import { AuthGuard } from '../User/userToken';
import { CurrentUser } from '../common/decorators';
import { GroupsService } from './groupsService';
import { CreateGroupDto } from './dto/create-group.dto';
import { UpdateGroupDto } from './dto/update-group.dto';
import { AddMemberDto } from './dto/add-member.dto';
import { RemoveMemberDto } from './dto/remove-member.dto';

@Controller('groups')
@UseGuards(AuthGuard)
export class GroupsController {
  private readonly logger = new Logger(GroupsController.name);

  constructor(private readonly groupsService: GroupsService) { }

  @Post()
  @Throttle({ default: { limit: 10, ttl: 60000 } })
  async create(
    @Body() createGroupDto: CreateGroupDto,
    @CurrentUser() user: any,
  ) {
    try {
      if (!createGroupDto.name) {
        throw new BadRequestException('Group name is required');
      }

      const group = await this.groupsService.createGroup(createGroupDto, user.id);

      return {
        success: true,
        message: 'Group created successfully',
        data: group,
      };
    } catch (error) {
      this.logger.error('Group creation error', error.message);

      const statusCode = error.status || HttpStatus.BAD_REQUEST;
      throw new HttpException(
        {
          success: false,
          message: error.message || 'Failed to create group',
        },
        statusCode,
      );
    }
  }

  @Get()
  @Throttle({ default: { limit: 30, ttl: 60000 } })
  async findAll() {
    try {
      const groups = await this.groupsService.findAllGroups();

      return {
        success: true,
        message: 'Groups retrieved successfully',
        data: groups,
      };
    } catch (error) {
      this.logger.error('Error fetching groups', error.message);

      throw new HttpException(
        {
          success: false,
          message: error.message || 'Failed to fetch groups',
        },
        error.status || HttpStatus.BAD_REQUEST,
      );
    }
  }

  @Get('user')
  @Throttle({ default: { limit: 30, ttl: 60000 } })
  async findUserGroups(@CurrentUser() user: any) {
    try {
      const groups = await this.groupsService.findUserGroups(user.id);

      return {
        success: true,
        message: 'User groups retrieved successfully',
        data: groups,
      };
    } catch (error) {
      this.logger.error('Error fetching user groups', error.message);

      throw new HttpException(
        {
          success: false,
          message: error.message || 'Failed to fetch user groups',
        },
        error.status || HttpStatus.BAD_REQUEST,
      );
    }
  }

  @Get(':id')
  @Throttle({ default: { limit: 30, ttl: 60000 } })
  async findOne(
    @Param('id') id: string,
    @CurrentUser() user: any,
  ) {
    try {
      const group = await this.groupsService.findOne(id, user.id);

      return {
        success: true,
        message: 'Group retrieved successfully',
        data: group,
      };
    } catch (error) {
      this.logger.error('Error fetching group', error.message);

      const statusCode = error.status || HttpStatus.BAD_REQUEST;
      throw new HttpException(
        {
          success: false,
          message: error.message || 'Failed to fetch group',
        },
        statusCode,
      );
    }
  }

  @Patch(':id')
  @Throttle({ default: { limit: 10, ttl: 60000 } })
  async update(
    @Param('id') id: string,
    @Body() updateGroupDto: UpdateGroupDto,
    @CurrentUser() user: any,
  ) {
    try {
      if (!updateGroupDto.name) {
        throw new BadRequestException('At least one field must be provided for update');
      }

      const group = await this.groupsService.updateGroup(id, updateGroupDto, user.id);

      return {
        success: true,
        message: 'Group updated successfully',
        data: group,
      };
    } catch (error) {
      this.logger.error('Group update error', error.message);

      const statusCode = error.status || HttpStatus.BAD_REQUEST;
      throw new HttpException(
        {
          success: false,
          message: error.message || 'Failed to update group',
        },
        statusCode,
      );
    }
  }

  @Delete(':id')
  @Throttle({ default: { limit: 5, ttl: 60000 } })
  @HttpCode(HttpStatus.NO_CONTENT)
  async remove(
    @Param('id') id: string,
    @CurrentUser() user: any,
  ) {
    try {
      await this.groupsService.deleteGroup(id, user.id);

      return {
        success: true,
        message: 'Group deleted successfully',
      };
    } catch (error) {
      this.logger.error('Group deletion error', error.message);

      const statusCode = error.status || HttpStatus.BAD_REQUEST;
      throw new HttpException(
        {
          success: false,
          message: error.message || 'Failed to delete group',
        },
        statusCode,
      );
    }
  }

  @Post(':id/members')
  @Throttle({ default: { limit: 10, ttl: 60000 } })
  async addMember(
    @Param('id') groupId: string,
    @Body() addMemberDto: AddMemberDto,
    @CurrentUser() user: any,
  ) {
    try {
      if (!addMemberDto.userId) {
        throw new BadRequestException('User ID is required');
      }

      const member = await this.groupsService.addMember(
        groupId,
        addMemberDto.userId,
        user.id,
      );

      return {
        success: true,
        message: 'Member added successfully',
        data: member,
      };
    } catch (error) {
      this.logger.error('Add member error', error.message);

      const statusCode = error.status || HttpStatus.BAD_REQUEST;
      throw new HttpException(
        {
          success: false,
          message: error.message || 'Failed to add member',
        },
        statusCode,
      );
    }
  }

  @Delete(':id/members')
  @Throttle({ default: { limit: 10, ttl: 60000 } })
  @HttpCode(HttpStatus.NO_CONTENT)
  async removeMember(
    @Param('id') groupId: string,
    @Body() removeMemberDto: RemoveMemberDto,
    @CurrentUser() user: any,
  ) {
    try {
      if (!removeMemberDto.userId) {
        throw new BadRequestException('User ID is required');
      }

      await this.groupsService.removeMember(
        groupId,
        removeMemberDto.userId,
        user.id,
      );

      return {
        success: true,
        message: 'Member removed successfully',
      };
    } catch (error) {
      this.logger.error('Remove member error', error.message);

      const statusCode = error.status || HttpStatus.BAD_REQUEST;
      throw new HttpException(
        {
          success: false,
          message: error.message || 'Failed to remove member',
        },
        statusCode,
      );
    }
  }

  @Post(':id/avatar')
  @UseInterceptors(FileInterceptor('avatar'))
  @Throttle({ default: { limit: 5, ttl: 60000 } })
  async uploadAvatar(
    @Param('id') groupId: string,
    @UploadedFile(
      new ParseFilePipe({
        validators: [
          new MaxFileSizeValidator({ maxSize: 5 * 1024 * 1024 }), // 5MB
          new FileTypeValidator({ fileType: /^image\/(jpeg|jpg|png|webp)$/ }),
        ],
      }),
    )
    file: Express.Multer.File,
    @CurrentUser() user: any,
  ) {
    try {
      const result = await this.groupsService.updateGroupAvatar(file, groupId, user.id);

      return {
        success: true,
        message: 'Group avatar uploaded successfully',
        data: result,
      };
    } catch (error) {
      this.logger.error('Avatar upload error', error.message);

      const statusCode = error.status || HttpStatus.BAD_REQUEST;
      throw new HttpException(
        {
          success: false,
          message: error.message || 'Failed to upload group avatar',
        },
        statusCode,
      );
    }
  }
}