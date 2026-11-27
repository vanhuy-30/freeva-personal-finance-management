import { Controller, Get, Res } from '@nestjs/common';
import { randomBytes } from 'node:crypto';
import type { Response } from 'express';
import {
  authLinkCsp,
  renderAuthLinkPage,
  type AuthLinkKind,
} from './auth-link-page';

/**
 * Landing pages for the links in auth emails. Served outside the `/api` prefix (see `main.ts`) so
 * the public URL shape matches a future web app. A GET never consumes a token: mail scanners and
 * link previews open these URLs, and only the page's script (on a user tap) calls the API.
 */
@Controller()
export class AuthLinkController {
  @Get('verify-email')
  verifyEmail(@Res() response: Response): void {
    this.page(response, 'verify-email');
  }

  @Get('reset-password')
  resetPassword(@Res() response: Response): void {
    this.page(response, 'reset-password');
  }

  private page(response: Response, kind: AuthLinkKind): void {
    const nonce = randomBytes(16).toString('base64');
    response
      .status(200)
      .setHeader('Content-Type', 'text/html; charset=utf-8')
      .setHeader('Cache-Control', 'no-store')
      .setHeader('Referrer-Policy', 'no-referrer')
      .setHeader('X-Robots-Tag', 'noindex, nofollow')
      // Replaces helmet's default policy, which would block this page's inline script.
      .setHeader('Content-Security-Policy', authLinkCsp(nonce))
      .send(renderAuthLinkPage(kind, nonce));
  }
}
