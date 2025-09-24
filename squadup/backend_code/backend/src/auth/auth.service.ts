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
      throw new UnauthorizedException('Invalid token');
    }

    return user;
  }
}