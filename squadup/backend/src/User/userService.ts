import { Injectable, BadRequestException, UnauthorizedException } from '@nestjs/common';
import { SupabaseService } from '../supabase/supabaseService';
import { UpdateProfileDto } from './dto/update-profile.dto';

@Injectable()
export class UserService {
  constructor(public readonly supabase: SupabaseService) { }

  async register(email: string, password: string) {
    const { data, error } = await this.supabase.client.auth.signUp({
      email,
      password,
      options: {
        data: {
          name: null,
          avatar_url: null,
        },
      },
    });

    if (error) {
      throw new BadRequestException(`Error registering user: ${error.message}`);
    }

    return data;
  }

  async updateProfile(updateData: UpdateProfileDto, userId: string, avatarFile?: Express.Multer.File) {
    try {
      const updatePayload: any = {};

      if (updateData.name !== undefined) {
        updatePayload.name = updateData.name;
      }

      if (updateData.avatar_url !== undefined) {
        updatePayload.avatar_url = updateData.avatar_url;
      }

      if (avatarFile) {
        const { createClient } = require('@supabase/supabase-js');
        const adminSupabase = createClient(
          process.env.SUPABASE_URL,
          process.env.SUPABASE_SERVICE_ROLE_KEY
        );

        const { data: currentUser, error: getUserError } = await adminSupabase.auth.admin.getUserById(userId);

        if (!getUserError && currentUser?.user?.user_metadata?.avatar_url) {
          const currentAvatarUrl = currentUser.user.user_metadata.avatar_url;

          try {
            const urlParts = currentAvatarUrl.split('/');
            const fileName = urlParts[urlParts.length - 1];
            const oldFilePath = `${userId}/${fileName}`;

            await this.supabase.client.storage
              .from('user-uploads')
              .remove([oldFilePath]);

          } catch (deleteErr) {
            console.error('⚠️ Warning: Error processing old avatar deletion:', deleteErr);
          }
        }

        const avatarUrl = await this.uploadAvatar(avatarFile, userId);
        updatePayload.avatar_url = avatarUrl;
      }

      if (Object.keys(updatePayload).length === 0) {
        throw new BadRequestException('No fields to update');
      }

      const { createClient } = require('@supabase/supabase-js');
      const adminSupabase = createClient(
        process.env.SUPABASE_URL,
        process.env.SUPABASE_SERVICE_ROLE_KEY
      );

      const { data, error } = await adminSupabase.auth.admin.updateUserById(userId, {
        user_metadata: updatePayload,
      });

      if (error) {
        throw new BadRequestException(`Error updating profile: ${error.message}`);
      }

      return data.user;
    } catch (error) {
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

  async getUserById(userId: string) {
    try {

      const { createClient } = require('@supabase/supabase-js');
      const adminSupabase = createClient(
        process.env.SUPABASE_URL,
        process.env.SUPABASE_SERVICE_ROLE_KEY
      );

      const { data, error } = await adminSupabase.auth.admin.getUserById(userId);

      if (error || !data.user) {
        throw new BadRequestException('User not found');
      }

      return data.user;
    } catch (error) {
      throw new BadRequestException(`Error getting user: ${error}`);
    }
  }

  async getUserFromToken(token: string) {
    const { data: { user }, error } = await this.supabase.client.auth.getUser(token);

    if (error || !user) {
      throw new UnauthorizedException('Invalid token');
    }

    return user;
  }

  async uploadAvatar(file: Express.Multer.File, userId: string): Promise<string> {
    try {
      const fileExtension = file.originalname.split('.').pop() || 'jpg';
      const fileName = `avatar_${Date.now()}.${fileExtension}`;
      const filePath = `${userId}/${fileName}`; // Organizar por userId

      const { data, error } = await this.supabase.client.storage
        .from('user-uploads')
        .upload(filePath, file.buffer, {
          contentType: file.mimetype,
          upsert: true
        });

      if (error) {
        throw new BadRequestException(`Error uploading avatar: ${error.message}`);
      }

      const { data: publicUrlData } = this.supabase.client.storage
        .from('user-uploads')
        .getPublicUrl(filePath);

      return publicUrlData.publicUrl;
    } catch (error) {
      throw new BadRequestException(`Unexpected error uploading avatar: ${error}`);
    }
  }
}