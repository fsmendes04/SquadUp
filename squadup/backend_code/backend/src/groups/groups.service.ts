import { Injectable, NotFoundException, BadRequestException, ForbiddenException } from '@nestjs/common';
import { SupabaseService } from '../supabase/supabase.service';
import { CreateGroupDto } from './dto/create-group.dto';
import { UpdateGroupDto } from './dto/update-group.dto';
import { Group, GroupMember, GroupWithMembers } from './models/group.model';

@Injectable()
export class GroupsService {
  constructor(private readonly supabaseService: SupabaseService) { }

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
          created_by
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
        const group = userGroup.groups as Group;
        const members = await this.getGroupMembers(group.id);
        groupsWithMembers.push({
          ...group,
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
    const { data: members, error } = await this.supabaseService.client
      .from('group_members')
      .select('*')
      .eq('group_id', groupId)
      .order('joined_at', { ascending: true });

    if (error) {
      throw new BadRequestException(`Erro ao buscar membros do grupo: ${error.message}`);
    }

    return members || [];
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