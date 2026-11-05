import {
  Body, Controller, Delete, Get, Header, HttpCode, Param, ParseUUIDPipe, Patch, Post, Query, Req, Res,
  UseFilters, UseGuards,
} from '@nestjs/common';
import type { Response } from 'express';
import { AuthGuard, type AuthRequest } from '../auth/auth.guard';
import { GoalExceptionFilter } from './goal-exception.filter';
import { AdjustGoalDto, ArchiveGoalDto, CreateGoalDto, ListGoalsDto, MoveGoalDto, PreviewGoalDto, UpdateGoalDto } from './goal.dto';
import { GoalService } from './goal.service';

@Controller('v1/goals')
@UseGuards(AuthGuard)
@UseFilters(GoalExceptionFilter)
export class GoalController {
  constructor(private readonly goals: GoalService) {}

  @Get('presets') @Header('Cache-Control', 'no-store')
  presets() {
    return this.goals.presets();
  }

  @Post('preview') @HttpCode(200) @Header('Cache-Control', 'no-store')
  preview(@Req() req: AuthRequest, @Body() body: PreviewGoalDto) {
    return this.goals.preview(req.session.userId, body);
  }

  @Get() @Header('Cache-Control', 'no-store')
  list(@Req() req: AuthRequest, @Query() query: ListGoalsDto) {
    return this.goals.list(req.session.userId, query.includeArchived);
  }

  @Post() @Header('Cache-Control', 'no-store')
  async create(@Req() req: AuthRequest, @Body() body: CreateGoalDto, @Res({ passthrough: true }) res: Response) {
    const result = await this.goals.create(req.session.userId, body);
    res.status(result.created ? 201 : 200);
    return result.goal;
  }

  @Get(':id') @Header('Cache-Control', 'no-store')
  find(@Req() req: AuthRequest, @Param('id', ParseUUIDPipe) id: string) {
    return this.goals.find(req.session.userId, id);
  }

  @Get(':id/entries') @Header('Cache-Control', 'no-store')
  history(@Req() req: AuthRequest, @Param('id', ParseUUIDPipe) id: string) {
    return this.goals.history(req.session.userId, id);
  }

  @Patch(':id') @Header('Cache-Control', 'no-store')
  update(@Req() req: AuthRequest, @Param('id', ParseUUIDPipe) id: string, @Body() body: UpdateGoalDto) {
    return this.goals.update(req.session.userId, id, body);
  }

  @Delete(':id') @HttpCode(204) @Header('Cache-Control', 'no-store')
  async archive(@Req() req: AuthRequest, @Param('id', ParseUUIDPipe) id: string, @Query() query: ArchiveGoalDto) {
    await this.goals.archive(req.session.userId, id, query.version);
  }

  @Post(':id/contribute') @Header('Cache-Control', 'no-store')
  async contribute(
    @Req() req: AuthRequest, @Param('id', ParseUUIDPipe) id: string, @Body() body: MoveGoalDto,
    @Res({ passthrough: true }) res: Response,
  ) {
    const result = await this.goals.contribute(req.session.userId, id, body);
    res.status(result.created ? 201 : 200);
    return result.goal;
  }

  @Post(':id/withdraw') @Header('Cache-Control', 'no-store')
  async withdraw(
    @Req() req: AuthRequest, @Param('id', ParseUUIDPipe) id: string, @Body() body: MoveGoalDto,
    @Res({ passthrough: true }) res: Response,
  ) {
    const result = await this.goals.withdraw(req.session.userId, id, body);
    res.status(result.created ? 201 : 200);
    return result.goal;
  }

  @Post(':id/adjust') @HttpCode(200) @Header('Cache-Control', 'no-store')
  adjust(@Req() req: AuthRequest, @Param('id', ParseUUIDPipe) id: string, @Body() body: AdjustGoalDto) {
    return this.goals.adjust(req.session.userId, id, body);
  }
}
