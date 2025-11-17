import { Injectable, UnauthorizedException, BadRequestException, Logger } from '@nestjs/common';
import { SupabaseService } from '../Supabase/supabaseService';

@Injectable()
export class SessionService {
  private readonly logger = new Logger(SessionService.name);

  constructor(private readonly supabase: SupabaseService) { }

  async refreshSession(refreshToken: string) {
    try {
      if (!refreshToken) {
        throw new UnauthorizedException('Refresh token is required');
      }

      const { data, error } = await this.supabase.getClient().auth.refreshSession({
        refresh_token: refreshToken,
      });

      if (error) {
        this.logger.warn('Invalid refresh token attempt');
        throw new UnauthorizedException('Invalid refresh token');
      }

      if (!data.session) {
        throw new UnauthorizedException('Failed to refresh session');
      }

      this.logger.log('Session refreshed successfully');

      return {
        access_token: data.session.access_token,
        refresh_token: data.session.refresh_token,
        expires_in: data.session.expires_in,
        expires_at: data.session.expires_at,
      };
    } catch (error) {
      if (error instanceof UnauthorizedException) {
        throw error;
      }
      this.logger.error('Unexpected session refresh error', error);
      throw new UnauthorizedException('Session refresh failed');
    }
  }

  async revokeSession(token: string) {
    try {
      if (!token) {
        throw new BadRequestException('Token is required');
      }

      const { error: signOutError } = await this.supabase
        .getClient()
        .auth
        .signOut({ scope: 'global' });

      if (signOutError) {
        this.logger.error('Failed to revoke session', signOutError);
        throw new BadRequestException('Failed to revoke session');
      }

      this.logger.log('Session revoked successfully');

      return {
        success: true,
        message: 'Session revoked successfully'
      };
    } catch (error) {
      if (error instanceof BadRequestException) {
        throw error;
      }
      this.logger.error('Unexpected session revocation error', error);
      throw new BadRequestException('Failed to revoke session');
    }
  }

  async validateSession(token: string) {
    try {
      const { data: { user }, error } = await this.supabase.getClient().auth.getUser(token);

      if (error || !user) {
        throw new UnauthorizedException('Invalid or expired session');
      }

      return user;
    } catch (error) {
      this.logger.warn('Session validation failed');
      throw new UnauthorizedException('Invalid session');
    }
  }
}