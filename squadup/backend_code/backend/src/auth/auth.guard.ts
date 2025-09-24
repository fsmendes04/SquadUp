import { Injectable, CanActivate, ExecutionContext, UnauthorizedException } from '@nestjs/common';
import { AuthService } from '../auth/auth.service';

@Injectable()
export class AuthGuard implements CanActivate {
  constructor(private authService: AuthService) { }

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
      return true;
    } catch (error) {
      throw new UnauthorizedException('Invalid token');
    }
  }
}