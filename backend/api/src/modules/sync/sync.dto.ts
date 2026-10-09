import { Transform, Type } from 'class-transformer';
import { ArrayMaxSize, ArrayMinSize, ArrayUnique, IsArray, IsDefined, IsIn, IsInt, IsObject, IsUUID, Max, Min, Validate, ValidateIf, ValidateNested, type ValidationArguments, ValidatorConstraint, type ValidatorConstraintInterface } from 'class-validator';
import { CreateTransactionDto, UpdateTransactionDto } from '../transactions/transaction.dto';

const uuid = ({ value }: { value: unknown }) => typeof value === 'string' ? value.toLowerCase() : value;
function operationBody(options?: { object?: { action?: string } }) {
  return options?.object?.action === 'update' ? UpdateTransactionDto : CreateTransactionDto;
}
@ValidatorConstraint({ name: 'syncOperationShape', async: false })
class SyncOperationShape implements ValidatorConstraintInterface {
  validate(_value: unknown, args: ValidationArguments): boolean {
    const op = args.object as SyncOperationDto;
    if (op.action === 'create') return op.id === undefined && op.version === undefined && op.body != null;
    if (op.action === 'update') return op.id !== undefined && op.version === undefined && op.body != null;
    if (op.action === 'delete') return op.id !== undefined && op.version !== undefined && op.body === undefined;
    return false;
  }
}
export class SyncOperationDto {
  @Transform(uuid) @IsUUID() opId!: string;
  @IsIn(['create', 'update', 'delete']) @Validate(SyncOperationShape) action!: 'create' | 'update' | 'delete';
  @ValidateIf(op => op.action !== 'create') @Transform(uuid) @IsUUID() id?: string;
  @ValidateIf(op => op.action === 'delete') @IsInt() @Min(1) @Max(2147483646) version?: number;
  @ValidateIf(op => op.action === 'create' || op.action === 'update') @IsDefined() @IsObject() @ValidateNested() @Type(operationBody)
  body?: CreateTransactionDto | UpdateTransactionDto;
}
export class SyncRequestDto {
  @IsInt() @Min(1) @Max(2147483647) schemaVersion!: number;
  @IsArray() @ArrayMinSize(1) @ArrayMaxSize(50) @ArrayUnique((op: SyncOperationDto) => op.opId)
  @ValidateNested({ each: true }) @Type(() => SyncOperationDto) operations!: SyncOperationDto[];
}
