import { Injectable, HttpException, HttpStatus, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { RedisService } from '../../redis/redis.service.js';

const OTP_TTL          = 300;   // 5 minutes
const OTP_LIMIT_TTL    = 900;   // 15 minutes
const OTP_MAX_REQUESTS = 3;
const OTP_MAX_ATTEMPTS = 3;

@Injectable()
export class OtpService {
  private readonly logger = new Logger(OtpService.name);

  constructor(
    private redis: RedisService,
    private config: ConfigService,
  ) {}

  // ── Send phone OTP via Fast2SMS ───────────────────────────────────────────

  async sendOtp(phone: string, type: string = 'DEFAULT'): Promise<void> {
    await this.checkRateLimit(phone);

    const otp = this.generateOtp();
    await this.redis.set(`otp:${phone}`, JSON.stringify({ otp, type }), OTP_TTL);

    const limitKey = `otp_limit:${phone}`;
    const count = await this.redis.incr(limitKey);
    if (count === 1) await this.redis.expire(limitKey, OTP_LIMIT_TTL);

    // Always log for dev debugging — useful even when SMS is enabled
    this.logger.log(`[OTP] phone=${phone} otp=${otp} type=${type}`);

    await this.sendSmsFast2Sms(phone, otp);
  }

  // ── Send email OTP via SendGrid ───────────────────────────────────────────

  async sendEmailOtp(email: string): Promise<void> {
    const otp = this.generateOtp();
    await this.redis.set(`otp:${email}`, JSON.stringify({ otp, type: 'ADMIN_LOGIN' }), OTP_TTL);

    this.logger.log(`[OTP-EMAIL] email=${email} otp=${otp}`);

    await this.sendEmailSendGrid(email, otp);
  }

  // ── Verify OTP ────────────────────────────────────────────────────────────

  async verifyOtp(identifier: string, submittedOtp: string, expectedType?: string): Promise<void> {
    const raw = await this.redis.get(`otp:${identifier}`);
<<<<<<< HEAD
    this.logger.log(`[DBG-H4] otpVerify identifier=${identifier} hasRecord=${!!raw} expectedType=${expectedType ?? 'NA'} submittedLen=${submittedOtp?.length ?? 0}`);
    // #region agent log
    fetch('http://127.0.0.1:7572/ingest/0165e44f-c140-425a-bb49-5e5c88d4f3e3',{method:'POST',headers:{'Content-Type':'application/json','X-Debug-Session-Id':'2e5b8f'},body:JSON.stringify({sessionId:'2e5b8f',runId:'run1',hypothesisId:'H4',location:'otp.service.ts:verifyOtp',message:'verifyOtp redis lookup',data:{identifierPrefix:identifier.slice(0,3),identifierLen:identifier.length,hasOtpRecord:!!raw,submittedOtpLen:(submittedOtp??'').length,expectedType:expectedType??null},timestamp:Date.now()})}).catch(()=>{});
    // #endregion
=======
>>>>>>> 9164b54b7ae96a96dfb046b32a6f1d92bc55e577

    if (!raw) {
      throw new HttpException({ code: 'OTP_EXPIRED', message: 'OTP has expired. Request a new one.' }, HttpStatus.BAD_REQUEST);
    }

    const { otp, type } = JSON.parse(raw) as { otp: string; type: string };
<<<<<<< HEAD
    this.logger.log(`[DBG-H4] otpRecord identifier=${identifier} storedType=${type} otpMatch=${otp === submittedOtp}`);
    // #region agent log
    fetch('http://127.0.0.1:7572/ingest/0165e44f-c140-425a-bb49-5e5c88d4f3e3',{method:'POST',headers:{'Content-Type':'application/json','X-Debug-Session-Id':'2e5b8f'},body:JSON.stringify({sessionId:'2e5b8f',runId:'run1',hypothesisId:'H4',location:'otp.service.ts:verifyOtp',message:'verifyOtp compare/meta',data:{storedType:type,matchesExpectedType:expectedType?type===expectedType:true,matchesOtp:otp===submittedOtp},timestamp:Date.now()})}).catch(()=>{});
    // #endregion
=======
>>>>>>> 9164b54b7ae96a96dfb046b32a6f1d92bc55e577

    if (expectedType && type !== expectedType) {
      throw new HttpException({ code: 'OTP_INVALID', message: 'Incorrect OTP.' }, HttpStatus.BAD_REQUEST);
    }

    const attemptsKey = `otp_attempts:${identifier}`;
    const attempts = await this.redis.incr(attemptsKey);
    if (attempts === 1) await this.redis.expire(attemptsKey, OTP_LIMIT_TTL);

    if (otp !== submittedOtp) {
      if (attempts >= OTP_MAX_ATTEMPTS) {
        await this.redis.del(`otp:${identifier}`, attemptsKey);
        throw new HttpException({ code: 'OTP_MAX_ATTEMPTS', message: 'Too many wrong attempts. Try again in 15 minutes.' }, HttpStatus.BAD_REQUEST);
      }
      throw new HttpException({ code: 'OTP_INVALID', message: 'Incorrect OTP. Please try again.' }, HttpStatus.BAD_REQUEST);
    }

    await this.redis.del(`otp:${identifier}`, attemptsKey);
  }

  async deleteOtp(identifier: string): Promise<void> {
    await this.redis.del(`otp:${identifier}`);
  }

  // ── Private: Fast2SMS ─────────────────────────────────────────────────────

  private async sendSmsFast2Sms(phone: string, otp: string): Promise<void> {
    const apiKey = this.config.get<string>('FAST2SMS_API_KEY');
    if (!apiKey) {
      this.logger.warn('[OTP] FAST2SMS_API_KEY not configured — SMS not sent');
      return;
    }

    // Fast2SMS expects 10-digit Indian mobile number (no country code)
    const mobile = phone.replace(/^\+91/, '').replace(/\D/g, '');

    const url = new URL('https://www.fast2sms.com/dev/bulkV2');
    url.searchParams.set('authorization', apiKey);
    url.searchParams.set('route', 'q');
    url.searchParams.set('message', `Your Bhojan OTP is ${otp}. Valid for 5 minutes. Do not share this code.`);
    url.searchParams.set('language', 'english');
    url.searchParams.set('flash', '0');
    url.searchParams.set('numbers', mobile);

    try {
      const res = await fetch(url.toString());
      const data = await res.json() as { return: boolean; message: string | string[] };
      if (!data.return) {
        const msg = Array.isArray(data.message) ? data.message.join(', ') : data.message;
        this.logger.error(`[OTP] Fast2SMS rejected: ${msg}`);
      } else {
        this.logger.log(`[OTP] SMS sent via Fast2SMS to ${mobile}`);
      }
    } catch (err) {
      this.logger.error(`[OTP] Fast2SMS request failed: ${err}`);
    }
  }

  // ── Send vendor activation email ─────────────────────────────────────────

  async sendActivationEmail(email: string, activationLink: string): Promise<void> {
<<<<<<< HEAD
    const apiKey = this.config.get<string>('SENDGRID_API_KEY') ?? this.config.get<string>('SMTP_PASS');
    const from   = this.config.get<string>('SENDGRID_FROM_EMAIL') ?? this.config.get<string>('EMAIL_FROM') ?? 'noreply@bhojan.app';
=======
    const apiKey = this.config.get<string>('SMTP_PASS');
    const from   = this.config.get<string>('EMAIL_FROM') ?? 'noreply@bhojan.app';
>>>>>>> 9164b54b7ae96a96dfb046b32a6f1d92bc55e577

    if (!apiKey?.startsWith('SG.')) {
      this.logger.warn('[ACTIVATION-EMAIL] SendGrid API key not configured — email not sent');
      return;
    }

    const body = {
      personalizations: [{ to: [{ email }] }],
      from: { email: from, name: 'Bhojan' },
      subject: 'Activate your Bhojan Vendor Account',
      content: [{
        type: 'text/plain',
        value: `Welcome to Bhojan!\n\nYour vendor account has been created. Click the link below to set your password and activate your account:\n\n${activationLink}\n\nThis link is valid for 24 hours.\n\nDo not share this link with anyone.`,
      }],
    };

    try {
      const res = await fetch('https://api.sendgrid.com/v3/mail/send', {
        method: 'POST',
        headers: { 'Authorization': `Bearer ${apiKey}`, 'Content-Type': 'application/json' },
        body: JSON.stringify(body),
      });

      if (res.status === 202) {
        this.logger.log(`[ACTIVATION-EMAIL] Email sent via SendGrid to ${email}`);
      } else {
        const text = await res.text();
        this.logger.error(`[ACTIVATION-EMAIL] SendGrid error ${res.status}: ${text}`);
      }
    } catch (err) {
      this.logger.error(`[ACTIVATION-EMAIL] SendGrid request failed: ${err}`);
    }
  }

  // ── Private: SendGrid email ───────────────────────────────────────────────

  private async sendEmailSendGrid(email: string, otp: string): Promise<void> {
<<<<<<< HEAD
    const apiKey  = this.config.get<string>('SENDGRID_API_KEY') ?? this.config.get<string>('SMTP_PASS');
    const from    = this.config.get<string>('SENDGRID_FROM_EMAIL') ?? this.config.get<string>('EMAIL_FROM') ?? 'noreply@bhojan.app';
=======
    const apiKey  = this.config.get<string>('SMTP_PASS');
    const from    = this.config.get<string>('EMAIL_FROM') ?? 'noreply@bhojan.app';
>>>>>>> 9164b54b7ae96a96dfb046b32a6f1d92bc55e577

    if (!apiKey?.startsWith('SG.')) {
      this.logger.warn('[OTP-EMAIL] SendGrid API key not configured — email not sent');
      return;
    }

    const body = {
      personalizations: [{ to: [{ email }] }],
      from: { email: from, name: 'Bhojan' },
      subject: 'Your Bhojan Admin Login OTP',
      content: [{
        type: 'text/plain',
        value: `Your Bhojan admin OTP is ${otp}. Valid for 5 minutes. Do not share this code with anyone.`,
      }],
    };

    try {
      const res = await fetch('https://api.sendgrid.com/v3/mail/send', {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${apiKey}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(body),
      });

      if (res.status === 202) {
        this.logger.log(`[OTP-EMAIL] Email sent via SendGrid to ${email}`);
      } else {
        const text = await res.text();
        this.logger.error(`[OTP-EMAIL] SendGrid error ${res.status}: ${text}`);
      }
    } catch (err) {
      this.logger.error(`[OTP-EMAIL] SendGrid request failed: ${err}`);
    }
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  private generateOtp(): string {
    return Math.floor(100000 + Math.random() * 900000).toString();
  }

  private async checkRateLimit(phone: string): Promise<void> {
    const count = await this.redis.get(`otp_limit:${phone}`);
    if (count && parseInt(count, 10) >= OTP_MAX_REQUESTS) {
      throw new HttpException(
        { code: 'OTP_RATE_LIMIT', message: 'Too many OTP requests. Wait 15 minutes before trying again.' },
        HttpStatus.TOO_MANY_REQUESTS,
      );
    }
  }
}
