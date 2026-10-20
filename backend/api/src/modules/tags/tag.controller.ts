import { Body, Controller, Delete, Get, Header, HttpCode, Param, Patch, Post, Query, Req, Res, UseFilters, UseGuards } from '@nestjs/common';
import type { Response } from 'express';
import { AuthGuard, type AuthRequest } from '../auth/auth.guard';
import { TagService } from './tag.service';
import { CreateTagDto, DeleteTagDto, TagIdDto, TagQueryDto, UpdateTagDto } from './tag.dto';
import { TagExceptionFilter } from './tag-exception.filter';
@Controller('v1/tags')
@UseGuards(AuthGuard)
@UseFilters(TagExceptionFilter)
export class TagController {
  constructor(private readonly tags: TagService) {}
  @Post() @Header('Cache-Control', 'no-store')
  async create(@Req() req: AuthRequest, @Body() body: CreateTagDto, @Res({ passthrough: true }) res: Response) {
    const result = await this.tags.create(req.session.userId, body);
    res.status(result.created ? 201 : 200);
    return result.tag;
  }
  @Get() @Header('Cache-Control', 'no-store')
  list(@Req() req: AuthRequest, @Query() query: TagQueryDto) { return this.tags.list(req.session.userId, query); }
  @Get(':id') @Header('Cache-Control', 'no-store')
  find(@Req() req: AuthRequest, @Param() params: TagIdDto) { return this.tags.find(req.session.userId, params.id); }
  @Patch(':id') @Header('Cache-Control', 'no-store')
  update(@Req() req: AuthRequest, @Param() params: TagIdDto, @Body() body: UpdateTagDto) {
    return this.tags.update(req.session.userId, params.id, body);
  }
  @Delete(':id') @HttpCode(204) @Header('Cache-Control', 'no-store')
  delete(@Req() req: AuthRequest, @Param() params: TagIdDto, @Query() query: DeleteTagDto) {
    return this.tags.delete(req.session.userId, params.id, query.version);
  }
}
