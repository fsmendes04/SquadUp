import { Injectable, BadRequestException, UnauthorizedException } from '@nestjs/common';
import { SupabaseService } from '../supabase/supabase.service';
import { UpdateProfileDto } from './dto/update-profile.dto';

@Injectable()
export class AuthService {
  constructor(public readonly supabase: SupabaseService) { }

  async register(email: string, password: string) {
    console.log('🚀 Trying to register user:', email);

    const { data, error } = await this.supabase.client.auth.signUp({
      email,
      password,
      options: {
        data: {
          name: null,
          avatar_url: null, // Avatar inicialmente null
        },
      },
    });

    if (error) {
      console.error('❌ Error registering user:', error);
      throw new BadRequestException(`Error registering user: ${error.message}`);
    }

    console.log('✅ User registered successfully:', {
      user: data.user,
      session: data.session
    });

    return data;
  }

  async updateProfile(updateData: UpdateProfileDto) {
    try {
      const updatePayload: any = {};

      // Adicionar name se fornecido
      if (updateData.name !== undefined) {
        updatePayload.name = updateData.name;
      }

      // Adicionar avatar_url se fornecido
      if (updateData.avatar_url !== undefined) {
        updatePayload.avatar_url = updateData.avatar_url;
      }

      const { data, error } = await this.supabase.client.auth.updateUser({
        data: updatePayload,
      });

      if (error) {
        console.error('❌ Error updating profile:', error);
        throw new BadRequestException(`Error updating profile: ${error.message}`);
      }

      console.log('✅ Profile updated successfully:', data.user);
      return data.user;
    } catch (error) {
      console.error('❌ Unexpected error updating profile:', error);
      throw new BadRequestException(`Unexpected error updating profile: ${error}`);
    }
  }



  async login(email: string, password: string) {
    const { data, error } = await this.supabase.client.auth.signInWithPassword({
      email,
      password,
    });

    if (error) {
      throw new UnauthorizedException(`Error logging in: ${error.message}`);
    }

    return data;
  }

  async getUserFromToken(token: string) {
    const { data: { user }, error } = await this.supabase.client.auth.getUser(token);

    if (error || !user) {
      console.error('❌ Error getting user from token:', error);
      throw new UnauthorizedException('Invalid token');
    }

    console.log('👤 User from token:', {
      id: user.id,
      email: user.email,
      user_metadata: user.user_metadata
    });

    return user;
  }

  async uploadAvatar(file: Express.Multer.File, userId: string): Promise<string> {
    try {
      console.log('🚀 Starting avatar upload for user:', userId);

      // Criar nome único para o arquivo
      const fileExtension = file.originalname.split('.').pop() || 'jpg';
      const fileName = `avatar_${Date.now()}.${fileExtension}`;
      const filePath = `${userId}/${fileName}`; // Organizar por userId

      console.log('📁 Upload path:', filePath);

      // Upload para o Supabase Storage
      const { data, error } = await this.supabase.client.storage
        .from('user-uploads')
        .upload(filePath, file.buffer, {
          contentType: file.mimetype,
          upsert: true
        });

      if (error) {
        console.error('❌ Error uploading avatar:', error);
        throw new BadRequestException(`Error uploading avatar: ${error.message}`);
      }

      console.log('📤 Upload successful, data:', data);

      // Obter URL pública da imagem
      const { data: publicUrlData } = this.supabase.client.storage
        .from('user-uploads')
        .getPublicUrl(filePath);

      console.log('✅ Avatar uploaded successfully:', publicUrlData.publicUrl);
      return publicUrlData.publicUrl;
    } catch (error) {
      console.error('❌ Unexpected error uploading avatar:', error);
      throw new BadRequestException(`Unexpected error uploading avatar: ${error}`);
    }
  }

  async updateAvatar(file: Express.Multer.File, userId: string, accessToken: string) {
    try {
      console.log('🔄 Starting updateAvatar for userId:', userId);

      // Upload da nova imagem
      const avatarUrl = await this.uploadAvatar(file, userId);

      // Use service role to update user metadata directly
      const { createClient } = require('@supabase/supabase-js');
      const adminSupabase = createClient(
        process.env.SUPABASE_URL,
        process.env.SUPABASE_SERVICE_ROLE_KEY
      );

      // Atualizar o perfil do usuário com a nova URL do avatar usando service role
      const { data, error } = await adminSupabase.auth.admin.updateUserById(userId, {
        user_metadata: {
          avatar_url: avatarUrl,
        },
      });

      if (error) {
        console.error('❌ Error updating user avatar:', error);
        throw new BadRequestException(`Error updating user avatar: ${error.message}`);
      }

      console.log('✅ User avatar updated successfully:', data.user);
      return data.user;
    } catch (error) {
      console.error('❌ Unexpected error updating avatar:', error);
      throw new BadRequestException(`Unexpected error updating avatar: ${error}`);
    }
  }
}