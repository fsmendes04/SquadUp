import { Injectable, CanActivate, ExecutionContext, UnauthorizedException } from '@nestjs/common';
import { UserService } from './userService';

@Injectable()
export class AuthGuard implements CanActivate {
  constructor(private authService: UserService) { }

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const request = context.switchToHttp().getRequest();
    const authHeader = request.headers.authorization;

    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      throw new UnauthorizedException('Authorization token required');
    }

    const token = authHeader.substring(7);

    try {
      const user = await this.authService.getUserFromToken(token);
      request.user = user; // Adiciona o usuário ao request
      request.accessToken = token; // Adiciona o token ao request
      return true;
    } catch (error) {
      throw new UnauthorizedException('Invalid token');
    }
  }
}