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
import * as DOMPurify from 'isomorphic-dompurify';

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
    avatarFile?: Express.Multer.File
  ) {

    try {
      const updatePayload: any = {};

      if (updateData.name !== undefined) {
        const sanitizedName = this.sanitizeString(updateData.name);

        if (sanitizedName.length > this.MAX_NAME_LENGTH) {
          throw new BadRequestException(`Name cannot exceed ${this.MAX_NAME_LENGTH} characters`);
        }

        updatePayload.name = sanitizedName || null;
      }

      if (updateData.avatar_url !== undefined && !avatarFile) {
        if (!this.isValidAvatarUrl(updateData.avatar_url, userId)) {
          throw new BadRequestException('Invalid avatar URL');
        }
        updatePayload.avatar_url = updateData.avatar_url;
      }

      if (avatarFile) {
        this.validateAvatarFile(avatarFile);
        await this.handleAvatarUpdate(userId, avatarFile, updatePayload);
      }

      if (Object.keys(updatePayload).length === 0) {
        throw new BadRequestException('No valid fields to update');
      }

      const adminClient = this.supabase.getAdminClient();
      const { data, error } = await adminClient.auth.admin.updateUserById(userId, {
        user_metadata: updatePayload,
      });

      if (error) {
        this.logger.error(`Profile update failed for user: ${userId}`, error.message);
        throw new BadRequestException('Unable to update profile');
      }

      this.logger.log(`Profile updated successfully for user: ${userId}`);
      return this.sanitizeUserData(data.user);
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

  async uploadAvatar(file: Express.Multer.File, userId: string): Promise<string> {
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

      const { error } = await this.supabase.getClient().storage
        .from('user-uploads')
        .upload(filePath, file.buffer, {
          contentType: file.mimetype,
          upsert: false,
          cacheControl: '3600'
        });

      if (error) {
        this.logger.error(`Avatar upload failed for user: ${userId}`, error.message);
        throw new BadRequestException('Failed to upload avatar');
      }

      const { data: publicUrlData } = this.supabase.getClient().storage
        .from('user-uploads')
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
    updatePayload: any
  ): Promise<void> {
    try {
      const adminClient = this.supabase.getAdminClient();
      const { data: currentUser, error: getUserError } = await adminClient.auth.admin.getUserById(userId);

      if (!getUserError && currentUser?.user?.user_metadata?.avatar_url) {
        const currentAvatarUrl = currentUser.user.user_metadata.avatar_url;

        try {
          const urlObj = new URL(currentAvatarUrl);
          const pathParts = urlObj.pathname.split('/');
          const fileName = pathParts[pathParts.length - 1];
          const userIdFromPath = pathParts[pathParts.length - 2];

          if (userIdFromPath === userId) {
            const oldFilePath = `${userId}/${fileName}`;
            await this.supabase.getClient().storage
              .from('user-uploads')
              .remove([oldFilePath]);
          }
        } catch (deleteErr) {
          this.logger.warn('Could not delete old avatar', deleteErr);
        }
      }

      const avatarUrl = await this.uploadAvatar(avatarFile, userId);
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
    const cleaned = DOMPurify.sanitize(input, {
      ALLOWED_TAGS: [],
      ALLOWED_ATTR: []
    });
    return cleaned.trim();
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