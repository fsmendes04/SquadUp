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
  Query,
  UseInterceptors,
  UploadedFile,
  ParseFilePipe,
  MaxFileSizeValidator,
  FileTypeValidator,
  UseGuards,
  Req,
  HttpException,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { AuthGuard } from '../auth/auth.guard';
import { CurrentUser } from '../auth/current-user.decorator';
import { GroupsService } from './groups.service';
import { CreateGroupDto } from './dto/create-group.dto';
import { UpdateGroupDto } from './dto/update-group.dto';
import { AddMemberDto } from './dto/add-member.dto';
import { RemoveMemberDto } from './dto/remove-member.dto';

@Controller('groups')
export class GroupsController {
  constructor(private readonly groupsService: GroupsService) { }
  @Post(':id/avatar')
  @UseGuards(AuthGuard)
  @UseInterceptors(FileInterceptor('avatar'))
  async uploadAvatar(
    @Param('id') groupId: string,
    @UploadedFile(
      new ParseFilePipe({
        validators: [
          new MaxFileSizeValidator({ maxSize: 5 * 1024 * 1024 }), // 5MB
          new FileTypeValidator({ fileType: /^image\/(jpeg|jpg|png|gif|webp)$/ }),
        ],
      }),
    )
    file: Express.Multer.File,
    @CurrentUser() user: any,
    @Req() request: any,
  ) {
    try {
      console.log('🔍 Debug uploadGroupAvatar - user object:', user);
      console.log('🔍 Debug uploadGroupAvatar - user.id:', user?.id);

      const accessToken = request.accessToken;
      const result = await this.groupsService.updateGroupAvatar(file, groupId, user.id, accessToken);

      return {
        success: true,
        message: 'Group avatar uploaded successfully',
        data: result,
      };
    } catch (error) {
      throw new HttpException(
        {
          success: false,
          message: 'Error uploading group avatar',
          error: error.message,
        },
        HttpStatus.BAD_REQUEST,
      );
    }
  }

  @Post()
  async create(
    @Body() createGroupDto: CreateGroupDto,
    @Query('userId') userId: string,
  ) {
    return this.groupsService.createGroup(createGroupDto, userId);
  }

  @Get()
  async findAll() {
    return this.groupsService.findAllGroups();
  }

  @Get('user/:userId')
  async findUserGroups(@Param('userId') userId: string) {
    return this.groupsService.findUserGroups(userId);
  }

  @Get(':id')
  async findOne(@Param('id') id: string) {
    return this.groupsService.findOne(id);
  }

  @Patch(':id')
  async update(
    @Param('id') id: string,
    @Body() updateGroupDto: UpdateGroupDto,
    @Query('userId') userId: string,
  ) {
    // description removido do DTO
    return this.groupsService.updateGroup(id, updateGroupDto, userId);
  }

  @Delete(':id')
  @HttpCode(HttpStatus.NO_CONTENT)
  async remove(
    @Param('id') id: string,
    @Query('userId') userId: string,
  ) {
    return this.groupsService.deleteGroup(id, userId);
  }

  @Post(':id/members')
  async addMember(
    @Param('id') groupId: string,
    @Body() addMemberDto: AddMemberDto,
    @Query('requesterId') requesterId: string,
  ) {
    return this.groupsService.addMember(
      groupId,
      addMemberDto.userId,
      requesterId,
    );
  }

  @Delete(':id/members')
  @HttpCode(HttpStatus.NO_CONTENT)
  async removeMember(
    @Param('id') groupId: string,
    @Body() removeMemberDto: RemoveMemberDto,
    @Query('requesterId') requesterId: string,
  ) {
    return this.groupsService.removeMember(
      groupId,
      removeMemberDto.userId,
      requesterId,
    );
  }
}