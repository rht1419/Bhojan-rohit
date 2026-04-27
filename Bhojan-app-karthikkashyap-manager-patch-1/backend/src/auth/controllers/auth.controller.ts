import {
  Controller, Post, Put, Get, Delete, Body, Req, HttpCode, HttpStatus,
  UseGuards, UseInterceptors, UploadedFile, ParseFilePipe,
  MaxFileSizeValidator, FileTypeValidator,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { AuthGuard } from '@nestjs/passport';
import type { Request } from 'express';
import { AuthService } from '../services/auth.service.js';
import { ProfileService } from '../services/profile.service.js';
import { PasswordService } from '../services/password.service.js';
import { ContactService } from '../services/contact.service.js';
import { UpgradeService } from '../services/upgrade.service.js';
import { DeletionService } from '../services/deletion.service.js';
<<<<<<< HEAD
import { LoginOtpRequestV2Dto } from '../dto/login-otp-request-v2.dto.js';
=======
>>>>>>> 9164b54b7ae96a96dfb046b32a6f1d92bc55e577
import { RegisterDto } from '../dto/register.dto.js';
import { OtpVerifyDto } from '../dto/otp-verify.dto.js';
import { LoginDto } from '../dto/login.dto.js';
import { RefreshTokenDto } from '../dto/refresh-token.dto.js';
import { LogoutDto } from '../dto/logout.dto.js';
import { UpdateProfileDto } from '../dto/update-profile.dto.js';
import { PasswordResetRequestDto } from '../dto/password-reset-request.dto.js';
import { PasswordResetVerifyDto } from '../dto/password-reset-verify.dto.js';
import { ContactChangeDto } from '../dto/contact-change.dto.js';
import { ContactVerifyDto } from '../dto/contact-verify.dto.js';
import { UpgradeEmployeeDto } from '../dto/upgrade-employee.dto.js';
import { DeleteAccountDto } from '../dto/delete-account.dto.js';
import { JwtAuthGuard } from '../guards/jwt.guard.js';
import { CurrentUser } from '../decorators/current-user.decorator.js';
import type { JwtPayload } from '../services/jwt.service.js';
import { Role } from '@prisma/client';

@Controller('auth')
export class AuthController {
  constructor(
    private auth: AuthService,
    private profile: ProfileService,
    private password: PasswordService,
    private contact: ContactService,
    private upgrade: UpgradeService,
    private deletion: DeletionService,
  ) {}

  // EP-01
  @Post('register')
  @HttpCode(HttpStatus.OK)
  register(@Body() dto: RegisterDto, @Req() req: Request) {
<<<<<<< HEAD
    // #region agent log
    fetch('http://127.0.0.1:7572/ingest/0165e44f-c140-425a-bb49-5e5c88d4f3e3',{method:'POST',headers:{'Content-Type':'application/json','X-Debug-Session-Id':'2e5b8f'},body:JSON.stringify({sessionId:'2e5b8f',runId:'run1',hypothesisId:'H1',location:'auth.controller.ts:register',message:'register endpoint hit',data:{hasPhone:!!dto.phone,phoneLen:(dto.phone??'').length,userType:dto.user_type,hasEmail:!!dto.email,hasEmployeeId:!!dto.employee_id},timestamp:Date.now()})}).catch(()=>{});
    // #endregion
=======
>>>>>>> 9164b54b7ae96a96dfb046b32a6f1d92bc55e577
    return this.auth.register(dto, req.ip);
  }

  // EP-02
  @Post('otp/verify')
  otpVerify(@Body() dto: OtpVerifyDto, @Req() req: Request) {
<<<<<<< HEAD
    // #region agent log
    fetch('http://127.0.0.1:7572/ingest/0165e44f-c140-425a-bb49-5e5c88d4f3e3',{method:'POST',headers:{'Content-Type':'application/json','X-Debug-Session-Id':'2e5b8f'},body:JSON.stringify({sessionId:'2e5b8f',runId:'run1',hypothesisId:'H2',location:'auth.controller.ts:otpVerify',message:'otp verify endpoint hit',data:{phoneLen:(dto.phone??'').length,otpLen:(dto.otp??'').length},timestamp:Date.now()})}).catch(()=>{});
    // #endregion
=======
>>>>>>> 9164b54b7ae96a96dfb046b32a6f1d92bc55e577
    return this.auth.verifyOtp(dto, req.ip, req.headers['user-agent']);
  }

  // EP-03
<<<<<<< HEAD
  @Post('login/otp-request')
  @HttpCode(HttpStatus.OK)
  loginOtpRequest(@Body() dto: LoginOtpRequestV2Dto, @Req() req: Request) {
    // #region agent log
    fetch('http://127.0.0.1:7572/ingest/0165e44f-c140-425a-bb49-5e5c88d4f3e3',{method:'POST',headers:{'Content-Type':'application/json','X-Debug-Session-Id':'2e5b8f'},body:JSON.stringify({sessionId:'2e5b8f',runId:'run1',hypothesisId:'H3',location:'auth.controller.ts:loginOtpRequest',message:'login otp-request endpoint hit',data:{phoneLen:(dto.phone??'').length},timestamp:Date.now()})}).catch(()=>{});
    // #endregion
    return this.auth.requestLoginOtp(dto.phone, req.ip);
  }

  // EP-04
=======
>>>>>>> 9164b54b7ae96a96dfb046b32a6f1d92bc55e577
  @Post('login/password')
  @HttpCode(HttpStatus.OK)
  loginPassword(@Body() dto: LoginDto, @Req() req: Request) {
    return this.auth.loginPassword(dto, req.ip, req.headers['user-agent']);
  }

  // EP-04
  @Post('token/refresh')
  @HttpCode(HttpStatus.OK)
  refresh(@Body() dto: RefreshTokenDto) {
    return this.auth.refreshToken(dto.refresh_token);
  }

  // EP-05
  @Post('logout')
  @HttpCode(HttpStatus.OK)
  @UseGuards(JwtAuthGuard)
  async logout(@CurrentUser() user: JwtPayload, @Body() dto: LogoutDto, @Req() req: Request) {
    const token = req.headers['authorization']?.slice(7) ?? '';
    await this.auth.logout(user.sub, token, dto.refresh_token);
    return { success: true, message: 'Logged out successfully' };
  }

  // EP-06
  @Get('me')
  @UseGuards(JwtAuthGuard)
  getProfile(@CurrentUser() user: JwtPayload) {
    return this.auth.getProfile(user.sub);
  }

  // EP-07
  @Put('profile')
  @HttpCode(HttpStatus.OK)
  @UseGuards(JwtAuthGuard)
  updateProfile(@CurrentUser() user: JwtPayload, @Body() dto: UpdateProfileDto) {
    return this.profile.updateProfile(user.sub, dto);
  }

  // EP-08
  @Post('profile/avatar')
  @HttpCode(HttpStatus.OK)
  @UseGuards(JwtAuthGuard)
  @UseInterceptors(FileInterceptor('avatar'))
  uploadAvatar(
    @UploadedFile(new ParseFilePipe({
      validators: [
        new MaxFileSizeValidator({ maxSize: 5 * 1024 * 1024 }),
        new FileTypeValidator({ fileType: /image\/(jpeg|jpg|png)/ }),
      ],
    })) file: Express.Multer.File,
    @CurrentUser() user: JwtPayload,
  ) {
    return this.profile.uploadAvatar(file, user.sub);
  }

  // EP-09
  @Post('password/reset-request')
  @HttpCode(HttpStatus.OK)
  passwordResetRequest(@Body() dto: PasswordResetRequestDto) {
    return this.password.resetRequest(dto);
  }

  // EP-10
  @Post('password/reset-verify')
  @HttpCode(HttpStatus.OK)
  passwordResetVerify(@Body() dto: PasswordResetVerifyDto) {
    return this.password.resetVerify(dto);
  }

  // EP-11
  @Post('contact/change')
  @HttpCode(HttpStatus.OK)
  @UseGuards(JwtAuthGuard)
  contactChange(@CurrentUser() user: JwtPayload, @Body() dto: ContactChangeDto) {
    return this.contact.initiateChange(user.sub, dto);
  }

  // EP-12
  @Post('contact/verify')
  @HttpCode(HttpStatus.OK)
  @UseGuards(JwtAuthGuard)
  contactVerify(@CurrentUser() user: JwtPayload, @Body() dto: ContactVerifyDto) {
    return this.contact.verifyChange(user.sub, dto);
  }

  // EP-14
  @Post('upgrade-to-employee')
  @HttpCode(HttpStatus.OK)
  @UseGuards(JwtAuthGuard)
  upgradeToEmployee(@CurrentUser() user: JwtPayload, @Body() dto: UpgradeEmployeeDto) {
    return this.upgrade.upgrade(user.sub, user.role as Role, dto);
  }

  // EP-13
  @Delete('account')
  @HttpCode(HttpStatus.OK)
  @UseGuards(JwtAuthGuard)
  deleteAccount(@CurrentUser() user: JwtPayload, @Body() dto: DeleteAccountDto) {
    return this.deletion.deleteAccount(user.sub, dto);
  }

  // EP-15
  @Get('sso/google')
  @UseGuards(AuthGuard('google'))
  googleSsoRedirect() {
    return;
  }

  // EP-16
  @Get('sso/google/callback')
  @UseGuards(AuthGuard('google'))
  googleSsoCallback(@Req() req: Request) {
    const user = req.user as { email: string; name: string; google_sub: string };
    return this.auth.loginWithGoogle(user, req.ip, req.headers['user-agent']);
  }
}
