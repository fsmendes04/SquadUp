import {
  Controller,
  Post,
  Body,
  HttpException,
  HttpStatus,
  Put,
  Get,
  UseGuards,
  UseInterceptors,
  UploadedFile,
  MaxFileSizeValidator,
  FileTypeValidator,
  ParseFilePipe,
  Logger,
  BadRequestException
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { Throttle } from '@nestjs/throttler';
import { UserService } from './userService';
import { SessionService } from './sessionService';
import { RegisterDto } from './dto/register.dto';
import { LoginDto } from './dto/login.dto';
import { UpdateProfileDto } from './dto/update-profile.dto';
import { RefreshTokenDto } from './dto/refresh-token.dto';
import { AuthGuard } from './userToken';
import { CurrentUser } from '../common/decorators';
import { GetToken } from '../common/decorators';

@Controller('user')
export class UserController {
  private readonly logger = new Logger(UserController.name);

  constructor(
    private readonly userService: UserService,
    private readonly sessionService: SessionService,
  ) { }


  @Post('register')
  @Throttle({ default: { limit: 15, ttl: 60000 } })
  async register(@Body() registerDto: RegisterDto) {
    try {
      // Additional input validation
      if (!registerDto.email || !registerDto.password) {
        throw new BadRequestException('Email and password are required');
      }

      const result = await this.userService.register(
        registerDto.email,
        registerDto.password,
      );

      // Don't return session data with sensitive info
      return {
        success: true,
        message: 'User registered successfully. Please check your email to confirm your account.',
        data: {
          user: {
            id: result.user?.id,
            email: result.user?.email,
            created_at: result.user?.created_at
          }
        },
      };
    } catch (error) {
      this.logger.error('Registration error', error.message);

      const statusCode = error.status || HttpStatus.BAD_REQUEST;
      throw new HttpException(
        {
          success: false,
          message: error.message || 'Registration failed',
        },
        statusCode,
      );
    }
  }

  @Post('login')
  @Throttle({ default: { limit: 5, ttl: 60000 } }) // 5 requests per minute
  async login(@Body() loginDto: LoginDto) {
    try {
      // Additional input validation
      if (!loginDto.email || !loginDto.password) {
        throw new BadRequestException('Email and password are required');
      }

      const result = await this.userService.login(
        loginDto.email,
        loginDto.password,
      );

      // Return minimal necessary data
      return {
        success: true,
        message: 'Login successful',
        data: {
          user: {
            id: result.user.id,
            email: result.user.email,
            user_metadata: result.user.user_metadata
          },
          access_token: result.session?.access_token,
          refresh_token: result.session?.refresh_token,
          expires_in: result.session?.expires_in,
          expires_at: result.session?.expires_at
        },
      };
    } catch (error) {
      this.logger.error('Login error', error.message);

      throw new HttpException(
        {
          success: false,
          message: 'Invalid credentials',
        },
        HttpStatus.UNAUTHORIZED,
      );
    }
  }

  @Put('profile')
  @UseGuards(AuthGuard)
  @UseInterceptors(FileInterceptor('avatar'))
  @Throttle({ default: { limit: 10, ttl: 60000 } }) // 10 requests per minute
  async updateProfile(
    @Body() updateData: UpdateProfileDto,
    @CurrentUser() user: any,
    @GetToken() token: string,
    @UploadedFile(
      new ParseFilePipe({
        validators: [
          new MaxFileSizeValidator({ maxSize: 5 * 1024 * 1024 }), // 5MB
          new FileTypeValidator({ fileType: /^image\/(jpeg|jpg|png|webp)$/ }),
        ],
        fileIsRequired: false,
      }),
    )
    file?: Express.Multer.File,
  ) {
    try {
      // Validate that at least one field is being updated
      if (!updateData.name && !updateData.avatar_url && !file) {
        throw new BadRequestException('At least one field must be provided for update');
      }

      const result = await this.userService.updateProfile(
        updateData,
        user.id,
        file,
        token
      );

      return {
        success: true,
        message: 'Profile updated successfully',
        data: {
          id: result.id,
          email: result.email,
          user_metadata: result.user_metadata
        },
      };
    } catch (error) {
      this.logger.error('Profile update error', error.message);

      const statusCode = error.status || HttpStatus.BAD_REQUEST;
      throw new HttpException(
        {
          success: false,
          message: error.message || 'Failed to update profile',
        },
        statusCode,
      );
    }
  }


  @Get('profile')
  @UseGuards(AuthGuard)
  @Throttle({ default: { limit: 30, ttl: 60000 } }) // 30 requests per minute
  async getCurrentUserProfile(
    @CurrentUser() user: any,
    @GetToken() token: string, // <-- ADICIONAR DECORATOR PARA OBTER O TOKEN
  ) {
    try {
      const userData = await this.userService.getProfile(token);

      return {
        success: true,
        message: 'User retrieved successfully',
        data: {
          ...userData,
        },
      };
    } catch (error) {
      this.logger.error('Get profile error', error.message);

      const statusCode = error.status || HttpStatus.BAD_REQUEST;
      throw new HttpException(
        {
          success: false,
          message: error.message || 'Failed to retrieve profile',
        },
        statusCode,
      );
    }
  }

  @Post('refresh')
  @Throttle({ default: { limit: 10, ttl: 60000 } })
  async refreshSession(@Body() refreshTokenDto: RefreshTokenDto) {
    try {
      const result = await this.sessionService.refreshSession(refreshTokenDto.refresh_token);

      return {
        success: true,
        message: 'Session refreshed successfully',
        data: result,
      };
    } catch (error) {
      this.logger.error('Session refresh error', error.message);

      throw new HttpException(
        {
          success: false,
          message: error.message || 'Failed to refresh session',
        },
        error.status || HttpStatus.UNAUTHORIZED,
      );
    }
  }

  @Post('logout')
  @UseGuards(AuthGuard)
  async logout(@GetToken() token: string) {
    try {
      await this.userService.logout(token);
      return {
        success: true,
        message: 'Logout successful',
      };
    } catch (error) {
      this.logger.error('Logout error', error.message);
      throw new HttpException(
        {
          success: false,
          message: error.message || 'Logout failed',
        },
        error.status || HttpStatus.BAD_REQUEST,
      );
    } 
  }
}