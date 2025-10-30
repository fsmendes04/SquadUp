import { Injectable, NestMiddleware, Logger } from '@nestjs/common';
import { Request, Response, NextFunction } from 'express';

@Injectable()
export class RequestLoggingMiddleware implements NestMiddleware {
  private readonly logger = new Logger('HTTP');

  use(req: Request, res: Response, next: NextFunction) {
    const { method, originalUrl, ip } = req;
    const userAgent = req.get('user-agent') || '';
    const startTime = Date.now();

    res.on('finish', () => {
      const { statusCode } = res;
      const responseTime = Date.now() - startTime;

      // Log suspicious activity
      if (statusCode === 401 || statusCode === 403) {
        this.logger.warn(
          `${method} ${originalUrl} ${statusCode} - IP: ${ip} - ${userAgent} - ${responseTime}ms`
        );
      } else if (statusCode >= 400) {
        this.logger.error(
          `${method} ${originalUrl} ${statusCode} - IP: ${ip} - ${responseTime}ms`
        );
      } else {
        this.logger.log(
          `${method} ${originalUrl} ${statusCode} - ${responseTime}ms`
        );
      }
    });

    next();
  }
}
