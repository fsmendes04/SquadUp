import {
  Injectable,
  CanActivate,
  ExecutionContext,
  UnauthorizedException,
  Logger
} from '@nestjs/common';
import { UserService } from './userService';

@Injectable()
export class AuthGuard implements CanActivate {
  private readonly logger = new Logger(AuthGuard.name);

  constructor(private readonly userService: UserService) { }

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const request = context.switchToHttp().getRequest();
    const authHeader = request.headers.authorization;

    if (!authHeader) {
      this.logger.warn('Missing authorization header');
      throw new UnauthorizedException('Authorization header required');
    }

    if (!authHeader.startsWith('Bearer ')) {
      this.logger.warn('Invalid authorization header format');
      throw new UnauthorizedException('Invalid authorization format. Use: Bearer <token>');
    }

    const token = authHeader.substring(7).trim();

    if (!token) {
      this.logger.warn('Empty token provided');
      throw new UnauthorizedException('Token cannot be empty');
    }

    if (!this.isValidJWTFormat(token)) {
      this.logger.warn('Invalid JWT format');
      throw new UnauthorizedException('Invalid token format');
    }

    try {
      const user = await this.userService.getUserFromToken(token);

      request.user = user;
      request.userId = user.id;

      return true;
    } catch (error) {
      this.logger.warn(`Authentication failed: ${error.message}`);
      throw new UnauthorizedException('Invalid or expired token');
    }
  }

  private isValidJWTFormat(token: string): boolean {
    const parts = token.split('.');

    if (parts.length !== 3) {
      return false;
    }

    return parts.every(part => {
      if (part.length === 0) return false;
      return /^[A-Za-z0-9_-]+$/.test(part);
    });
  }
}