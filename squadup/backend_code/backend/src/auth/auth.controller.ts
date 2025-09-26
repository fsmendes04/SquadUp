import {
  Controller,
  Post,
  Body,
  HttpException,
  HttpStatus,
  Put,
  UseGuards,
  UseInterceptors,
  UploadedFile,
  MaxFileSizeValidator,
  FileTypeValidator,
  ParseFilePipe,
  Req
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { AuthService } from './auth.service';
import { RegisterDto } from './dto/register.dto';
import { LoginDto } from './dto/login.dto';
import { UpdateProfileDto } from './dto/update-profile.dto';
import { UpdateAvatarDto } from './dto/update-avatar.dto';
import { AuthGuard } from './auth.guard';
import { CurrentUser } from './current-user.decorator';

@Controller('auth')
export class AuthController {
  constructor(private readonly authService: AuthService) { }

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
      console.log('🔍 UpdateProfile - user object:', user);
      console.log('🔍 UpdateProfile - user.id:', user?.id);
      console.log('🔍 UpdateProfile - updateData:', updateData);

      const result = await this.authService.updateProfileWithUserId(updateData, user.id);

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

  @Post('upload-avatar')
  @UseGuards(AuthGuard)
  @UseInterceptors(FileInterceptor('avatar'))
  async uploadAvatar(
    @UploadedFile(
      new ParseFilePipe({
        validators: [
          new MaxFileSizeValidator({ maxSize: 5 * 1024 * 1024 }), // 5MB
          new FileTypeValidator({ fileType: /^image\/(jpeg|jpg|png|gif|webp)$/ }),
        ],
      }),
    )
    file: Express.Multer.File,
    @CurrentUser() user: any,
    @Req() request: any,
  ) {
    try {
      console.log('🔍 Debug uploadAvatar - user object:', user);
      console.log('🔍 Debug uploadAvatar - user.id:', user?.id);

      const accessToken = request.accessToken;
      const result = await this.authService.updateAvatar(file, user.id, accessToken);

      return {
        success: true,
        message: 'Avatar uploaded successfully',
        data: result,
      };
    } catch (error) {
      throw new HttpException(
        {
          success: false,
          message: 'Error uploading avatar',
          error: error.message,
        },
        HttpStatus.BAD_REQUEST,
      );
    }
  }

  @Put('update-avatar-url')
  @UseGuards(AuthGuard)
  async updateAvatarUrl(
    @Body() updateAvatarDto: UpdateAvatarDto,
    @CurrentUser() user: any,
  ) {
    try {
      const updateData: UpdateProfileDto = { avatar_url: updateAvatarDto.avatar_url };
      const result = await this.authService.updateProfile(updateData);

      return {
        success: true,
        message: 'Avatar URL updated successfully',
        data: result,
      };
    } catch (error) {
      throw new HttpException(
        {
          success: false,
          message: 'Error updating avatar URL',
          error: error.message,
        },
        HttpStatus.BAD_REQUEST,
      );
    }
  }
}