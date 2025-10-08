import { Injectable, NotFoundException, BadRequestException, ForbiddenException } from '@nestjs/common';
import { createClient } from '@supabase/supabase-js';
import { SupabaseService } from '../supabase/supabaseService';
import { CreateGroupDto } from './dto/create-group.dto';
import { UpdateGroupDto } from './dto/update-group.dto';
import { Group, GroupMember, GroupWithMembers } from './models/group.model';

@Injectable()
export class GroupsService {
  constructor(private readonly supabaseService: SupabaseService) { }

  async uploadGroupAvatar(file: Express.Multer.File, groupId: string, accessToken: string): Promise<string> {
    try {
      console.log('🚀 Starting group avatar upload for group:', groupId);

      // Criar cliente Supabase com JWT token do usuário para respeitar RLS
      const { createClient } = require('@supabase/supabase-js');
      const userSupabase = createClient(
        process.env.SUPABASE_URL,
        process.env.SUPABASE_KEY, // Esta é a anon key
        {
          global: {
            headers: {
              Authorization: `Bearer ${accessToken}`,
            },
          },
        }
      );

      // Criar nome único para o arquivo
      const fileExtension = file.originalname.split('.').pop() || 'jpg';
      const fileName = `group_avatar_${Date.now()}.${fileExtension}`;
      const filePath = `${groupId}/${fileName}`; // Organizar por groupId

      console.log('📁 Upload path:', filePath);

      // Upload para o Supabase Storage usando cliente com JWT token
      const { data, error } = await userSupabase.storage
        .from('group-avatars')
        .upload(filePath, file.buffer, {
          contentType: file.mimetype,
          upsert: true
        });

      if (error) {
        console.error('❌ Error uploading group avatar:', error);
        throw new BadRequestException(`Error uploading group avatar: ${error.message}`);
      }

      console.log('📤 Upload successful, data:', data);

      // Obter URL pública da imagem usando o cliente regular (não precisa de auth para URLs públicas)
      const { data: publicUrlData } = this.supabaseService.client.storage
        .from('group-avatars')
        .getPublicUrl(filePath);

      console.log('✅ Group avatar uploaded successfully:', publicUrlData.publicUrl);
      return publicUrlData.publicUrl;
    } catch (error) {
      console.error('❌ Unexpected error uploading group avatar:', error);
      throw new BadRequestException(`Unexpected error uploading group avatar: ${error}`);
    }
  }

  async updateGroupAvatar(file: Express.Multer.File, groupId: string, userId: string, accessToken: string) {
    try {
      console.log('🔄 Starting updateGroupAvatar for groupId:', groupId, 'by user:', userId);

      // Verificar se o usuário é admin do grupo
      const isAdmin = await this.isUserAdmin(groupId, userId);
      if (!isAdmin) {
        throw new ForbiddenException('Apenas administradores podem alterar o avatar do grupo');
      }

      // Get current group data to check for existing avatar
      const { data: currentGroup, error: getGroupError } = await this.supabaseService.client
        .from('groups')
        .select('avatar_url')
        .eq('id', groupId)
        .single();

      if (getGroupError) {
        console.error('❌ Error getting current group:', getGroupError);
      } else if (currentGroup?.avatar_url) {
        // Extract the file path from the current avatar URL to delete it
        console.log('🗑️ Found existing avatar, will delete:', currentGroup.avatar_url);

        try {
          // Criar cliente Supabase com JWT token para deletar o arquivo antigo
          const { createClient } = require('@supabase/supabase-js');
          const userSupabase = createClient(
            process.env.SUPABASE_URL,
            process.env.SUPABASE_KEY,
            {
              global: {
                headers: {
                  Authorization: `Bearer ${accessToken}`,
                },
              },
            }
          );

          const urlParts = currentGroup.avatar_url.split('/');
          const fileName = urlParts[urlParts.length - 1];
          const oldFilePath = `${groupId}/${fileName}`;

          // Delete the old avatar file from storage using JWT token
          const { error: deleteError } = await userSupabase.storage
            .from('group-avatars')
            .remove([oldFilePath]);

          if (deleteError) {
            console.error('⚠️ Warning: Could not delete old group avatar file:', deleteError);
            // Continue with upload even if deletion fails
          } else {
            console.log('✅ Old group avatar file deleted successfully:', oldFilePath);
          }
        } catch (deleteErr) {
          console.error('⚠️ Warning: Error processing old group avatar deletion:', deleteErr);
          // Continue with upload even if deletion fails
        }
      }

      // Upload the new avatar
      const avatarUrl = await this.uploadGroupAvatar(file, groupId, accessToken);

      // Update the group's avatar_url in the database
      const { error: updateError } = await this.supabaseService.client
        .from('groups')
        .update({
          avatar_url: avatarUrl,
          updated_at: new Date().toISOString()
        })
        .eq('id', groupId);

      if (updateError) {
        console.error('❌ Error updating group avatar_url:', updateError);
        throw new BadRequestException(`Error updating group avatar: ${updateError.message}`);
      }

      console.log('✅ Group avatar updated successfully in database');

      return {
        success: true,
        message: 'Group avatar updated successfully',
        avatar_url: avatarUrl,
      };

    } catch (error) {
      console.error('❌ Error in updateGroupAvatar:', error);
      if (error instanceof ForbiddenException || error instanceof BadRequestException) {
        throw error;
      }
      throw new BadRequestException(`Unexpected error updating group avatar: ${error.message || error}`);
    }
  }

  async createGroup(createGroupDto: CreateGroupDto, userId: string): Promise<Group> {
    const { name, memberIds = [] } = createGroupDto;

    const { data: group, error: groupError } = await this.supabaseService.client
      .from('groups')
      .insert({
        name,
        created_by: userId,
      })
      .select()
      .single();

    if (groupError) {
      throw new BadRequestException(`Erro ao criar grupo: ${groupError.message}`);
    }

    // Adicionar o criador como admin do grupo
    const { error: memberError } = await this.supabaseService.client
      .from('group_members')
      .insert({
        group_id: group.id,
        user_id: userId,
        role: 'admin',
      });

    if (memberError) {
      // Se falhar ao adicionar o criador, deletar o grupo criado
      await this.supabaseService.client
        .from('groups')
        .delete()
        .eq('id', group.id);

      throw new BadRequestException(`Erro ao adicionar criador ao grupo: ${memberError.message}`);
    }

    // Adicionar membros adicionais se fornecidos
    if (memberIds.length > 0) {
      const membersToAdd = memberIds.map(memberId => ({
        group_id: group.id,
        user_id: memberId,
        role: 'member' as const,
      }));

      const { error: additionalMembersError } = await this.supabaseService.client
        .from('group_members')
        .insert(membersToAdd);

      if (additionalMembersError) {
        console.warn(`Aviso: Alguns membros não puderam ser adicionados: ${additionalMembersError.message}`);
      }
    }

    return group;
  }

  async findAllGroups(): Promise<Group[]> {
    const { data: groups, error } = await this.supabaseService.client
      .from('groups')
      .select('*')
      .order('created_at', { ascending: false });

    if (error) {
      throw new BadRequestException(`Erro ao buscar grupos: ${error.message}`);
    }

    return groups || [];
  }

  async findUserGroups(userId: string): Promise<GroupWithMembers[]> {
    const { data: userGroups, error } = await this.supabaseService.client
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
      throw new BadRequestException(`Erro ao buscar grupos do usuário: ${error.message}`);
    }

    if (!userGroups || userGroups.length === 0) {
      return [];
    }

    // Buscar membros para cada grupo
    const groupsWithMembers: GroupWithMembers[] = [];

    for (const userGroup of userGroups) {
      if (userGroup.groups) {
        const group = userGroup.groups as Group & { avatar_url?: string };
        const members = await this.getGroupMembers(group.id);
        groupsWithMembers.push({
          ...group,
          avatar_url: group.avatar_url || null,
          members,
        });
      }
    }

    return groupsWithMembers;
  }

  async findOne(id: string): Promise<GroupWithMembers> {
    const { data: group, error: groupError } = await this.supabaseService.client
      .from('groups')
      .select('*')
      .eq('id', id)
      .single();

    if (groupError || !group) {
      throw new NotFoundException(`Grupo com ID ${id} não encontrado`);
    }

    const members = await this.getGroupMembers(id);

    return {
      ...group,
      members,
    };
  }

  async updateGroup(id: string, updateGroupDto: UpdateGroupDto, userId: string): Promise<Group> {
    // Verificar se o usuário é admin do grupo
    const isAdmin = await this.isUserAdmin(id, userId);
    if (!isAdmin) {
      throw new ForbiddenException('Apenas administradores podem atualizar o grupo');
    }

    const { name } = updateGroupDto;
    const { data: group, error } = await this.supabaseService.client
      .from('groups')
      .update({
        name,
        updated_at: new Date().toISOString(),
      })
      .eq('id', id)
      .select()
      .single();

    if (error || !group) {
      throw new BadRequestException(`Erro ao atualizar grupo: ${error?.message}`);
    }

    return group;
  }

  async deleteGroup(id: string, userId: string): Promise<void> {
    // Verificar se o usuário é admin do grupo
    const isAdmin = await this.isUserAdmin(id, userId);
    if (!isAdmin) {
      throw new ForbiddenException('Apenas administradores podem deletar o grupo');
    }

    // Deletar membros do grupo primeiro (devido à foreign key)
    const { error: membersError } = await this.supabaseService.client
      .from('group_members')
      .delete()
      .eq('group_id', id);

    if (membersError) {
      throw new BadRequestException(`Erro ao deletar membros do grupo: ${membersError.message}`);
    }

    // Deletar o grupo
    const { error: groupError } = await this.supabaseService.client
      .from('groups')
      .delete()
      .eq('id', id);

    if (groupError) {
      throw new BadRequestException(`Erro ao deletar grupo: ${groupError.message}`);
    }
  }

  async addMember(groupId: string, userId: string, requesterId: string): Promise<GroupMember> {
    // Verificar se o solicitante é admin do grupo
    const isAdmin = await this.isUserAdmin(groupId, requesterId);
    if (!isAdmin) {
      throw new ForbiddenException('Apenas administradores podem adicionar membros');
    }

    // Verificar se o usuário já é membro do grupo
    const { data: existingMember } = await this.supabaseService.client
      .from('group_members')
      .select('id')
      .eq('group_id', groupId)
      .eq('user_id', userId)
      .single();

    if (existingMember) {
      throw new BadRequestException('Usuário já é membro do grupo');
    }

    const { data: member, error } = await this.supabaseService.client
      .from('group_members')
      .insert({
        group_id: groupId,
        user_id: userId,
        role: 'member',
      })
      .select()
      .single();

    if (error || !member) {
      throw new BadRequestException(`Erro ao adicionar membro: ${error?.message}`);
    }

    return member;
  }

  async removeMember(groupId: string, userId: string, requesterId: string): Promise<void> {
    // Verificar se o solicitante é admin do grupo ou se está removendo a si mesmo
    const isAdmin = await this.isUserAdmin(groupId, requesterId);
    const isSelfRemoval = userId === requesterId;

    if (!isAdmin && !isSelfRemoval) {
      throw new ForbiddenException('Apenas administradores podem remover outros membros');
    }

    // Não permitir que o criador do grupo se remova
    if (isSelfRemoval) {
      const { data: group } = await this.supabaseService.client
        .from('groups')
        .select('created_by')
        .eq('id', groupId)
        .single();

      if (group && group.created_by === userId) {
        throw new ForbiddenException('O criador do grupo não pode se remover. Delete o grupo se necessário.');
      }
    }

    const { error } = await this.supabaseService.client
      .from('group_members')
      .delete()
      .eq('group_id', groupId)
      .eq('user_id', userId);

    if (error) {
      throw new BadRequestException(`Erro ao remover membro: ${error.message}`);
    }
  }

  private async getGroupMembers(groupId: string): Promise<GroupMember[]> {
    // Primeiro, buscar os membros do grupo
    const { data: members, error } = await this.supabaseService.client
      .from('group_members')
      .select('*')
      .eq('group_id', groupId)
      .order('joined_at', { ascending: true });

    if (error) {
      throw new BadRequestException(`Erro ao buscar membros do grupo: ${error.message}`);
    }

    if (!members || members.length === 0) {
      return [];
    }

    // Buscar os dados dos usuários para cada membro usando Service Role
    const userIds = members.map(member => member.user_id);
    console.log('Buscando dados dos usuários para IDs:', userIds);

    // Criar cliente admin usando service role key
    const adminClient = createClient(
      process.env.SUPABASE_URL!,
      process.env.SUPABASE_SERVICE_ROLE_KEY!,
      {
        auth: {
          autoRefreshToken: false,
          persistSession: false
        }
      }
    );

    // Buscar dados dos usuários usando Admin API
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
        } else {
          console.warn(`Erro ao buscar usuário ${userId}:`, error?.message);
        }
      } catch (error) {
        console.warn(`Erro ao buscar usuário ${userId}:`, error);
      }
    }

    console.log('Dados dos usuários retornados:', users);

    // Criar um mapa de usuários por ID para facilitar a busca
    const usersMap = new Map();
    if (users) {
      users.forEach(user => {
        usersMap.set(user.id, { name: user.name, avatar_url: user.avatar_url });
      });
    }

    // Mapear para incluir name e avatar_url no objeto GroupMember
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
  }

  private async isUserAdmin(groupId: string, userId: string): Promise<boolean> {
    const { data: member } = await this.supabaseService.client
      .from('group_members')
      .select('role')
      .eq('group_id', groupId)
      .eq('user_id', userId)
      .single();

    return member?.role === 'admin';
  }
}