import { Body, Controller, Get, Header, HttpCode, Param, ParseUUIDPipe, Post, Req, Res, UseFilters, UseGuards } from '@nestjs/common';
import type { Response } from 'express';
import { AuthGuard, type AuthRequest } from '../auth/auth.guard';
import { CommitImportDto, PreviewImportDto } from './transaction-import.dto';
import { TransactionImportExceptionFilter } from './transaction-import-exception.filter';
import { TransactionImportService } from './transaction-import.service';

@Controller('v1/transactions/import')
@UseGuards(AuthGuard)
@UseFilters(TransactionImportExceptionFilter)
export class TransactionImportController {
  constructor(private readonly imports: TransactionImportService) {}

  @Post('preview') @HttpCode(200) @Header('Cache-Control', 'no-store')
  preview(@Req() req: AuthRequest, @Body() body: PreviewImportDto) {
    return this.imports.preview(req.session.userId, body);
  }

  @Post() @Header('Cache-Control', 'no-store')
  async commit(@Req() req: AuthRequest, @Body() body: CommitImportDto, @Res({ passthrough: true }) res: Response) {
    const result = await this.imports.commit(req.session.userId, body);
    res.status(result.created ? 201 : 200);
    return result;
  }

  @Get(':id') @Header('Cache-Control', 'no-store')
  find(@Req() req: AuthRequest, @Param('id', ParseUUIDPipe) id: string) {
    return this.imports.find(req.session.userId, id);
  }

  @Post(':id/undo') @HttpCode(200) @Header('Cache-Control', 'no-store')
  undo(@Req() req: AuthRequest, @Param('id', ParseUUIDPipe) id: string) {
    return this.imports.undo(req.session.userId, id);
  }
}
