import {
  Injectable,
  NotFoundException,
  BadRequestException,
  ForbiddenException,
  Logger
} from '@nestjs/common';
import { SupabaseService } from '../Supabase/supabaseService';
import { CreateGroupDto } from './dto/create-group.dto';
import { UpdateGroupDto } from './dto/update-group.dto';
import { Group, GroupMember, GroupWithMembers } from './groupModel';
import xss from 'xss';

@Injectable()
export class GroupsService {
  private readonly logger = new Logger(GroupsService.name);
  private readonly MAX_NAME_LENGTH = 100;
  private readonly ALLOWED_IMAGE_TYPES = ['image/jpeg', 'image/jpg', 'image/png', 'image/webp'];
  private readonly MAX_FILE_SIZE = 5 * 1024 * 1024;
  private readonly MAX_MEMBERS_PER_GROUP = 50;

  constructor(private readonly supabaseService: SupabaseService) { }

  async createGroup(createGroupDto: CreateGroupDto, userId: string, token: string): Promise<Group> {
    try {
      const sanitizedName = this.sanitizeString(createGroupDto.name);
      if (!sanitizedName || sanitizedName.length === 0) {
        throw new BadRequestException('Group name cannot be empty');
      }
      if (sanitizedName.length > this.MAX_NAME_LENGTH) {
        throw new BadRequestException(`Group name cannot exceed ${this.MAX_NAME_LENGTH} characters`);
      }
      if (createGroupDto.memberIds && createGroupDto.memberIds.length > 0) {
        if (createGroupDto.memberIds.length > this.MAX_MEMBERS_PER_GROUP) {
          throw new BadRequestException(`Cannot add more than ${this.MAX_MEMBERS_PER_GROUP} members at once`);
        }
        const uniqueMemberIds = new Set(createGroupDto.memberIds);
        if (uniqueMemberIds.size !== createGroupDto.memberIds.length) {
          throw new BadRequestException('Duplicate member IDs are not allowed');
        }
        if (createGroupDto.memberIds.includes(userId)) {
          throw new BadRequestException('Creator is automatically added as admin');
        }
      }
      const client = this.supabaseService.getClientWithToken(token);
      
      // Obter o userId autenticado do token para garantir conformidade com RLS
      const { data: { user }, error: userError } = await client.auth.getUser();
      if (userError || !user) {
        this.logger.error('Failed to get authenticated user', userError?.message);
        throw new BadRequestException('Unable to verify user authentication');
      }
      
      const authenticatedUserId = user.id;
      
      // Usar admin client para bypass RLS - autenticação já foi validada acima
      const adminClient = this.supabaseService.getAdminClient();
      const { data: group, error: groupError } = await adminClient
        .from('groups')
        .insert({
          name: sanitizedName,
          created_by: authenticatedUserId,
        })
        .select()
        .single();
      if (groupError) {
        this.logger.error(`Failed to create group for user ${authenticatedUserId}`, groupError.message);
        throw new BadRequestException('Unable to create group');
      }
      const { error: memberError } = await adminClient
        .from('group_members')
        .insert({
          group_id: group.id,
          user_id: authenticatedUserId,
          role: 'admin',
        });
      if (memberError) {
        await adminClient
          .from('groups')
          .delete()
          .eq('id', group.id);
        this.logger.error(`Failed to add creator as admin for group ${group.id}`, memberError.message);
        throw new BadRequestException('Unable to initialize group membership');
      }
      if (createGroupDto.memberIds && createGroupDto.memberIds.length > 0) {
        await this.addInitialMembers(group.id, createGroupDto.memberIds, token);
      }
      this.logger.log(`Group created successfully: ${group.id} by user ${authenticatedUserId}`);
      return group;
    } catch (error) {
      if (error instanceof BadRequestException) {
        throw error;
      }
      this.logger.error('Unexpected error creating group', error);
      throw new BadRequestException('Failed to create group');
    }
  }

  async findAllGroups(token: string): Promise<Group[]> {
    try {
      const client = this.supabaseService.getClientWithToken(token);
      const { data: groups, error } = await client
        .from('groups')
        .select('*')
        .order('created_at', { ascending: false });

      if (error) {
        this.logger.error('Failed to fetch groups', error.message);
        throw new BadRequestException('Unable to fetch groups');
      }

      return groups || [];
    } catch (error) {
      if (error instanceof BadRequestException) {
        throw error;
      }
      this.logger.error('Unexpected error fetching groups', error);
      throw new BadRequestException('Failed to fetch groups');
    }
  }

  async findUserGroups(userId: string, token: string): Promise<GroupWithMembers[]> {
    try {
      if (!userId) {
        throw new BadRequestException('User ID is required');
      }

      const client = this.supabaseService.getClientWithToken(token);
      const { data: groupMembers, error } = await client
        .from('group_members')
        .select('group_id')
        .eq('user_id', userId);

      if (error) {
        this.logger.error(`Failed to fetch group_members for user ${userId}`, error.message);
        throw new BadRequestException('Unable to fetch user groups');
      }

      if (!groupMembers || groupMembers.length === 0) {
        return [];
      }

      const groupIds = groupMembers.map((gm: any) => gm.group_id);

      const { data: groups, error: groupsError } = await client
        .from('groups')
        .select('*')
        .in('id', groupIds);

      if (groupsError) {
        this.logger.error(`Failed to fetch groups for user ${userId}`, groupsError.message);
        throw new BadRequestException('Unable to fetch user groups');
      }

      if (!groups || groups.length === 0) {
        return [];
      }

      const groupsWithMembers: GroupWithMembers[] = [];
      for (const group of groups) {
        const members = await this.getGroupMembers(group.id, token);
        groupsWithMembers.push({
          ...group,
          avatar_url: group.avatar_url || null,
          members,
        });
      }

      return groupsWithMembers;

    } catch (error) {
      if (error instanceof BadRequestException) {
        throw error;
      }
      this.logger.error('Unexpected error fetching user groups', error);
      throw new BadRequestException('Failed to fetch user groups');
    }
  }

  async findOne(id: string, userId: string, token: string): Promise<GroupWithMembers> {
    try {
      if (!id) {
        throw new BadRequestException('Group ID is required');
      }

      const client = this.supabaseService.getClientWithToken(token);
      const { data: group, error: groupError } = await client
        .from('groups')
        .select('*')
        .eq('id', id)
        .single();

      if (groupError || !group) {
        throw new NotFoundException(`Group with ID ${id} not found`);
      }

      const isMember = await this.isUserMember(id, userId, token);
      if (!isMember) {
        throw new ForbiddenException('You are not a member of this group');
      }

      const members = await this.getGroupMembers(id, token);

      return {
        ...group,
        members,
      };

    } catch (error) {
      if (error instanceof NotFoundException || error instanceof ForbiddenException) {
        throw error;
      }
      this.logger.error('Unexpected error fetching group', error);
      throw new BadRequestException('Failed to fetch group');
    }
  }

  async updateGroup(id: string, updateGroupDto: UpdateGroupDto, userId: string, token: string): Promise<Group> {
    try {
      const isAdmin = await this.isUserAdmin(id, userId, token);
      if (!isAdmin) {
        throw new ForbiddenException('Only administrators can update the group');
      }

      const updatePayload: any = { updated_at: new Date().toISOString() };

      if (updateGroupDto.name !== undefined) {
        const sanitizedName = this.sanitizeString(updateGroupDto.name);

        if (!sanitizedName || sanitizedName.length === 0) {
          throw new BadRequestException('Group name cannot be empty');
        }

        if (sanitizedName.length > this.MAX_NAME_LENGTH) {
          throw new BadRequestException(`Group name cannot exceed ${this.MAX_NAME_LENGTH} characters`);
        }

        updatePayload.name = sanitizedName;
      }

      if (Object.keys(updatePayload).length === 1) {
        throw new BadRequestException('No valid fields to update');
      }

      const client = this.supabaseService.getClientWithToken(token);
      const { data: group, error } = await client
        .from('groups')
        .update(updatePayload)
        .eq('id', id)
        .select()
        .single();

      if (error || !group) {
        this.logger.error(`Failed to update group ${id}`, error?.message);
        throw new BadRequestException('Unable to update group');
      }

      this.logger.log(`Group ${id} updated successfully by user ${userId}`);
      return group;

    } catch (error) {
      if (error instanceof ForbiddenException || error instanceof BadRequestException) {
        throw error;
      }
      this.logger.error('Unexpected error updating group', error);
      throw new BadRequestException('Failed to update group');
    }
  }

  async deleteGroup(id: string, userId: string, token: string): Promise<void> {
    try {
      const isAdmin = await this.isUserAdmin(id, userId, token);
      if (!isAdmin) {
        throw new ForbiddenException('Only administrators can delete the group');
      }

      const client = this.supabaseService.getClientWithToken(token);
      const { data: group } = await client
        .from('groups')
        .select('created_by, avatar_url')
        .eq('id', id)
        .single();

      if (group && group.created_by !== userId) {
        throw new ForbiddenException('Only the group creator can delete the group');
      }

      if (group?.avatar_url) {
        await this.deleteGroupAvatar(id, group.avatar_url);
      }

      const { error: membersError } = await client
        .from('group_members')
        .delete()
        .eq('group_id', id);

      if (membersError) {
        this.logger.error(`Failed to delete members for group ${id}`, membersError.message);
        throw new BadRequestException('Unable to delete group members');
      }

      const { error: groupError } = await client
        .from('groups')
        .delete()
        .eq('id', id);

      if (groupError) {
        this.logger.error(`Failed to delete group ${id}`, groupError.message);
        throw new BadRequestException('Unable to delete group');
      }

      this.logger.log(`Group ${id} deleted successfully by user ${userId}`);

    } catch (error) {
      if (error instanceof ForbiddenException || error instanceof BadRequestException) {
        throw error;
      }
      this.logger.error('Unexpected error deleting group', error);
      throw new BadRequestException('Failed to delete group');
    }
  }

  async addMember(groupId: string, userIdToAdd: string, requesterId: string, token: string): Promise<GroupMember> {
    try {
      if (userIdToAdd === requesterId) {
        throw new BadRequestException('Cannot add yourself as a member');
      }

      const isAdmin = await this.isUserAdmin(groupId, requesterId, token);
      if (!isAdmin) {
        throw new ForbiddenException('Only administrators can add members');
      }

      const client = this.supabaseService.getClientWithToken(token);
      const { data: existingMember } = await client
        .from('group_members')
        .select('id')
        .eq('group_id', groupId)
        .eq('user_id', userIdToAdd)
        .single();

      if (existingMember) {
        throw new BadRequestException('User is already a member of the group');
      }

      const { count } = await client
        .from('group_members')
        .select('*', { count: 'exact', head: true })
        .eq('group_id', groupId);

      if (count && count >= this.MAX_MEMBERS_PER_GROUP) {
        throw new BadRequestException(`Group has reached maximum capacity of ${this.MAX_MEMBERS_PER_GROUP} members`);
      }

      const { data: member, error } = await client
        .from('group_members')
        .insert({
          group_id: groupId,
          user_id: userIdToAdd,
          role: 'member',
        })
        .select()
        .single();

      if (error || !member) {
        this.logger.error(`Failed to add member to group ${groupId}`, error?.message);
        throw new BadRequestException('Unable to add member');
      }

      this.logger.log(`User ${userIdToAdd} added to group ${groupId} by ${requesterId}`);
      return member;

    } catch (error) {
      if (error instanceof ForbiddenException || error instanceof BadRequestException) {
        throw error;
      }
      this.logger.error('Unexpected error adding member', error);
      throw new BadRequestException('Failed to add member');
    }
  }

  async removeMember(groupId: string, userIdToRemove: string, requesterId: string, token: string): Promise<void> {
    try {
      const isAdmin = await this.isUserAdmin(groupId, requesterId, token);
      const isSelfRemoval = userIdToRemove === requesterId;

      if (!isAdmin && !isSelfRemoval) {
        throw new ForbiddenException('Only administrators can remove other members');
      }

      const client = this.supabaseService.getClientWithToken(token);
      const { data: memberToRemove } = await client
        .from('group_members')
        .select('role')
        .eq('group_id', groupId)
        .eq('user_id', userIdToRemove)
        .single();

      if (!memberToRemove) {
        throw new NotFoundException('User is not a member of this group');
      }

      const { data: group } = await client
        .from('groups')
        .select('created_by')
        .eq('id', groupId)
        .single();

      if (group && group.created_by === userIdToRemove) {
        throw new ForbiddenException('The group creator cannot be removed. Delete the group instead.');
      }

      if (isSelfRemoval && memberToRemove.role === 'admin') {
        const { count } = await client
          .from('group_members')
          .select('*', { count: 'exact', head: true })
          .eq('group_id', groupId)
          .eq('role', 'admin');

        if (count === 1) {
          throw new ForbiddenException('Cannot remove the last administrator. Promote another member first.');
        }
      }

      const { error } = await client
        .from('group_members')
        .delete()
        .eq('group_id', groupId)
        .eq('user_id', userIdToRemove);

      if (error) {
        this.logger.error(`Failed to remove member from group ${groupId}`, error.message);
        throw new BadRequestException('Unable to remove member');
      }

      this.logger.log(`User ${userIdToRemove} removed from group ${groupId} by ${requesterId}`);

    } catch (error) {
      if (error instanceof ForbiddenException || error instanceof BadRequestException || error instanceof NotFoundException) {
        throw error;
      }
      this.logger.error('Unexpected error removing member', error);
      throw new BadRequestException('Failed to remove member');
    }
  }

  async uploadGroupAvatar(file: Express.Multer.File, groupId: string, userId: string, token: string): Promise<string> {
    try {
      const isAdmin = await this.isUserAdmin(groupId, userId, token);
      if (!isAdmin) {
        throw new ForbiddenException('Only administrators can update group avatar');
      }

      this.validateAvatarFile(file);

      const fileExtension = file.originalname.split('.').pop()?.toLowerCase() || 'jpg';
      const allowedExtensions = ['jpg', 'jpeg', 'png', 'webp'];

      if (!allowedExtensions.includes(fileExtension)) {
        throw new BadRequestException('Invalid file type. Allowed: JPG, PNG, WEBP');
      }

      const timestamp = Date.now();
      const randomStr = Math.random().toString(36).substring(2, 15);
      const fileName = `avatar_${timestamp}_${randomStr}.${fileExtension}`;
      const filePath = `${groupId}/${fileName}`;

      const adminClient = this.supabaseService.getAdminClient();
      const { error: uploadError } = await adminClient.storage
        .from('group-avatars')
        .upload(filePath, file.buffer, {
          contentType: file.mimetype,
          upsert: false,
          cacheControl: '3600'
        });

      if (uploadError) {
        this.logger.error(`Failed to upload avatar for group ${groupId}`, uploadError.message);
        throw new BadRequestException('Unable to upload avatar');
      }

      const client = this.supabaseService.getClientWithToken(token);
      const { data: publicUrlData } = client.storage
        .from('group-avatars')
        .getPublicUrl(filePath);

      this.logger.log(`Avatar uploaded for group ${groupId} by user ${userId}`);
      return publicUrlData.publicUrl;

    } catch (error) {
      if (error instanceof ForbiddenException || error instanceof BadRequestException) {
        throw error;
      }
      this.logger.error('Unexpected error uploading group avatar', error);
      throw new BadRequestException('Failed to upload avatar');
    }
  }

  async updateGroupAvatar(file: Express.Multer.File, groupId: string, userId: string, token: string): Promise<{ success: boolean; message: string; avatar_url: string }> {
    try {
      const client = this.supabaseService.getClientWithToken(token);
      const { data: currentGroup, error: getGroupError } = await client
        .from('groups')
        .select('avatar_url')
        .eq('id', groupId)
        .single();
      if (getGroupError) {
        throw new NotFoundException('Group not found');
      }
      if (currentGroup?.avatar_url) {
        await this.deleteGroupAvatar(groupId, currentGroup.avatar_url);
      }
      const avatarUrl = await this.uploadGroupAvatar(file, groupId, userId, token);
      const { error: updateError } = await client
        .from('groups')
        .update({
          avatar_url: avatarUrl,
          updated_at: new Date().toISOString()
        })
        .eq('id', groupId);
      if (updateError) {
        await this.deleteGroupAvatar(groupId, avatarUrl);
        this.logger.error(`Failed to update avatar URL for group ${groupId}`, updateError.message);
        throw new BadRequestException('Unable to update group avatar');
      }
      this.logger.log(`Avatar updated for group ${groupId} by user ${userId}`);
      return {
        success: true,
        message: 'Group avatar updated successfully',
        avatar_url: avatarUrl,
      };
    } catch (error) {
      if (error instanceof ForbiddenException || error instanceof BadRequestException || error instanceof NotFoundException) {
        throw error;
      }
      this.logger.error('Unexpected error updating group avatar', error);
      throw new BadRequestException('Failed to update group avatar');
    }
  }



  private async addInitialMembers(groupId: string, memberIds: string[], token: string): Promise<void> {
    try {
      const membersToAdd = memberIds.map(memberId => ({
        group_id: groupId,
        user_id: memberId,
        role: 'member' as const,
      }));

      const client = this.supabaseService.getClientWithToken(token);
      const { error } = await client
        .from('group_members')
        .insert(membersToAdd);

      if (error) {
        this.logger.warn(`Some members could not be added to group ${groupId}: ${error.message}`);
      }
    } catch (error) {
      this.logger.warn('Error adding initial members', error);
    }
  }

  private async getGroupMembers(groupId: string, token: string): Promise<GroupMember[]> {
    try {
      const client = this.supabaseService.getClientWithToken(token);

      const { data: rawMembers, error: rpcError } = await client.rpc('get_group_members_list', {
        group_id_in: groupId,
      });

      if (rpcError) {
        this.logger.error(`RPC failed to fetch members for group ${groupId}`, rpcError.message);
        if (rpcError.message.includes('User is not a member of group')) {
          throw new ForbiddenException('You are not authorized to view these group members');
        }
        throw new BadRequestException('Unable to fetch group members');
      }

      if (!rawMembers || rawMembers.length === 0) {
        return [];
      }

      const userIds = rawMembers.map((m: any) => m.user_id);

      const adminClient = this.supabaseService.getAdminClient();
      const { data: profiles, error: profileError } = await adminClient
        .from('profiles')
        .select(`id, name, avatar_url`)
        .in('id', userIds);

      if (profileError) {
        this.logger.error(`Failed to fetch profiles for members of group ${groupId}`, profileError.message);
        const membersWithoutProfiles = rawMembers.map((member: any) => ({
          ...member, name: null, avatar_url: null
        }));
        return membersWithoutProfiles;
      }

      const profileMap = new Map((profiles || []).map(p => [p.id, p]));

      return rawMembers.map((member: any) => {
        const profile = profileMap.get(member.user_id);
        return {
          id: member.id,
          group_id: member.group_id,
          user_id: member.user_id,
          joined_at: member.joined_at,
          role: member.role,
          name: profile?.name || null,
          avatar_url: profile?.avatar_url || null,
        };
      });

    } catch (error) {
      if (error instanceof BadRequestException || error instanceof ForbiddenException) {
        throw error;
      }
      this.logger.error('Unexpected error fetching group members', error);
      throw new BadRequestException('Failed to fetch group members');
    }
  }

  private async deleteGroupAvatar(groupId: string, avatarUrl: string): Promise<void> {
    try {
      const urlParts = avatarUrl.split('/');
      const fileName = urlParts[urlParts.length - 1];
      const filePath = `${groupId}/${fileName}`;

      const adminClient = this.supabaseService.getAdminClient();
      const { error } = await adminClient.storage
        .from('group-avatars')
        .remove([filePath]);

      if (error) {
        this.logger.warn(`Failed to delete avatar for group ${groupId}`, error.message);
      }
    } catch (error) {
      this.logger.warn('Error deleting group avatar', error);
    }
  }

  async checkUserIsAdmin(groupId: string, userId: string, token: string): Promise<boolean> {
    try {
      return await this.isUserAdmin(groupId, userId, token);
    } catch (error) {
      this.logger.warn(`Error checking admin status for user ${userId} in group ${groupId}`, error);
      return false;
    }
  }

  private async isUserAdmin(groupId: string, userId: string, token: string): Promise<boolean> {
    try {
      const client = this.supabaseService.getClientWithToken(token);
      const { data: member } = await client
        .from('group_members')
        .select('role')
        .eq('group_id', groupId)
        .eq('user_id', userId)
        .single();

      return member?.role === 'admin';
    } catch (error) {
      return false;
    }
  }

  private async isUserMember(groupId: string, userId: string, token: string): Promise<boolean> {
    try {
      const client = this.supabaseService.getClientWithToken(token);
      const { data: member } = await client
        .from('group_members')
        .select('id')
        .eq('group_id', groupId)
        .eq('user_id', userId)
        .single();

      return !!member;
    } catch (error) {
      return false;
    }
  }

  async checkUserIsMember(groupId: string, userId: string, token: string): Promise<boolean> {
    try {
      return await this.isUserMember(groupId, userId, token);
    } catch (error) {
      this.logger.warn(`Error checking member status for user ${userId} in group ${groupId}`, error);
      return false;
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

  private validateAvatarFile(file: Express.Multer.File): void {
    if (!this.ALLOWED_IMAGE_TYPES.includes(file.mimetype)) {
      throw new BadRequestException('Invalid file type. Allowed: JPEG, PNG, WEBP');
    }

    if (file.size > this.MAX_FILE_SIZE) {
      throw new BadRequestException('File size exceeds 5MB limit');
    }

    if (file.size === 0) {
      throw new BadRequestException('File is empty');
    }

    const signature = file.buffer.slice(0, 4).toString('hex');
    const validSignatures = [
      'ffd8ffe0', 'ffd8ffe1', 'ffd8ffe2',
      '89504e47',
      '52494646',
    ];
    if (!validSignatures.some(sig => signature.startsWith(sig))) {
      throw new BadRequestException('File content does not match declared type');
    }
  }
}