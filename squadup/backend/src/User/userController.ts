import {
  Controller,
  Post,
  Body,
  HttpException,
  HttpStatus,
  Put,
  Get,
  Param,
  UseGuards,
  UseInterceptors,
  UploadedFile,
  MaxFileSizeValidator,
  FileTypeValidator,
  ParseFilePipe
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { UserService } from './userService';
import { RegisterDto } from './dto/register.dto';
import { LoginDto } from './dto/login.dto';
import { UpdateProfileDto } from './dto/update-profile.dto';
import { AuthGuard } from './user.guard';
import { CurrentUser } from './current-user.decorator';

@Controller('user')
export class UserController {
  constructor(private readonly userService: UserService) { }

  @Post('register')
  async register(@Body() registerDto: RegisterDto) {
    try {
      const result = await this.userService.register(
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
      const result = await this.userService.login(
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
  @UseInterceptors(FileInterceptor('avatar'))
  async updateProfile(
    @Body() updateData: UpdateProfileDto,
    @CurrentUser() user: any,
    @UploadedFile(
      new ParseFilePipe({
        validators: [
          new MaxFileSizeValidator({ maxSize: 5 * 1024 * 1024 }), // 5MB
          new FileTypeValidator({ fileType: /^image\/(jpeg|jpg|png|gif|webp)$/ }),
        ],
        fileIsRequired: false,
      }),
    )
    file?: Express.Multer.File,
  ) {
    try {
      const result = await this.userService.updateProfile(updateData, user.id, file);

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

  @Get(':id')
  @UseGuards(AuthGuard)
  async getUserById(@Param('id') userId: string) {
    try {
      const user = await this.userService.getUserById(userId);

      return {
        success: true,
        message: 'User retrieved successfully',
        data: user,
      };
    } catch (error) {
      throw new HttpException(
        {
          success: false,
          message: 'Error retrieving user',
          error: error.message,
        },
        HttpStatus.BAD_REQUEST,
      );
    }
  }


}