import 'reflect-metadata';
import { plainToInstance } from 'class-transformer';
import { validate } from 'class-validator';
import { ChangePasswordDto, CredentialsDto, NewCredentialsDto, RegisterDto, ResetPasswordDto } from './auth.dto';

const email = 'lan@example.test';
const token = 'a'.repeat(64);

describe('DS-P2-004 password rule', () => {
  it.each(['maytrangngay7', 'mật khẩu có số 7', 'Пароль123456', 'hai3ba4nam5sau6'])('accepts %j for a new password', async password => {
    expect(await validate(plainToInstance(NewCredentialsDto, { email, password }))).toHaveLength(0);
    expect(await validate(plainToInstance(ResetPasswordDto, { token, password }))).toHaveLength(0);
  });
  it.each(['no digits in this one', '1234567890123', '!!!!!!!!!!!!7', 'short7a'])('rejects %j for a new password', async password => {
    expect((await validate(plainToInstance(NewCredentialsDto, { email, password }))).length).toBeGreaterThan(0);
    expect((await validate(plainToInstance(ResetPasswordDto, { token, password }))).length).toBeGreaterThan(0);
  });
  it('login keeps accepting older passwords without a digit', async () => {
    expect(await validate(plainToInstance(CredentialsDto, { email, password: 'no digits in this one' }))).toHaveLength(0);
  });
  it('change-password asks for the old password and applies the new rule', async () => {
    expect(await validate(plainToInstance(ChangePasswordDto, { currentPassword: 'old', newPassword: 'maytrangngay7' }))).toHaveLength(0);
    expect((await validate(plainToInstance(ChangePasswordDto, { currentPassword: '', newPassword: 'maytrangngay7' }))).length).toBeGreaterThan(0);
    expect((await validate(plainToInstance(ChangePasswordDto, { currentPassword: 'old', newPassword: 'no digits in this one' }))).length).toBeGreaterThan(0);
  });
});

describe('DS-P2-004 terms consent', () => {
  const password = 'maytrangngay7';
  it('register needs the terms checkbox ticked', async () => {
    expect(await validate(plainToInstance(RegisterDto, { email, password, termsAccepted: true }))).toHaveLength(0);
    for (const termsAccepted of [false, 'true', undefined]) {
      expect((await validate(plainToInstance(RegisterDto, { email, password, termsAccepted }))).length).toBeGreaterThan(0);
    }
  });
});
