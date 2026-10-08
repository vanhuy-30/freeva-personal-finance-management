import { Module } from '@nestjs/common';
import { AuthModule } from '../auth/auth.module';
import { CATEGORY_REPOSITORY } from './domain/category.repository';
import { PrismaCategoryRepository } from './infrastructure/prisma-category.repository';
import { CategoryController } from './category.controller';
import { CategoryService } from './category.service';
@Module({ imports: [AuthModule], controllers: [CategoryController],
  providers: [CategoryService, { provide: CATEGORY_REPOSITORY, useClass: PrismaCategoryRepository }] })
export class CategoryModule {}
