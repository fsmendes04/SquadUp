import {
  Injectable,
  BadRequestException,
  UnauthorizedException,
  ForbiddenException,
  Logger
} from '@nestjs/common';
import { SupabaseService } from '../Supabase/supabaseService';
import { SessionService } from './sessionService';
import { UpdateProfileDto } from './dto/update-profile.dto';
import xss from 'xss';

@Injectable()
export class UserService {

  private readonly logger = new Logger(UserService.name);
  private readonly MAX_NAME_LENGTH = 100;
  private readonly ALLOWED_IMAGE_TYPES = ['image/jpeg', 'image/jpg', 'image/png', 'image/webp'];
  private readonly MAX_FILE_SIZE = 5 * 1024 * 1024;

  constructor(
    public readonly supabase: SupabaseService,
    private readonly sessionService: SessionService
  ) { }

  async getUserByEmail(email: string) {
    try {
      const adminClient = this.supabase.getAdminClient();
      const { data: profile, error } = await adminClient
        .from('profiles')
        .select('*')
        .ilike('email', email.trim().toLowerCase())
        .maybeSingle();

      if (error) {
        this.logger.error('Erro ao buscar perfil por email', error.message);
        throw new BadRequestException('Erro ao buscar usuário por email');
      }
      if (!profile) {
        throw new BadRequestException('Usuário não encontrado com este email');
      }
      return this.sanitizeUserData(profile);
    } catch (error) {
      if (error instanceof BadRequestException) {
        throw error;
      }
      this.logger.error('Erro inesperado ao buscar usuário por email', error);
      throw new BadRequestException('Erro ao buscar usuário por email');
    }
  }

  async changePassword(userId: string, currentPassword: string, newPassword: string): Promise<any> {
    const user = await this.getUserById(userId);

    const { error: signInError } = await this.supabase.getClient().auth.signInWithPassword({
      email: user.email,
      password: currentPassword,
    });
    if (signInError) {
      throw new BadRequestException('Current password is incorrect');
    }

    if (!this.isStrongPassword(newPassword)) {
      throw new BadRequestException(
        'Password must be at least 8 characters and contain uppercase, lowercase, number and special character'
      );
    }
    if (currentPassword === newPassword) {
      throw new BadRequestException('New password must be different from the current password');
    }

    const { error } = await this.supabase.getClient().auth.updateUser({
      password: newPassword,
    });
    if (error) {
      throw new BadRequestException('Failed to update password');
    }

    this.logger.log(`Password changed for user: ${userId}`);
    return { success: true, message: 'Password updated successfully' };
  }

  async getProfile(accessToken: string) {
    try {
      if (!accessToken) {
        throw new UnauthorizedException('Access token is required');
      }

      const userClient = this.supabase.getClientWithToken(accessToken);

      const user = await this.getUserFromToken(accessToken);

      const { data: profileData, error: profileError } = await userClient
        .from('profiles')
        .select('*')
        .eq('id', user.id)
        .maybeSingle();

      if (profileError) {
        this.logger.warn(`Failed to fetch profile for user ${user.id}`, profileError.message);
      }

      const combinedData = {
        id: user.id,
        email: user.email,
        user_metadata: user.user_metadata,
        created_at: user.created_at,
        updated_at: user.updated_at,
        ...profileData,
      };

      this.logger.log(`Profile retrieved for user: ${user.id}`);
      return this.sanitizeUserData(combinedData);

    } catch (error) {
      if (error instanceof UnauthorizedException) {
        throw error;
      }
      this.logger.error('Error fetching user profile', error);
      throw new BadRequestException('Unable to fetch user profile');
    }
  }


  async register(email: string, password: string) {
    try {
      if (!this.isValidEmail(email)) {
        throw new BadRequestException('Invalid email format');
      }

      if (!this.isStrongPassword(password)) {
        throw new BadRequestException(
          'Password must be at least 8 characters and contain uppercase, lowercase, number and special character'
        );
      }

      try {
        await this.getUserByEmail(email);
        throw new BadRequestException('Account already exists with this email');
      } catch (err) {
        if (!(err instanceof BadRequestException && err.message === 'Usuário não encontrado com este email')) {
          throw err;
        }
      }

      const { data, error } = await this.supabase.getClient().auth.signUp({
        email: email.toLowerCase().trim(),
        password,
        options: {
          data: {
            name: null,
            avatar_url: null,
          },
        },
      });

      if (error) {
        this.logger.error(`Registration failed for email: ${email}`, error.message);
        throw new BadRequestException('Unable to register user. Please try again.');
      }

      this.logger.log(`User registered successfully: ${email}`);
      return data;
    } catch (error) {
      if (error instanceof BadRequestException) {
        throw error;
      }
      this.logger.error('Unexpected registration error', error);
      throw new BadRequestException('Registration failed');
    }
  }

  async updateProfile(
    updateData: UpdateProfileDto,
    userId: string,
    avatarFile?: Express.Multer.File,
    accessToken?: string
  ) {
    try {
      this.logger.log(`Token recebido para updateProfile: ${accessToken}`);
      const updatePayload: Record<string, any> = {};

      // --- Validação e sanitização do nome ---
      if (updateData.name !== undefined) {
        const sanitizedName = this.sanitizeString(updateData.name);

        if (sanitizedName.length > this.MAX_NAME_LENGTH) {
          throw new BadRequestException(`Name cannot exceed ${this.MAX_NAME_LENGTH} characters`);
        }

        updatePayload.name = sanitizedName || null;
      }

      // --- Validação do avatar URL ---
      if (updateData.avatar_url !== undefined && !avatarFile) {
        if (!this.isValidAvatarUrl(updateData.avatar_url, userId)) {
          throw new BadRequestException('Invalid avatar URL');
        }
        updatePayload.avatar_url = updateData.avatar_url;
      }

      // --- Upload de ficheiro de avatar ---
      if (avatarFile) {
        this.validateAvatarFile(avatarFile);
        await this.handleAvatarUpdate(userId, avatarFile, updatePayload, accessToken);
      }

      // --- Nenhum campo válido para atualizar ---
      if (Object.keys(updatePayload).length === 0) {
        throw new BadRequestException('No valid fields to update');
      }

      // --- Atualização através do Supabase (RLS) ---
      let userClient;
      if (accessToken) {
        try {
          try {
            const tokenUser = await this.supabase.verifyToken(accessToken);
            if (tokenUser.id !== userId) {
              this.logger.warn(`Token user (${tokenUser.id}) does not match target user (${userId})`);
            }
          } catch (verifyErr) {
            this.logger.warn('Could not verify access token for RLS update', verifyErr as Error);
          }

          userClient = this.supabase.getClientWithToken(accessToken);
          const profileUpdate: Record<string, any> = {};

          if ('name' in updatePayload) {
            profileUpdate.name = updatePayload.name ?? null;
          }
          if ('avatar_url' in updatePayload) {
            profileUpdate.avatar_url = updatePayload.avatar_url ?? null;
          }

          if (Object.keys(profileUpdate).length > 0) {
            profileUpdate.updated_at = new Date().toISOString();

            // Verifica se o perfil já existe
            const { data: existingRow, error: selectErr } = await userClient
              .from('profiles')
              .select('id')
              .eq('id', userId)
              .maybeSingle();

            if (selectErr) {
              this.logger.warn('profiles existence check failed', selectErr.message);
            }

            // Se não existir, cria o perfil
            if (!existingRow) {
              const { error: insertErr } = await userClient
                .from('profiles')
                .insert({ id: userId })
                .single();
              if (insertErr) {
                this.logger.warn('profiles insert via RLS failed', insertErr.message);
              }
            }

            // Atualiza o perfil
            const { error: profileError } = await userClient
              .from('profiles')
              .update(profileUpdate)
              .eq('id', userId);

            if (profileError) {
              this.logger.warn('Profiles table update via RLS failed', {
                code: (profileError as any).code,
                message: profileError.message,
                details: (profileError as any).details,
                hint: (profileError as any).hint,
              });
            }
          }
        } catch (profilesErr) {
          this.logger.warn('Unexpected error updating profiles table via RLS', profilesErr as Error);
        }
      }

      // --- Busca e retorna o perfil atualizado ---
      if (!userClient && accessToken) {
        userClient = this.supabase.getClientWithToken(accessToken);
      }
      if (userClient) {
        const { data: updatedUser, error: fetchErr } = await userClient
          .from('profiles')
          .select('*')
          .eq('id', userId)
          .single();

        if (fetchErr) {
          this.logger.warn('Failed to fetch updated user profile', fetchErr.message);
          throw new BadRequestException('Could not retrieve updated profile');
        }

        this.logger.log(`Profiles updated successfully for user: ${userId}`);
        // Este retorno devolve o objeto da tabela 'profiles' (com o nome)
        return this.sanitizeUserData(updatedUser);
      }
    } catch (error) {
      if (error instanceof BadRequestException || error instanceof ForbiddenException) {
        throw error;
      }
      this.logger.error('Unexpected profile update error', error);
      throw new BadRequestException('Profile update failed');
    }
  }


  async login(email: string, password: string) {
    try {
      if (!email || !password) {
        throw new UnauthorizedException('Email and password are required');
      }

      const { data, error } = await this.supabase.getClient().auth.signInWithPassword({
        email: email.toLowerCase().trim(),
        password,
      });

      if (error) {
        this.logger.warn(`Failed login attempt for email: ${email}`);
        throw new UnauthorizedException('Invalid credentials');
      }

      this.logger.log(`Successful login for user: ${data.user.id}`);
      return data;
    } catch (error) {
      if (error instanceof UnauthorizedException) {
        throw error;
      }
      this.logger.error('Unexpected login error', error);
      throw new UnauthorizedException('Login failed');
    }
  }

  async logout(token: string) {
    if (!token) {
      throw new BadRequestException('Token is required for logout');
    }
    return this.sessionService.revokeSession(token);
  }

  async getUserById(userId: string) {
    try {
      const adminClient = this.supabase.getAdminClient();
      const { data, error } = await adminClient.auth.admin.getUserById(userId);

      if (error || !data.user) {
        throw new BadRequestException('User not found');
      }

      return this.sanitizeUserData(data.user);
    } catch (error) {
      if (error instanceof BadRequestException) {
        throw error;
      }
      this.logger.error('Error fetching user', error);
      throw new BadRequestException('Unable to fetch user data');
    }
  }

  async getUserFromToken(token: string) {
    try {
      const { data: { user }, error } = await this.supabase.getClient().auth.getUser(token);

      if (error || !user) {
        throw new UnauthorizedException('Invalid or expired token');
      }

      if (user.aud !== 'authenticated') {
        throw new UnauthorizedException('Invalid token audience');
      }

      return user;
    } catch (error) {
      this.logger.warn('Token validation failed', error.message);
      throw new UnauthorizedException('Authentication failed');
    }
  }

  async uploadAvatar(file: Express.Multer.File, userId: string, accessToken?: string): Promise<string> {
    try {
      const fileExtension = file.originalname.split('.').pop()?.toLowerCase() || 'jpg';

      const allowedExtensions = ['jpg', 'jpeg', 'png', 'webp'];
      if (!allowedExtensions.includes(fileExtension)) {
        throw new BadRequestException('Invalid file type. Allowed: JPG, PNG, WEBP');
      }

      const timestamp = Date.now();
      const randomStr = Math.random().toString(36).substring(2, 15);
      const fileName = `avatar_${timestamp}_${randomStr}.${fileExtension}`;
      const filePath = `${userId}/${fileName}`;

      const storageClient = accessToken 
        ? this.supabase.getClientWithToken(accessToken)
        : this.supabase.getClient();

      const { error } = await storageClient.storage
        .from('avatars')
        .upload(filePath, file.buffer, {
          contentType: file.mimetype,
          upsert: false,
          cacheControl: '3600'
        });

      if (error) {
        this.logger.error(`Avatar upload failed for user: ${userId}`, error.message);
        throw new BadRequestException('Failed to upload avatar');
      }

      const { data: publicUrlData } = storageClient.storage
        .from('avatars')
        .getPublicUrl(filePath);

      return publicUrlData.publicUrl;
    } catch (error) {
      if (error instanceof BadRequestException) {
        throw error;
      }
      this.logger.error('Unexpected avatar upload error', error);
      throw new BadRequestException('Avatar upload failed');
    }
  }

  private async handleAvatarUpdate(
    userId: string,
    avatarFile: Express.Multer.File,
    updatePayload: any,
    accessToken?: string
  ): Promise<void> {
    try {
      // Buscar o avatar atual da tabela profiles
      const profileClient = accessToken 
        ? this.supabase.getClientWithToken(accessToken)
        : this.supabase.getAdminClient();
      
      const { data: profileData, error: profileError } = await profileClient
        .from('profiles')
        .select('avatar_url')
        .eq('id', userId)
        .maybeSingle();

      // Se existe um avatar antigo, removê-lo do storage
      if (!profileError && profileData?.avatar_url) {
        const currentAvatarUrl = profileData.avatar_url;

        try {
          const urlObj = new URL(currentAvatarUrl);
          const pathParts = urlObj.pathname.split('/');
          const fileName = pathParts[pathParts.length - 1];
          const userIdFromPath = pathParts[pathParts.length - 2];

          if (userIdFromPath === userId) {
            const oldFilePath = `${userId}/${fileName}`;
            const storageClient = accessToken 
              ? this.supabase.getClientWithToken(accessToken)
              : this.supabase.getClient();
            await storageClient.storage
              .from('avatars')
              .remove([oldFilePath]);
            this.logger.log(`Old avatar removed: ${oldFilePath}`);
          }
        } catch (deleteErr) {
          this.logger.warn('Could not delete old avatar', deleteErr);
        }
      }

      const avatarUrl = await this.uploadAvatar(avatarFile, userId, accessToken);
      updatePayload.avatar_url = avatarUrl;
    } catch (error) {
      this.logger.error('Avatar update handling failed', error);
      throw error;
    }
  }

  private isValidEmail(email: string): boolean {
    const emailRegex = /^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$/;
    return emailRegex.test(email) && email.length <= 254;
  }

  private isStrongPassword(password: string): boolean {
    const strongRegex = /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)[A-Za-z\d]{8,}$/;
    return strongRegex.test(password);
  }


  private isValidAvatarUrl(url: string, userId: string): boolean {
    try {
      const urlObj = new URL(url);
      const supabaseUrl = process.env.SUPABASE_URL;
      if (!supabaseUrl || !url.includes(supabaseUrl)) {
        return false;
      }
      return url.includes(`/${userId}/`);
    } catch {
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
      throw new BadRequestException('Invalid file type');
    }

    if (file.size > this.MAX_FILE_SIZE) {
      throw new BadRequestException('File size exceeds 5MB limit');
    }

    if (file.size === 0) {
      throw new BadRequestException('File is empty');
    }

    const signature = file.buffer.slice(0, 4).toString('hex');
    const validSignatures = [
      'ffd8ffe0', // JPG
      'ffd8ffe1', // JPG
      'ffd8ffe2', // JPG
      '89504e47', // PNG
      '52494646', // WEBP
    ];

    if (!validSignatures.some(sig => signature.startsWith(sig))) {
      throw new BadRequestException('File content does not match declared type');
    }
  }

  private sanitizeUserData(user: any): any {
    const {
      encrypted_password,
      email_confirmed_at,
      confirmation_sent_at,
      recovery_sent_at,
      email_change_sent_at,
      ...safeUser
    } = user;

    return safeUser;
  }
}