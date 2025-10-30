import { plainToInstance } from 'class-transformer';
import { IsString, IsUrl, validateSync, IsEnum } from 'class-validator';

export enum Environment {
  Development = 'development',
  Production = 'production',
  Test = 'test',
}

export class EnvironmentVariables {
  @IsUrl({ require_tld: false }, { message: 'SUPABASE_URL must be a valid URL' })
  SUPABASE_URL: string;

  @IsString({ message: 'SUPABASE_KEY is required' })
  SUPABASE_KEY: string;

  @IsString({ message: 'SUPABASE_SERVICE_ROLE_KEY is required' })
  SUPABASE_SERVICE_ROLE_KEY: string;

  @IsString({ message: 'ALLOWED_ORIGINS is required' })
  ALLOWED_ORIGINS: string;

  @IsEnum(Environment, { message: 'NODE_ENV must be development, production, or test' })
  NODE_ENV: Environment;
}

export function validateEnvironment(config: Record<string, unknown>) {
  const validatedConfig = plainToInstance(EnvironmentVariables, config, {
    enableImplicitConversion: true,
  });

  const errors = validateSync(validatedConfig, {
    skipMissingProperties: false,
  });

  if (errors.length > 0) {
    const errorMessages = errors
      .map(error => Object.values(error.constraints || {}))
      .flat();

    throw new Error(
      `Environment validation failed:\n${errorMessages.join('\n')}`
    );
  }

  return validatedConfig;
}
