import {
  Controller,
  Post,
  Body,
  HttpException,
  HttpStatus,
  Put,
  UseGuards
} from '@nestjs/common';
import { AuthService } from './auth.service';
import { RegisterDto } from './dto/register.dto';
import { LoginDto } from './dto/login.dto';
import { UpdateProfileDto } from './dto/update-profile.dto';
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


}