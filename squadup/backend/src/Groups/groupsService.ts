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
import * as DOMPurify from 'isomorphic-dompurify';

@Injectable()
export class GroupsService {
  private readonly logger = new Logger(GroupsService.name);
  private readonly MAX_NAME_LENGTH = 100;
  private readonly ALLOWED_IMAGE_TYPES = ['image/jpeg', 'image/jpg', 'image/png', 'image/webp'];
  private readonly MAX_FILE_SIZE = 5 * 1024 * 1024; // 5MB
  private readonly MAX_MEMBERS_PER_GROUP = 50;

  constructor(private readonly supabaseService: SupabaseService) { }

  async createGroup(createGroupDto: CreateGroupDto, userId: string): Promise<Group> {
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
      const { data: group, error: groupError } = await this.supabaseService.getClient()
        .from('groups')
        .insert({
          name: sanitizedName,
          created_by: userId,
        })
        .select()
        .single();
      if (groupError) {
        this.logger.error(`Failed to create group for user ${userId}`, groupError.message);
        throw new BadRequestException('Unable to create group');
      }
      const { error: memberError } = await this.supabaseService.getClient()
        .from('group_members')
        .insert({
          group_id: group.id,
          user_id: userId,
          role: 'admin',
        });
      if (memberError) {
        await this.supabaseService.getClient()
          .from('groups')
          .delete()
          .eq('id', group.id);
        this.logger.error(`Failed to add creator as admin for group ${group.id}`, memberError.message);
        throw new BadRequestException('Unable to initialize group membership');
      }
      if (createGroupDto.memberIds && createGroupDto.memberIds.length > 0) {
        await this.addInitialMembers(group.id, createGroupDto.memberIds);
      }
      this.logger.log(`Group created successfully: ${group.id} by user ${userId}`);
      return group;
    } catch (error) {
      if (error instanceof BadRequestException) {
        throw error;
      }
      this.logger.error('Unexpected error creating group', error);
      throw new BadRequestException('Failed to create group');
    }
  }

  async findAllGroups(): Promise<Group[]> {
    try {
      const { data: groups, error } = await this.supabaseService.getClient()
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

  async findUserGroups(userId: string): Promise<GroupWithMembers[]> {
    try {
      if (!userId) {
        throw new BadRequestException('User ID is required');
      }

      const { data: userGroups, error } = await this.supabaseService.getClient()
        .from('group_members')
        .select(`
          groups (
            id,
            name,
            created_at,
            updated_at,
            created_by,
            avatar_url
          )
        `)
        .eq('user_id', userId);

      if (error) {
        this.logger.error(`Failed to fetch groups for user ${userId}`, error.message);
        throw new BadRequestException('Unable to fetch user groups');
      }

      if (!userGroups || userGroups.length === 0) {
        return [];
      }

      const groupsWithMembers: GroupWithMembers[] = [];

      for (const userGroup of userGroups) {
        if (userGroup.groups) {
          const groupData = Array.isArray(userGroup.groups) ? userGroup.groups[0] : userGroup.groups;
          const group = groupData as Group;
          const members = await this.getGroupMembers(group.id);
          groupsWithMembers.push({
            ...group,
            avatar_url: group.avatar_url || null,
            members,
          });
        }
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

  async findOne(id: string, userId?: string): Promise<GroupWithMembers> {
    try {
      if (!id) {
        throw new BadRequestException('Group ID is required');
      }

      const { data: group, error: groupError } = await this.supabaseService.getClient()
        .from('groups')
        .select('*')
        .eq('id', id)
        .single();

      if (groupError || !group) {
        throw new NotFoundException(`Group with ID ${id} not found`);
      }

      // Verificar se o usuário é membro (se userId fornecido)
      if (userId) {
        const isMember = await this.isUserMember(id, userId);
        if (!isMember) {
          throw new ForbiddenException('You are not a member of this group');
        }
      }

      const members = await this.getGroupMembers(id);

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

  async updateGroup(id: string, updateGroupDto: UpdateGroupDto, userId: string): Promise<Group> {
    try {
      // Verificar permissões
      const isAdmin = await this.isUserAdmin(id, userId);
      if (!isAdmin) {
        throw new ForbiddenException('Only administrators can update the group');
      }

      // Validar e sanitizar dados
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

      if (Object.keys(updatePayload).length === 1) { // Apenas updated_at
        throw new BadRequestException('No valid fields to update');
      }

      const { data: group, error } = await this.supabaseService.getClient()
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

  async deleteGroup(id: string, userId: string): Promise<void> {
    try {
      // Verificar permissões
      const isAdmin = await this.isUserAdmin(id, userId);
      if (!isAdmin) {
        throw new ForbiddenException('Only administrators can delete the group');
      }

      // Verificar se é o criador
      const { data: group } = await this.supabaseService.getClient()
        .from('groups')
        .select('created_by, avatar_url')
        .eq('id', id)
        .single();

      if (group && group.created_by !== userId) {
        throw new ForbiddenException('Only the group creator can delete the group');
      }

      // Deletar avatar se existir
      if (group?.avatar_url) {
        await this.deleteGroupAvatar(id, group.avatar_url);
      }

      // Deletar membros primeiro (foreign key constraint)
      const { error: membersError } = await this.supabaseService.getClient()
        .from('group_members')
        .delete()
        .eq('group_id', id);

      if (membersError) {
        this.logger.error(`Failed to delete members for group ${id}`, membersError.message);
        throw new BadRequestException('Unable to delete group members');
      }

      // Deletar o grupo
      const { error: groupError } = await this.supabaseService.getClient()
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

  async addMember(groupId: string, userIdToAdd: string, requesterId: string): Promise<GroupMember> {
    try {
      // Validações básicas
      if (userIdToAdd === requesterId) {
        throw new BadRequestException('Cannot add yourself as a member');
      }

      // Verificar permissões
      const isAdmin = await this.isUserAdmin(groupId, requesterId);
      if (!isAdmin) {
        throw new ForbiddenException('Only administrators can add members');
      }

      // Verificar se já é membro
      const { data: existingMember } = await this.supabaseService.getClient()
        .from('group_members')
        .select('id')
        .eq('group_id', groupId)
        .eq('user_id', userIdToAdd)
        .single();

      if (existingMember) {
        throw new BadRequestException('User is already a member of the group');
      }

      // Verificar limite de membros
      const { count } = await this.supabaseService.getClient()
        .from('group_members')
        .select('*', { count: 'exact', head: true })
        .eq('group_id', groupId);

      if (count && count >= this.MAX_MEMBERS_PER_GROUP) {
        throw new BadRequestException(`Group has reached maximum capacity of ${this.MAX_MEMBERS_PER_GROUP} members`);
      }

      // Adicionar membro
      const { data: member, error } = await this.supabaseService.getClient()
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

  async removeMember(groupId: string, userIdToRemove: string, requesterId: string): Promise<void> {
    try {
      // Verificar permissões
      const isAdmin = await this.isUserAdmin(groupId, requesterId);
      const isSelfRemoval = userIdToRemove === requesterId;

      if (!isAdmin && !isSelfRemoval) {
        throw new ForbiddenException('Only administrators can remove other members');
      }

      // Verificar se o usuário a ser removido existe no grupo
      const { data: memberToRemove } = await this.supabaseService.getClient()
        .from('group_members')
        .select('role')
        .eq('group_id', groupId)
        .eq('user_id', userIdToRemove)
        .single();

      if (!memberToRemove) {
        throw new NotFoundException('User is not a member of this group');
      }

      // Não permitir remover o criador
      const { data: group } = await this.supabaseService.getClient()
        .from('groups')
        .select('created_by')
        .eq('id', groupId)
        .single();

      if (group && group.created_by === userIdToRemove) {
        throw new ForbiddenException('The group creator cannot be removed. Delete the group instead.');
      }

      // Admin não pode se auto-remover se for o último admin
      if (isSelfRemoval && memberToRemove.role === 'admin') {
        const { count } = await this.supabaseService.getClient()
          .from('group_members')
          .select('*', { count: 'exact', head: true })
          .eq('group_id', groupId)
          .eq('role', 'admin');

        if (count === 1) {
          throw new ForbiddenException('Cannot remove the last administrator. Promote another member first.');
        }
      }

      // Remover membro
      const { error } = await this.supabaseService.getClient()
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

  async uploadGroupAvatar(file: Express.Multer.File, groupId: string, userId: string): Promise<string> {
    try {
      // Validar permissões
      const isAdmin = await this.isUserAdmin(groupId, userId);
      if (!isAdmin) {
        throw new ForbiddenException('Only administrators can update group avatar');
      }

      // Validar arquivo
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

      // Upload usando admin client
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

      // Obter URL pública
      const { data: publicUrlData } = this.supabaseService.getClient().storage
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

  async updateGroupAvatar(file: Express.Multer.File, groupId: string, userId: string): Promise<{ success: boolean; message: string; avatar_url: string }> {
    try {
      const { data: currentGroup, error: getGroupError } = await this.supabaseService.getClient()
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
      const avatarUrl = await this.uploadGroupAvatar(file, groupId, userId);
      const { error: updateError } = await this.supabaseService.getClient()
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



  private async addInitialMembers(groupId: string, memberIds: string[]): Promise<void> {
    try {
      const membersToAdd = memberIds.map(memberId => ({
        group_id: groupId,
        user_id: memberId,
        role: 'member' as const,
      }));

      const { error } = await this.supabaseService.getClient()
        .from('group_members')
        .insert(membersToAdd);

      if (error) {
        this.logger.warn(`Some members could not be added to group ${groupId}: ${error.message}`);
      }
    } catch (error) {
      this.logger.warn('Error adding initial members', error);
    }
  }

  private async getGroupMembers(groupId: string): Promise<GroupMember[]> {
    try {
      const { data: members, error } = await this.supabaseService.getClient()
        .from('group_members')
        .select('*')
        .eq('group_id', groupId)
        .order('joined_at', { ascending: true });

      if (error) {
        this.logger.error(`Failed to fetch members for group ${groupId}`, error.message);
        throw new BadRequestException('Unable to fetch group members');
      }

      if (!members || members.length === 0) {
        return [];
      }

      const userIds = members.map(member => member.user_id);
      const adminClient = this.supabaseService.getAdminClient();
      const users: any[] = [];

      for (const userId of userIds) {
        try {
          const { data: user, error } = await adminClient.auth.admin.getUserById(userId);
          if (user && !error) {
            users.push({
              id: user.user.id,
              name: user.user.user_metadata?.name || null,
              avatar_url: user.user.user_metadata?.avatar_url || null,
            });
          }
        } catch (error) {
          this.logger.warn(`Failed to fetch user data for ${userId}`, error);
        }
      }

      const usersMap = new Map(users.map(user => [user.id, user]));

      return members.map((member: any) => {
        const userData = usersMap.get(member.user_id);
        return {
          id: member.id,
          group_id: member.group_id,
          user_id: member.user_id,
          joined_at: member.joined_at,
          role: member.role,
          name: userData?.name || null,
          avatar_url: userData?.avatar_url || null,
        };
      });

    } catch (error) {
      if (error instanceof BadRequestException) {
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

  private async isUserAdmin(groupId: string, userId: string): Promise<boolean> {
    try {
      const { data: member } = await this.supabaseService.getClient()
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

  private async isUserMember(groupId: string, userId: string): Promise<boolean> {
    try {
      const { data: member } = await this.supabaseService.getClient()
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

  private sanitizeString(input: string): string {
    if (!input) return '';
    const cleaned = DOMPurify.sanitize(input, {
      ALLOWED_TAGS: [],
      ALLOWED_ATTR: []
    });
    return cleaned.trim();
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