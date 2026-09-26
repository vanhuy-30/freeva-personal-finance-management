import { Body, Controller, Delete, Get, Header, HttpCode, Param, Patch, Post, Query, Req, Res, UseFilters, UseGuards } from '@nestjs/common';
import type { Response } from 'express';
import { AuthGuard, type AuthRequest } from '../auth/auth.guard';
import { CategoryService } from './category.service';
import { CategoryIdDto, CategoryQueryDto, CreateCategoryDto, DeleteCategoryDto, UpdateCategoryDto } from './category.dto';
import { CategoryExceptionFilter } from './category-exception.filter';
@Controller('v1/categories')
@UseGuards(AuthGuard)
@UseFilters(CategoryExceptionFilter)
export class CategoryController {
  constructor(private readonly categories: CategoryService) {}
  @Post('defaults') @HttpCode(204) @Header('Cache-Control', 'no-store')
  initialize(@Req() req: AuthRequest) { return this.categories.initialize(req.session.userId); }
  @Get('options') @Header('Cache-Control', 'no-store')
  options() { return this.categories.options(); }
  @Get('recent') @Header('Cache-Control', 'no-store')
  recent(@Req() req: AuthRequest) { return this.categories.recent(req.session.userId); }
  @Post() @Header('Cache-Control', 'no-store')
  async create(@Req() req: AuthRequest, @Body() body: CreateCategoryDto, @Res({ passthrough: true }) res: Response) {
    const result = await this.categories.create(req.session.userId, body);
    res.status(result.created ? 201 : 200);
    return result.category;
  }
  @Get() @Header('Cache-Control', 'no-store')
  list(@Req() req: AuthRequest, @Query() query: CategoryQueryDto) { return this.categories.list(req.session.userId, query); }
  @Get(':id') @Header('Cache-Control', 'no-store')
  find(@Req() req: AuthRequest, @Param() params: CategoryIdDto) { return this.categories.find(req.session.userId, params.id); }
  @Patch(':id') @Header('Cache-Control', 'no-store')
  update(@Req() req: AuthRequest, @Param() params: CategoryIdDto, @Body() body: UpdateCategoryDto) {
    return this.categories.update(req.session.userId, params.id, body);
  }
  @Delete(':id') @HttpCode(204) @Header('Cache-Control', 'no-store')
  delete(@Req() req: AuthRequest, @Param() params: CategoryIdDto, @Query() query: DeleteCategoryDto) {
    return this.categories.delete(req.session.userId, params.id, query.version, query.replacementCategoryId);
  }
}
