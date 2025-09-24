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
} from '@nestjs/common';
import { GroupsService } from './groups.service';
import { CreateGroupDto } from './dto/create-group.dto';
import { UpdateGroupDto } from './dto/update-group.dto';
import { AddMemberDto } from './dto/add-member.dto';
import { RemoveMemberDto } from './dto/remove-member.dto';

@Controller('groups')
export class GroupsController {
  constructor(private readonly groupsService: GroupsService) { }

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