import {
  Controller,
  Post,
  Body,
  HttpException,
  HttpStatus,
  Put,
  UseGuards,
  UploadedFile,
  UseInterceptors,
  Get,
  Delete
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { AuthService } from './auth.service';
import { RegisterDto } from './dto/register.dto';
import { LoginDto } from './dto/login.dto';
import { UpdateProfileDto } from './dto/update-profile.dto';
import { AuthGuard } from './auth.guard';
import { CurrentUser } from './current-user.decorator';
import { UploadService } from '../upload/upload.service';

@Controller('auth')
export class AuthController {
  constructor(
    private readonly authService: AuthService,
    private readonly uploadService: UploadService,
  ) { }

  @Post('register')
  async register(@Body() registerDto: RegisterDto) {
    try {
      const result = await this.authService.register(
        registerDto.email,
        registerDto.password,
      );

      return {
        success: true,
        message: 'User registered successfully',
        data: {
          user: result.user,
          session: result.session,
        },
      };
    } catch (error) {
      throw new HttpException(
        {
          success: false,
          message: 'Error registering user',
          error: error.message,
        },
        HttpStatus.BAD_REQUEST,
      );
    }
  }

  @Post('login')
  async login(@Body() loginDto: LoginDto) {
    try {
      const result = await this.authService.login(
        loginDto.email,
        loginDto.password,
      );

      return {
        success: true,
        message: 'Login successful',
        data: {
          user: result.user,
          session: result.session,
        },
      };
    } catch (error) {
      throw new HttpException(
        {
          success: false,
          message: 'Error logging in',
          error: error.message,
        },
        HttpStatus.UNAUTHORIZED,
      );
    }
  }

  @Put('update-profile')
  @UseGuards(AuthGuard)
  async updateProfile(
    @Body() updateData: UpdateProfileDto,
    @CurrentUser() user: any
  ) {
    try {
      const result = await this.authService.updateProfile(updateData);

      return {
        success: true,
        message: 'Profile updated successfully',
        data: result,
      };
    } catch (error) {
      throw new HttpException(
        {
          success: false,
          message: 'Error updating profile',
          error: error.message,
        },
        HttpStatus.BAD_REQUEST,
      );
    }
  }

  @Post('avatar')
  @UseGuards(AuthGuard)
  @UseInterceptors(FileInterceptor('avatar'))
  async uploadAvatar(
    @UploadedFile() file: Express.Multer.File,
    @CurrentUser() user: any,
  ) {
    try {
      // Fazer upload do novo avatar
      const uploadResult = await this.uploadService.uploadAvatar(user.id, file);

      // Remover avatar antigo se existir
      if (user.user_metadata?.avatar_path) {
        await this.uploadService.deleteAvatar(user.user_metadata.avatar_path);
      }

      // Atualizar perfil do usuário com nova URL do avatar
      const profileUpdate = await this.authService.updateProfile({
        avatar_url: uploadResult.url,
        avatar_path: uploadResult.path,
      });

      // Limpar avatares antigos (manter apenas o atual)
      await this.uploadService.cleanupOldAvatars(user.id, uploadResult.path);

      return {
        success: true,
        message: 'Avatar uploaded successfully',
        data: {
          user: profileUpdate,
          avatar: {
            url: uploadResult.url,
            path: uploadResult.path,
          },
        },
      };
    } catch (error) {
      throw new HttpException(
        {
          success: false,
          message: 'Error uploading avatar',
          error: error.message || error,
        },
        error.status || HttpStatus.BAD_REQUEST,
      );
    }
  }

  @Get('avatar')
  @UseGuards(AuthGuard)
  async getAvatar(@CurrentUser() user: any) {
    try {
      const avatarUrl = user.user_metadata?.avatar_url;

      if (!avatarUrl) {
        return {
          success: true,
          message: 'No avatar found',
          data: {
            avatar_url: null,
          },
        };
      }

      return {
        success: true,
        message: 'Avatar retrieved successfully',
        data: {
          avatar_url: avatarUrl,
        },
      };
    } catch (error) {
      throw new HttpException(
        {
          success: false,
          message: 'Error retrieving avatar',
          error: error.message || error,
        },
        HttpStatus.BAD_REQUEST,
      );
    }
  }

  @Delete('avatar')
  @UseGuards(AuthGuard)
  async deleteAvatar(@CurrentUser() user: any) {
    try {
      // Remover arquivo do storage se existir
      if (user.user_metadata?.avatar_path) {
        await this.uploadService.deleteAvatar(user.user_metadata.avatar_path);
      }

      // Limpar todos os avatares do usuário
      await this.uploadService.cleanupOldAvatars(user.id);

      // Atualizar perfil removendo referências ao avatar
      const profileUpdate = await this.authService.updateProfile({
        avatar_url: undefined,
        avatar_path: undefined,
      });

      return {
        success: true,
        message: 'Avatar deleted successfully',
        data: {
          user: profileUpdate,
        },
      };
    } catch (error) {
      throw new HttpException(
        {
          success: false,
          message: 'Error deleting avatar',
          error: error.message || error,
        },
        HttpStatus.BAD_REQUEST,
      );
    }
  }

  @Get('profile')
  @UseGuards(AuthGuard)
  async getProfile(@CurrentUser() user: any) {
    try {
      return {
        success: true,
        message: 'Profile retrieved successfully',
        data: {
          user: user,
        },
      };
    } catch (error) {
      throw new HttpException(
        {
          success: false,
          message: 'Error retrieving profile',
          error: error.message || error,
        },
        HttpStatus.BAD_REQUEST,
      );
    }
  }
}