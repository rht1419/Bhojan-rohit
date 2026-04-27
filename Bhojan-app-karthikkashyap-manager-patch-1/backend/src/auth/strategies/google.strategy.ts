import { Injectable, UnauthorizedException } from '@nestjs/common';
import { PassportStrategy } from '@nestjs/passport';
import { Strategy, VerifyCallback } from 'passport-google-oauth20';
import { ConfigService } from '@nestjs/config';

export interface GoogleProfilePayload {
  email: string;
  name: string;
  google_sub: string;
}

@Injectable()
export class GoogleStrategy extends PassportStrategy(Strategy, 'google') {
  constructor(config: ConfigService) {
    // passport-google-oauth20 throws at init if clientID is empty.
    // Google SSO is a P2 feature — use a placeholder when env vars aren't set
    // so the server boots cleanly in local dev without SSO credentials.
    const clientID = config.get<string>('GOOGLE_CLIENT_ID') || 'GOOGLE_SSO_NOT_CONFIGURED';
    const clientSecret = config.get<string>('GOOGLE_CLIENT_SECRET') || 'GOOGLE_SSO_NOT_CONFIGURED';
    super({
      clientID,
      clientSecret,
      callbackURL: config.get<string>('GOOGLE_CALLBACK_URL') ?? 'http://localhost:3000/auth/sso/google/callback',
      scope: ['email', 'profile'],
    });
  }

  validate(
    _accessToken: string,
    _refreshToken: string,
    profile: import('passport-google-oauth20').Profile,
    done: VerifyCallback,
  ): void {
    const email = profile.emails?.[0]?.value;
    if (!email) {
      done(new UnauthorizedException({ code: 'SSO_PROVIDER_ERROR', message: 'Google profile has no email.' }), undefined);
      return;
    }

    const payload: GoogleProfilePayload = {
      email: email.toLowerCase(),
      name: profile.displayName ?? email.split('@')[0] ?? 'Google User',
      google_sub: profile.id,
    };

    done(null, payload);
  }
}

